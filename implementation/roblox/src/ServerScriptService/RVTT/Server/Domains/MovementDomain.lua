--!strict

local Result = require(game:GetService("ReplicatedStorage").RVTT.Shared.Core.Result)
local Helpers = require(script.Parent.DomainHelpers)

local Domain = { id = "movement", slice = 1 }
local SAFETY_MAX_DISTANCE_STUDS = 200

function Domain.initialState()
	return { executions = {}, checkpoints = {} }
end

local function distanceBetween(left: any, right: any): number
	return math.sqrt((right.x - left.x) ^ 2 + (right.y - left.y) ^ 2 + (right.z - left.z) ^ 2)
end

function Domain.register(registry: any)
	registry:register({
		commandType = "movement.commit",
		domainId = Domain.id,
		authorize = function(context: any, domains: any, payload: any)
			return Helpers.controlsActor(context, domains, payload.actorId)
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "actorId") and Helpers.isVector(payload.destination)
		end,
		execute = function(context: any, state: any, payload: any, domains: any)
			local actor = domains.scene.actors[payload.actorId]
			if actor == nil then
				return Helpers.notFound("actor", payload.actorId)
			end
			local destination = payload.destination
			local current = actor.position
			local distance = distanceBetween(current, destination)
			if distance > SAFETY_MAX_DISTANCE_STUDS then
				return Result.err(
					"VALIDATION_FAILED",
					"error.validation.failed",
					false,
					{ reason = "movement safety bound" } :: { [string]: unknown }
				)
			end

			local encounter = domains.encounter.active
			if encounter ~= nil then
				local currentEntry = encounter.timeline[encounter.cursor]
				if currentEntry == nil or currentEntry.actorId ~= payload.actorId then
					return Helpers.conflict("actor does not own the active turn")
				end
				if distance > encounter.movementRemaining then
					return Helpers.conflict("movement budget exceeded")
				end
				encounter.movementRemaining -= distance
			end

			local executionId = "move:" .. context.commandId
			state.executions[executionId] = {
				actorId = payload.actorId,
				from = current,
				destination = destination,
				distance = distance,
				status = "committed",
			}
			actor.position = { x = destination.x, y = destination.y, z = destination.z }
			domains.scene.sceneRevision += 1
			table.insert(state.checkpoints, {
				executionId = executionId,
				actorId = payload.actorId,
				position = actor.position,
				sceneRevision = domains.scene.sceneRevision,
			})
			return { executionId = executionId, position = actor.position, distance = distance }
		end,
	})
end

return table.freeze(Domain)
