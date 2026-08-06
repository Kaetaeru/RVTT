--!strict

local Helpers = require(script.Parent.DomainHelpers)

local Domain = { id = "rules_content", slice = 14 }
local supported = { spells = true, equipment = true, conditions = true }

function Domain.initialState()
	return { spells = {}, equipment = {}, conditions = {}, rightsStatus = "blocked_until_review" }
end

function Domain.register(registry: any)
	registry:register({
		commandType = "rules_content.register",
		domainId = Domain.id,
		authorize = function(context: any)
			return Helpers.requireRole(context, { "dm" })
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "kind")
				and supported[payload.kind] == true
				and type(payload.entries) == "table"
				and (payload.rightsStatus == "approved" or payload.rightsStatus == "original")
		end,
		execute = function(_: any, state: any, payload: any)
			local destination = state[payload.kind]
			local count = 0
			for id, entry in payload.entries do
				if type(id) ~= "string" or destination[id] ~= nil then
					return Helpers.conflict("duplicate or invalid content id")
				end
				destination[id] = entry
				count += 1
			end
			return { kind = payload.kind, count = count }
		end,
	})
end

return table.freeze(Domain)
