--!strict

local Helpers = require(script.Parent.DomainHelpers)

local Domain = { id = "dm_workspace", slice = 11 }

function Domain.initialState()
	return { control = {}, quickActions = {}, runtimePatches = {}, recoveryRequests = {} }
end

local function dm(context: any): boolean
	return Helpers.requireRole(context, { "dm" })
end

function Domain.register(registry: any)
	registry:register({
		commandType = "dm.assign_control",
		domainId = Domain.id,
		authorize = dm,
		validate = function(payload: any)
			return Helpers.hasString(payload, "actorId")
				and type(payload.controllerUserId) == "number"
		end,
		execute = function(_: any, state: any, payload: any, domains: any)
			local actor = domains.scene.actors[payload.actorId]
			if actor == nil then
				return Helpers.notFound("actor", payload.actorId)
			end
			actor.controllerUserId = payload.controllerUserId
			state.control[payload.actorId] = payload.controllerUserId
			return { actorId = payload.actorId, controllerUserId = payload.controllerUserId }
		end,
	})

	registry:register({
		commandType = "dm.quick_action",
		domainId = Domain.id,
		authorize = dm,
		validate = function(payload: any)
			return Helpers.hasString(payload, "actionId")
		end,
		execute = function(context: any, state: any, payload: any)
			local record = {
				actionId = payload.actionId,
				payload = payload.payload or {},
				commandId = context.commandId,
				createdAt = os.time(),
			}
			table.insert(state.quickActions, record)
			return record
		end,
	})

	registry:register({
		commandType = "dm.runtime_patch",
		domainId = Domain.id,
		authorize = dm,
		validate = function(payload: any)
			return Helpers.hasString(payload, "targetId") and type(payload.patch) == "table"
		end,
		execute = function(context: any, state: any, payload: any)
			local previous = state.runtimePatches[payload.targetId]
			state.runtimePatches[payload.targetId] = {
				id = "patch:" .. payload.targetId,
				targetId = payload.targetId,
				patch = payload.patch,
				revision = if previous ~= nil then previous.revision + 1 else 1,
				promoted = false,
				commandId = context.commandId,
				createdAt = os.time(),
			}
			return state.runtimePatches[payload.targetId]
		end,
	})

	registry:register({
		commandType = "dm.request_recovery",
		domainId = Domain.id,
		authorize = dm,
		validate = function(payload: any)
			return Helpers.hasString(payload, "target", 128)
		end,
		execute = function(context: any, state: any, payload: any)
			local requestId = "recovery:" .. context.commandId
			state.recoveryRequests[requestId] = {
				id = requestId,
				target = payload.target,
				status = "requested",
				createdAt = os.time(),
			}
			return state.recoveryRequests[requestId]
		end,
	})
end

return table.freeze(Domain)
