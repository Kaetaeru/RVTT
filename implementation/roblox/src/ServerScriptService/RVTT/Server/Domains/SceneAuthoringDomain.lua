--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DeepCopy = require(ReplicatedStorage.RVTT.Shared.Core.DeepCopy)
local Identity = require(ReplicatedStorage.RVTT.Shared.Core.Identity)
local Helpers = require(script.Parent.DomainHelpers)

local Domain = { id = "scene_authoring", slice = 10 }

function Domain.initialState()
    return { sources = {}, candidates = {}, published = {} }
end

local function dm(context): boolean
    return Helpers.requireRole(context, { "dm" })
end

local function validateSource(source): (boolean, { string })
    local errors = {}
    for objectId, object in source.objects do
        if type(objectId) ~= "string" or type(object) ~= "table" or type(object.kind) ~= "string" then
            table.insert(errors, "invalid object")
        elseif object.position ~= nil and not Helpers.isVector(object.position) then
            table.insert(errors, "invalid object position: " .. objectId)
        end
    end
    return #errors == 0, errors
end

function Domain.register(registry)
    registry:register({
        commandType = "authoring.create_scene",
        domainId = Domain.id,
        authorize = dm,
        validate = function(payload)
            return payload.name == nil or (type(payload.name) == "string" and #payload.name <= 120)
        end,
        execute = function(_, state, payload)
            local sceneId = Identity.new("scene")
            state.sources[sceneId] = {
                id = sceneId,
                name = payload.name or "",
                objects = {},
                revision = 1,
            }
            return state.sources[sceneId]
        end,
    })

    registry:register({
        commandType = "authoring.upsert_object",
        domainId = Domain.id,
        authorize = dm,
        validate = function(payload)
            return Helpers.hasString(payload, "sceneId")
                and type(payload.object) == "table"
                and Helpers.hasString(payload.object, "kind")
                and (payload.object.position == nil or Helpers.isVector(payload.object.position))
        end,
        execute = function(_, state, payload)
            local source = state.sources[payload.sceneId]
            if source == nil then
                return Helpers.notFound("scene_source", payload.sceneId)
            end
            local object = DeepCopy(payload.object)
            local objectId = object.id or Identity.new("object")
            object.id = objectId
            source.objects[objectId] = object
            source.revision += 1
            state.candidates[payload.sceneId] = nil
            return object
        end,
    })

    registry:register({
        commandType = "authoring.compile",
        domainId = Domain.id,
        authorize = dm,
        validate = function(payload)
            return Helpers.hasString(payload, "sceneId")
        end,
        execute = function(_, state, payload)
            local source = state.sources[payload.sceneId]
            if source == nil then
                return Helpers.notFound("scene_source", payload.sceneId)
            end
            local valid, errors = validateSource(source)
            state.candidates[payload.sceneId] = {
                sourceRevision = source.revision,
                compiledAt = os.time(),
                objects = DeepCopy(source.objects),
                valid = valid,
                errors = errors,
            }
            return state.candidates[payload.sceneId]
        end,
    })

    registry:register({
        commandType = "authoring.publish",
        domainId = Domain.id,
        authorize = dm,
        validate = function(payload)
            return Helpers.hasString(payload, "sceneId")
        end,
        execute = function(_, state, payload)
            local source = state.sources[payload.sceneId]
            local candidate = state.candidates[payload.sceneId]
            if source == nil or candidate == nil or candidate.valid ~= true or candidate.sourceRevision ~= source.revision then
                return Helpers.conflict("current valid candidate required")
            end
            state.published[payload.sceneId] = DeepCopy(candidate)
            return state.published[payload.sceneId]
        end,
    })
end

return table.freeze(Domain)
