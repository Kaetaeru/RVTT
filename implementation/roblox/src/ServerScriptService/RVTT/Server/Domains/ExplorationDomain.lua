--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Identity = require(ReplicatedStorage.RVTT.Shared.Core.Identity)
local Helpers = require(script.Parent.DomainHelpers)
local ActorProfileResolver = require(script.Parent.Parent.Rules.ActorProfileResolver)
local RuleResolver = require(script.Parent.Parent.Rules.RuleResolver)

local Domain = { id = "exploration", slice = 3 }

function Domain.initialState()
    return { objectStates = {}, knowledge = {}, fog = {}, searches = {} }
end

local function interactionAllowed(object, interactionId: string): boolean
    for _, allowed in object.interactionIds or {} do
        if allowed == interactionId then
            return true
        end
    end
    return interactionId == "inspect"
end

function Domain.register(registry)
    registry:register({
        commandType = "exploration.interact",
        domainId = Domain.id,
        authorize = function(context, domains, payload)
            return Helpers.controlsActor(context, domains, payload.actorId)
        end,
        validate = function(payload)
            return Helpers.hasString(payload, "actorId")
                and Helpers.hasString(payload, "objectId")
                and Helpers.hasString(payload, "interactionId")
        end,
        execute = function(context, state, payload, domains)
            local object = domains.scene.objects[payload.objectId]
            if object == nil or (object.hidden == true and context.role ~= "dm") then
                return Helpers.notFound("scene_object", payload.objectId)
            end
            if not interactionAllowed(object, payload.interactionId) then
                return Helpers.conflict("interaction is not available")
            end
            local objectState = state.objectStates[payload.objectId] or {
                state = object.state.state or "idle",
                revision = 0,
            }
            local interactionId = payload.interactionId
            if interactionId == "open" then
                if object.state.locked == true then
                    return Helpers.conflict("object is locked")
                end
                objectState.state = "open"
            elseif interactionId == "close" then
                objectState.state = "closed"
            elseif interactionId == "activate" then
                objectState.state = "active"
            elseif interactionId == "deactivate" then
                objectState.state = "inactive"
            end
            objectState.revision += 1
            objectState.lastActorId = payload.actorId
            state.objectStates[payload.objectId] = objectState
            return { objectId = payload.objectId, object = objectState }
        end,
    })

    registry:register({
        commandType = "exploration.search",
        domainId = Domain.id,
        authorize = function(context, domains, payload)
            return Helpers.controlsActor(context, domains, payload.actorId)
        end,
        validate = function(payload)
            return Helpers.hasString(payload, "actorId") and Helpers.hasString(payload, "objectId")
        end,
        execute = function(context, state, payload, domains)
            local object = domains.scene.objects[payload.objectId]
            if object == nil then
                return Helpers.notFound("scene_object", payload.objectId)
            end
            local profile = ActorProfileResolver.resolve(payload.actorId, domains)
            if profile == nil then
                return Helpers.notFound("actor", payload.actorId)
            end
            local difficultyClass = math.clamp(math.floor(object.searchDc or 10), 1, 40)
            local resolution = RuleResolver.rollCheck(profile, "wisdom", true, difficultyClass, nil)
            local revealed = {}
            if resolution.success then
                object.hidden = false
                for _, knowledgeId in object.knowledgeIds or {} do
                    state.knowledge[tostring(context.playerId) .. ":" .. knowledgeId] = true
                    table.insert(revealed, knowledgeId)
                end
            end
            local searchId = Identity.new("search")
            state.searches[searchId] = {
                id = searchId,
                actorId = payload.actorId,
                objectId = payload.objectId,
                observerUserId = context.playerId,
                resolution = resolution,
                revealed = revealed,
            }
            return state.searches[searchId]
        end,
    })

    registry:register({
        commandType = "exploration.set_fog",
        domainId = Domain.id,
        authorize = function(context)
            return Helpers.requireRole(context, { "dm" })
        end,
        validate = function(payload)
            return Helpers.hasString(payload, "regionId") and type(payload.hidden) == "boolean"
        end,
        execute = function(_, state, payload)
            local previous = state.fog[payload.regionId]
            state.fog[payload.regionId] = {
                hidden = payload.hidden,
                revision = if previous ~= nil then previous.revision + 1 else 1,
            }
            return state.fog[payload.regionId]
        end,
    })
end

return table.freeze(Domain)
