--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Identity = require(ReplicatedStorage.RVTT.Shared.Core.Identity)
local Helpers = require(script.Parent.DomainHelpers)

local Domain = { id = "scene", slice = 1 }

function Domain.initialState()
	return { activeSceneId = nil, actors = {}, objects = {}, sceneRevision = 0 }
end

function Domain.register(registry: any)
	registry:register({
		commandType = "scene.enter",
		domainId = Domain.id,
		authorize = function(context: any, domains: any, payload: any)
			if not Helpers.membership(context, domains) then
				return false
			end
			local selected = domains.session.selectedCharacter[tostring(context.playerId)]
			return selected == payload.actorId
				and Helpers.ownsCharacter(context, domains, payload.actorId)
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "sceneId") and Helpers.hasString(payload, "actorId")
		end,
		execute = function(context: any, state: any, payload: any, domains: any)
			if domains.session.phase ~= "active" or domains.session.sceneId ~= payload.sceneId then
				return Helpers.conflict("session scene is not active")
			end
			local character = domains.character.characters[payload.actorId]
			if character == nil then
				return Helpers.notFound("character", payload.actorId)
			end
			state.activeSceneId = payload.sceneId
			local actor = state.actors[payload.actorId]
			if actor == nil then
				actor = {
					id = payload.actorId,
					sourceCharacterId = payload.actorId,
					ownerUserId = context.playerId,
					controllerUserId = context.playerId,
					position = { x = 0, y = 0, z = 0 },
					incarnation = 1,
					hidden = false,
				}
				state.actors[payload.actorId] = actor
			else
				actor.controllerUserId = context.playerId
			end
			state.sceneRevision += 1
			return { actor = actor, sceneRevision = state.sceneRevision }
		end,
	})

	registry:register({
		commandType = "scene.spawn_actor",
		domainId = Domain.id,
		authorize = function(context: any)
			return Helpers.requireRole(context, { "dm" })
		end,
		validate = function(payload: any)
			return payload.position == nil or Helpers.isVector(payload.position)
		end,
		execute = function(_: any, state: any, payload: any)
			local actorId = Identity.new("actor")
			state.actors[actorId] = {
				id = actorId,
				sourceNpcId = payload.sourceNpcId,
				ownerUserId = payload.ownerUserId,
				controllerUserId = payload.controllerUserId,
				position = payload.position or { x = 0, y = 0, z = 0 },
				incarnation = 1,
				hidden = payload.hidden == true,
			}
			state.sceneRevision += 1
			return state.actors[actorId]
		end,
	})

	registry:register({
		commandType = "scene.spawn_object",
		domainId = Domain.id,
		authorize = function(context: any)
			return Helpers.requireRole(context, { "dm" })
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "kind")
				and (payload.position == nil or Helpers.isVector(payload.position))
		end,
		execute = function(_: any, state: any, payload: any)
			local objectId = Identity.new("object")
			state.objects[objectId] = {
				id = objectId,
				kind = payload.kind,
				position = payload.position or { x = 0, y = 0, z = 0 },
				state = payload.state or {},
				interactionIds = payload.interactionIds or {},
				searchDc = payload.searchDc,
				knowledgeIds = payload.knowledgeIds or {},
				hidden = payload.hidden == true,
				incarnation = 1,
				revision = 1,
			}
			state.sceneRevision += 1
			return state.objects[objectId]
		end,
	})
end

return table.freeze(Domain)
