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

local CommandRegistry = {}
CommandRegistry.__index = CommandRegistry

function CommandRegistry.new()
    return setmetatable({ descriptors = {} }, CommandRegistry)
end

function CommandRegistry:register(descriptor: Descriptor)
    assert(type(descriptor.commandType) == "string" and #descriptor.commandType > 0, "commandType required")
    assert(type(descriptor.domainId) == "string" and #descriptor.domainId > 0, "domainId required")
    assert(type(descriptor.authorize) == "function", "explicit authorization required: " .. descriptor.commandType)
    assert(type(descriptor.execute) == "function", "execute required: " .. descriptor.commandType)
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

function CommandRegistry:descriptors()
    return self.descriptors
end

return CommandRegistry
