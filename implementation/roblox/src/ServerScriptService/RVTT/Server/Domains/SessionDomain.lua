--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Identity = require(ReplicatedStorage.RVTT.Shared.Core.Identity)
local Helpers = require(script.Parent.DomainHelpers)

local Domain = { id = "session", slice = 1 }

function Domain.initialState()
    return {
        campaignId = Identity.new("campaign", "default"),
        phase = "lobby",
        memberships = {},
        ready = {},
        selectedCharacter = {},
        connections = {},
        sceneId = nil,
    }
end

function Domain.register(registry)
    registry:register({
        commandType = "session.join",
        domainId = Domain.id,
        authorize = function(context)
            return Helpers.authenticated(context)
        end,
        execute = function(context, state)
            local player = context.player
            local key = tostring(context.playerId)
            state.memberships[key] = {
                userId = context.playerId,
                displayName = if player ~= nil then player.DisplayName else tostring(context.playerId),
                role = context.role,
                joinedAt = os.time(),
            }
            state.connections[key] = "connected"
            return { membership = state.memberships[key] }
        end,
    })

    registry:register({
        commandType = "session.select_character",
        domainId = Domain.id,
        authorize = function(context, domains, payload)
            return Helpers.membership(context, domains)
                and Helpers.ownsCharacter(context, domains, payload.characterId)
        end,
        validate = function(payload)
            return Helpers.hasString(payload, "characterId")
        end,
        execute = function(context, state, payload, domains)
            local character = domains.character.characters[payload.characterId]
            if character == nil or character.status ~= "active" then
                return Helpers.conflict("active character required")
            end
            local key = tostring(context.playerId)
            state.selectedCharacter[key] = payload.characterId
            state.ready[key] = false
            return { characterId = payload.characterId }
        end,
    })

    registry:register({
        commandType = "session.ready",
        domainId = Domain.id,
        authorize = function(context, domains)
            return Helpers.membership(context, domains)
        end,
        validate = function(payload)
            return type(payload.ready) == "boolean"
        end,
        execute = function(context, state, payload)
            local key = tostring(context.playerId)
            if state.selectedCharacter[key] == nil then
                return Helpers.conflict("character selection required")
            end
            state.ready[key] = payload.ready
            return { ready = payload.ready }
        end,
    })

    registry:register({
        commandType = "session.start",
        domainId = Domain.id,
        authorize = function(context)
            return Helpers.requireRole(context, { "dm" })
        end,
        validate = function(payload)
            return Helpers.hasString(payload, "sceneId")
        end,
        execute = function(_, state, payload)
            for userId, membership in state.memberships do
                if membership.role == "player" and state.connections[userId] == "connected" then
                    if state.selectedCharacter[userId] == nil or state.ready[userId] ~= true then
                        return Helpers.conflict("connected players must select and ready a character")
                    end
                end
            end
            state.phase = "active"
            state.sceneId = payload.sceneId
            return { phase = state.phase, sceneId = state.sceneId }
        end,
    })

    registry:register({
        commandType = "session.connection",
        domainId = Domain.id,
        remoteAllowed = false,
        authorize = function(context)
            return Helpers.system(context)
        end,
        validate = function(payload)
            return type(payload.userId) == "number"
                and (payload.status == "connected" or payload.status == "disconnected")
        end,
        execute = function(_, state, payload)
            state.connections[tostring(payload.userId)] = payload.status
            return { userId = payload.userId, status = payload.status }
        end,
    })
end

return table.freeze(Domain)
