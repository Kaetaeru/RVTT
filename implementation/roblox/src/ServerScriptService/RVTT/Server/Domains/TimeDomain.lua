--!strict

local Helpers = require(script.Parent.DomainHelpers)

local Domain = { id = "time", slice = 7 }
local ALLOWED_ACTIVITY =
	{ rest = true, travel = true, crafting = true, training = true, downtime = true }

function Domain.initialState()
	return { campaignSeconds = 0, schedules = {}, activities = {} }
end

function Domain.register(registry: any)
	registry:register({
		commandType = "time.advance",
		domainId = Domain.id,
		authorize = function(context: any)
			return Helpers.requireRole(context, { "dm" })
		end,
		validate = function(payload: any)
			return Helpers.hasNumber(payload, "seconds")
				and payload.seconds >= 0
				and payload.seconds <= 31536000
		end,
		execute = function(_: any, state: any, payload: any)
			state.campaignSeconds += math.floor(payload.seconds)
			local due = {}
			for id, item in state.schedules do
				if item.dueAt <= state.campaignSeconds and item.status == "scheduled" then
					item.status = "due"
					table.insert(due, id)
				end
			end
			return { campaignSeconds = state.campaignSeconds, due = due }
		end,
	})

	registry:register({
		commandType = "time.schedule",
		domainId = Domain.id,
		authorize = function(context: any)
			return Helpers.requireRole(context, { "dm" })
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "scheduleId")
				and Helpers.hasNumber(payload, "afterSeconds")
				and payload.afterSeconds >= 0
		end,
		execute = function(_: any, state: any, payload: any)
			if state.schedules[payload.scheduleId] ~= nil then
				return Helpers.conflict("schedule id already exists")
			end
			state.schedules[payload.scheduleId] = {
				dueAt = state.campaignSeconds + math.floor(payload.afterSeconds),
				payload = payload.payload or {},
				status = "scheduled",
			}
			return state.schedules[payload.scheduleId]
		end,
	})

	registry:register({
		commandType = "time.start_activity",
		domainId = Domain.id,
		authorize = function(context: any, domains: any, payload: any)
			return Helpers.authenticated(context)
				and Helpers.ownsCharacter(context, domains, payload.characterId)
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "activityId")
				and Helpers.hasString(payload, "kind")
				and Helpers.hasString(payload, "characterId")
				and ALLOWED_ACTIVITY[payload.kind] == true
		end,
		execute = function(context: any, state: any, payload: any)
			if state.activities[payload.activityId] ~= nil then
				return Helpers.conflict("activity id already exists")
			end
			state.activities[payload.activityId] = {
				kind = payload.kind,
				characterId = payload.characterId,
				ownerUserId = context.playerId,
				status = "started",
				startedAt = state.campaignSeconds,
			}
			return state.activities[payload.activityId]
		end,
	})

	registry:register({
		commandType = "time.resolve_activity",
		domainId = Domain.id,
		authorize = function(context: any, domains: any, payload: any)
			local activity = domains.time.activities[payload.activityId]
			return context.role == "dm"
				or (activity ~= nil and activity.ownerUserId == context.playerId)
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "activityId")
				and (payload.status == "completed" or payload.status == "cancelled")
		end,
		execute = function(_: any, state: any, payload: any)
			local activity = state.activities[payload.activityId]
			if activity == nil then
				return Helpers.notFound("activity", payload.activityId)
			end
			activity.status = payload.status
			activity.resolvedAt = state.campaignSeconds
			return activity
		end,
	})
end

return table.freeze(Domain)
