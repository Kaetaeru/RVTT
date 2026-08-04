--!strict

local DeepCopy = require(game:GetService("ReplicatedStorage").RVTT.Shared.Core.DeepCopy)
local Version = require(game:GetService("ReplicatedStorage").RVTT.Shared.Core.Version)

local ProjectionBuilder = {}
ProjectionBuilder.__index = ProjectionBuilder

function ProjectionBuilder.new()
	return setmetatable({ sequenceByUserId = {} }, ProjectionBuilder)
end

local function removeSecrets(payload, role: string)
	if role == "dm" then
		return payload
	end
	payload.dm = nil
	payload.secrets = nil
	for _, domain in payload.domains or {} do
		if type(domain) == "table" then
			domain.secrets = nil
		end
	end
	return payload
end

function ProjectionBuilder:build(state, userId: number, role: string)
	local sequence = (self.sequenceByUserId[userId] or 0) + 1
	self.sequenceByUserId[userId] = sequence
	local payload = removeSecrets(DeepCopy(state) :: { [string]: unknown }, role)
	return {
		protocolVersion = Version.PROTOCOL,
		authorityEpoch = state.authorityEpoch,
		revision = state.revision,
		projectionSequence = sequence,
		projectionType = "authority.snapshot",
		payload = payload,
	}
end

return ProjectionBuilder
