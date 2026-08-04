--!strict

local Result = require(game:GetService("ReplicatedStorage").RVTT.Shared.Core.Result)

export type CommandContext = {
	player: Player?,
	playerId: number,
	role: string,
	commandId: string,
	correlationId: string,
}

export type Descriptor = {
	commandType: string,
	domainId: string,
	validate: (({ [string]: unknown }) -> boolean)?,
	authorize: ((CommandContext, { [string]: unknown }, { [string]: unknown }) -> boolean)?,
	execute: (CommandContext, { [string]: unknown }, { [string]: unknown }) -> unknown,
}

local CommandRegistry = {}
CommandRegistry.__index = CommandRegistry

function CommandRegistry.new()
	return setmetatable({ descriptors = {} }, CommandRegistry)
end

function CommandRegistry:register(descriptor: Descriptor)
	assert(self.descriptors[descriptor.commandType] == nil, "duplicate command: " .. descriptor.commandType)
	self.descriptors[descriptor.commandType] = table.freeze(descriptor)
end

function CommandRegistry:get(commandType: string)
	local descriptor = self.descriptors[commandType]
	if descriptor == nil then
		return Result.err("UNKNOWN_COMMAND", "error.command.unknown", false, { commandType = commandType })
	end
	return Result.ok(descriptor)
end

function CommandRegistry:list(): { string }
	local values = {}
	for commandType in self.descriptors do
		table.insert(values, commandType)
	end
	table.sort(values)
	return values
end

return CommandRegistry
