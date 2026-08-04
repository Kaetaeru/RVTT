--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Identity = require(ReplicatedStorage.RVTT.Shared.Core.Identity)
local Helpers = require(script.Parent.DomainHelpers)

local Domain = { id = "inventory", slice = 6 }

function Domain.initialState()
    return { items = {}, locations = {} }
end

local function validLocation(location): boolean
    if type(location) ~= "table" or type(location.kind) ~= "string" then
        return false
    end
    if location.kind == "ground" then
        return location.position == nil or Helpers.isVector(location.position)
    end
    if location.kind == "inventory" then
        return type(location.characterId) == "string"
    end
    if location.kind == "equipped" then
        return type(location.characterId) == "string" and type(location.slot) == "string"
    end
    return false
end

local function canReceive(context, domains, location): boolean
    if context.role == "dm" or location.kind == "ground" then
        return true
    end
    return Helpers.ownsCharacter(context, domains, location.characterId)
end

local function move(state, itemId: string, location)
    state.locations[itemId] = location
    state.items[itemId].revision += 1
    return { item = state.items[itemId], location = location }
end

function Domain.register(registry)
    registry:register({
        commandType = "inventory.create_item",
        domainId = Domain.id,
        authorize = function(context)
            return Helpers.requireRole(context, { "dm" })
        end,
        validate = function(payload)
            return Helpers.hasString(payload, "definitionId")
                and payload.location ~= nil
                and validLocation(payload.location)
        end,
        execute = function(_, state, payload)
            local itemId = Identity.new("item")
            state.items[itemId] = {
                id = itemId,
                definitionId = payload.definitionId,
                quantity = math.clamp(math.floor(payload.quantity or 1), 1, 9999),
                revision = 1,
            }
            state.locations[itemId] = payload.location
            return { item = state.items[itemId], location = payload.location }
        end,
    })

    registry:register({
        commandType = "inventory.move_item",
        domainId = Domain.id,
        authorize = function(context, domains, payload)
            return Helpers.ownsItem(context, domains, payload.itemId)
                and validLocation(payload.location)
                and canReceive(context, domains, payload.location)
        end,
        validate = function(payload)
            return Helpers.hasString(payload, "itemId") and validLocation(payload.location)
        end,
        execute = function(_, state, payload)
            if state.items[payload.itemId] == nil then
                return Helpers.notFound("item", payload.itemId)
            end
            return move(state, payload.itemId, payload.location)
        end,
    })

    registry:register({
        commandType = "inventory.equip",
        domainId = Domain.id,
        authorize = function(context, domains, payload)
            return Helpers.ownsItem(context, domains, payload.itemId)
                and Helpers.ownsCharacter(context, domains, payload.characterId)
        end,
        validate = function(payload)
            return Helpers.hasString(payload, "itemId")
                and Helpers.hasString(payload, "characterId")
                and Helpers.hasString(payload, "slot", 64)
        end,
        execute = function(_, state, payload)
            if state.items[payload.itemId] == nil then
                return Helpers.notFound("item", payload.itemId)
            end
            return move(state, payload.itemId, {
                kind = "equipped",
                characterId = payload.characterId,
                slot = payload.slot,
            })
        end,
    })
end

return table.freeze(Domain)
