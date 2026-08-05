--!strict

local Helpers = require(script.Parent.DomainHelpers)

local Domain = { id = "release", slice = 16 }
local required =
	{ "unit", "integration", "roblox", "migration", "security", "performance", "soak", "rollback" }
local allowedKinds = {}
for _, kind in required do
	allowedKinds[kind] = true
end

function Domain.initialState()
	return { evidence = {}, gate = { status = "blocked", missing = required } }
end

local function evaluate(state: any)
	local missing = {}
	for _, kind in required do
		local evidence = state.evidence[kind]
		if evidence == nil or evidence.status ~= "pass" then
			table.insert(missing, kind)
		end
	end
	state.gate = {
		status = if #missing == 0 then "pass" else "blocked",
		missing = missing,
		evaluatedAt = os.time(),
	}
	return state.gate
end

function Domain.register(registry: any)
	registry:register({
		commandType = "release.record_evidence",
		domainId = Domain.id,
		authorize = function(context: any)
			return Helpers.requireRole(context, { "dm" })
		end,
		validate = function(payload: any)
			return Helpers.hasString(payload, "kind")
				and allowedKinds[payload.kind] == true
				and (payload.status == "pass" or payload.status == "fail")
				and Helpers.hasString(payload, "reference", 512)
		end,
		execute = function(_: any, state: any, payload: any)
			state.evidence[payload.kind] = {
				status = payload.status,
				reference = payload.reference,
				recordedAt = os.time(),
			}
			return evaluate(state)
		end,
	})

	registry:register({
		commandType = "release.evaluate",
		domainId = Domain.id,
		authorize = function(context: any)
			return Helpers.requireRole(context, { "dm" })
		end,
		execute = function(_: any, state: any)
			return evaluate(state)
		end,
	})
end

return table.freeze(Domain)
