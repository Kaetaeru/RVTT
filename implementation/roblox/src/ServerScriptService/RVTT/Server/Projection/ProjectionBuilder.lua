--!strict

local Version = require(game:GetService("ReplicatedStorage").RVTT.Shared.Core.Version)
local CharacterSheetProjection = require(script.Parent.CharacterSheetProjection)
local DomainProjectionPolicy = require(script.Parent.DomainProjectionPolicy)

local ProjectionBuilder = {}
ProjectionBuilder.__index = ProjectionBuilder

function ProjectionBuilder.new()
	return setmetatable({ sequenceByUserId = {} }, ProjectionBuilder)
end

function ProjectionBuilder:build(state, userId: number, role: string)
	local sequence = (self.sequenceByUserId[userId] or 0) + 1
	self.sequenceByUserId[userId] = sequence
	local viewer = { userId = userId, role = role }
	local projectedDomains = {}
	for domainId, domainState in state.domains do
		projectedDomains[domainId] =
			DomainProjectionPolicy.project(domainId, domainState, viewer, state.domains)
	end
	return {
		protocolVersion = Version.PROTOCOL,
		authorityEpoch = state.authorityEpoch,
		revision = state.revision,
		projectionSequence = sequence,
		projectionType = "authority.snapshot",
		payload = {
			schemaVersion = state.schemaVersion,
			authorityEpoch = state.authorityEpoch,
			revision = state.revision,
			domains = projectedDomains,
			characterSheet = CharacterSheetProjection.build(
				state.domains,
				viewer,
				state.revision,
				nil
			),
		},
	}
end

return ProjectionBuilder
