--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Identity = require(ReplicatedStorage.RVTT.Shared.Core.Identity)
local Helpers = require(script.Parent.DomainHelpers)

local Domain = { id = "npc_content", slice = 15 }

function Domain.initialState()
	return { definitions = {}, instances = {} }
end

local function dm(context: any): boolean
	return Helpers.requireRole(context, { "dm" })
end

function Domain.register(registry: any)
	registry:register({
		commandType = "npc.register_definition",
		domainId = Domain.id,
		authorize = dm,
		validate = function(payload: any)
			return Helpers.hasString(payload, "definitionId")
				and type(payload.definition) == "table"
				and (payload.rightsStatus == "approved" or payload.rightsStatus == "original")
		end,
		execute = function(_: any, state: any, payload: any)
			if state.definitions[payload.definitionId] ~= nil then
				return Helpers.conflict("npc definition already registered")
			end
			state.definitions[payload.definitionId] = payload.definition
			return { definitionId = payload.definitionId }
		end,
	})

	registry:register({
		commandType = "npc.spawn",
		domainId = Domain.id,
		authorize = dm,
		validate = function(payload: any)
			return Helpers.hasString(payload, "definitionId")
				and (payload.position == nil or Helpers.isVector(payload.position))
		end,
		execute = function(_: any, state: any, payload: any, domains: any)
			local definition = state.definitions[payload.definitionId]
			if definition == nil then
				return Helpers.notFound("npc_definition", payload.definitionId)
			end
			local instanceId = Identity.new("actor")
			state.instances[instanceId] = {
				id = instanceId,
				definitionId = payload.definitionId,
				sceneId = payload.sceneId,
				position = payload.position or { x = 0, y = 0, z = 0 },
				runtime = definition.runtime or {},
			}
			domains.scene.actors[instanceId] = {
				id = instanceId,
				sourceNpcId = instanceId,
				controllerUserId = payload.controllerUserId,
				position = state.instances[instanceId].position,
				incarnation = 1,
				hidden = payload.hidden == true,
			}
			domains.scene.sceneRevision += 1
			return state.instances[instanceId]
		end,
	})
end

return table.freeze(Domain)
