--!strict

local Result = require(game:GetService("ReplicatedStorage").RVTT.Shared.Core.Result)

export type CommandContext = {
	player: Player?,
	playerId: number,
	role: string,
	origin: "remote" | "system",
	commandId: string,
	correlationId: string,
}

export type DomainMap = { [string]: { [string]: any } }

export type Descriptor = {
	commandType: string,
	domainId: string,
	validate: (({ [string]: unknown }) -> boolean)?,
	authorize: (CommandContext, DomainMap, { [string]: unknown }) -> boolean,
	execute: (CommandContext, { [string]: any }, { [string]: unknown }, DomainMap) -> unknown,
	remoteAllowed: boolean?,
	refreshAuthorityEpoch: boolean?,
}

export type Registry = {
	_descriptors: { [string]: Descriptor },
	register: (self: Registry, descriptor: Descriptor) -> (),
	get: (self: Registry, commandType: string) -> any,
	list: (self: Registry) -> { string },
	all: (self: Registry) -> { [string]: Descriptor },
}

local CommandRegistry = {}
CommandRegistry.__index = CommandRegistry

function CommandRegistry.new(): Registry
	return setmetatable({ _descriptors = {} }, CommandRegistry) :: any
end

function CommandRegistry.register(self: Registry, descriptor: Descriptor)
	assert(
		type(descriptor.commandType) == "string" and #descriptor.commandType > 0,
		"commandType required"
	)
	assert(type(descriptor.domainId) == "string" and #descriptor.domainId > 0, "domainId required")
	assert(
		type(descriptor.authorize) == "function",
		"explicit authorization required: " .. descriptor.commandType
	)
	assert(type(descriptor.execute) == "function", "execute required: " .. descriptor.commandType)
	assert(
		self._descriptors[descriptor.commandType] == nil,
		"duplicate command: " .. descriptor.commandType
	)
	self._descriptors[descriptor.commandType] = table.freeze(descriptor)
end

function CommandRegistry.get(self: Registry, commandType: string): any
	local descriptor = self._descriptors[commandType]
	if descriptor == nil then
		return Result.err(
			"UNKNOWN_COMMAND",
			"error.command.unknown",
			false,
			{ commandType = commandType } :: { [string]: unknown }
		)
	end
	return Result.ok(descriptor)
end

function CommandRegistry.list(self: Registry): { string }
	local values: { string } = {}
	for commandType in self._descriptors do
		table.insert(values, commandType)
	end
	table.sort(values)
	return values
end

function CommandRegistry.all(self: Registry): { [string]: Descriptor }
	return self._descriptors
end

return CommandRegistry
