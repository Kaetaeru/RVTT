--!strict

local Helpers = require(script.Parent.DomainHelpers)

local Domain = { id = "ui_preferences", slice = 8 }
local allowed = {
	uiScale = function(value)
		return type(value) == "number" and value >= 0.8 and value <= 1.4
	end,
	reducedMotion = function(value)
		return type(value) == "boolean"
	end,
	flashLimit = function(value)
		return type(value) == "boolean"
	end,
	cameraShake = function(value)
		return type(value) == "boolean"
	end,
	highContrast = function(value)
		return type(value) == "boolean"
	end,
	layout = function(value)
		return type(value) == "string" and #value <= 64
	end,
}

function Domain.initialState()
	return { byUser = {} }
end

function Domain.register(registry: any)
	registry:register({
		commandType = "ui.set_preference",
		domainId = Domain.id,
		authorize = function(context: any)
			return Helpers.authenticated(context)
		end,
		validate = function(payload: any)
			local validator = if type(payload.key) == "string" then allowed[payload.key] else nil
			return validator ~= nil and validator(payload.value)
		end,
		execute = function(context: any, state: any, payload: any)
			local key = tostring(context.playerId)
			state.byUser[key] = state.byUser[key] or {}
			state.byUser[key][payload.key] = payload.value
			return state.byUser[key]
		end,
	})
end

return table.freeze(Domain)
