--!strict

local Helpers = require(script.Parent.DomainHelpers)

local Domain = { id = "character_content", slice = 13 }

function Domain.initialState()
	return { catalogs = {}, coverage = {}, rightsStatus = "blocked_until_review" }
end

function Domain.register(registry: any)
	registry:register({
		commandType = "character_content.register_catalog",
		domainId = Domain.id,
		authorize = function(context: any)
			return Helpers.requireRole(context, { "dm" })
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "catalogId")
				and type(payload.entries) == "table"
				and (payload.rightsStatus == "approved" or payload.rightsStatus == "original")
		end,
		execute = function(_: any, state: any, payload: any)
			if state.catalogs[payload.catalogId] ~= nil then
				return Helpers.conflict("catalog already registered")
			end
			local count = 0
			for _ in payload.entries do
				count += 1
			end
			state.catalogs[payload.catalogId] = {
				entries = payload.entries,
				sourceVersion = payload.sourceVersion,
				rightsStatus = payload.rightsStatus,
			}
			state.coverage[payload.catalogId] = count
			return { catalogId = payload.catalogId, count = count }
		end,
	})
end

return table.freeze(Domain)
