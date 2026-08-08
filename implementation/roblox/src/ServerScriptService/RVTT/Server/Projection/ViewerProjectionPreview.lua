--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)
local DomainProjectionPolicy = require(script.Parent.DomainProjectionPolicy)

local ViewerProjectionPreview = {}

local function targetMembership(state: any, targetUserId: number): any?
	local domains = if type(state) == "table" then state.domains else nil
	local session = if type(domains) == "table" then domains.session else nil
	local memberships = if type(session) == "table" then session.memberships else nil
	return if type(memberships) == "table" then memberships[tostring(targetUserId)] else nil
end

function ViewerProjectionPreview.build(state: any, targetUserId: number): any
	local membership = targetMembership(state, targetUserId)
	if type(membership) ~= "table" then
		return Result.err("PREVIEW_TARGET_NOT_FOUND", "error.dm.preview_target_not_found", false)
	end
	local role = membership.role
	if role ~= "player" and role ~= "observer" then
		return Result.err(
			"PREVIEW_TARGET_INVALID_ROLE",
			"error.dm.preview_target_invalid_role",
			false
		)
	end
	local session = state.domains.session
	local selectedCharacter = if type(session.selectedCharacter) == "table"
		then session.selectedCharacter[tostring(targetUserId)]
		else nil
	if role == "player" and type(selectedCharacter) ~= "string" then
		return Result.err("PREVIEW_TARGET_UNASSIGNED", "error.dm.preview_target_unassigned", false)
	end

	local viewer = { userId = targetUserId, role = role }
	local domains = {}
	for domainId, domainState in state.domains do
		domains[domainId] =
			DomainProjectionPolicy.project(domainId, domainState, viewer, state.domains)
	end

	return Result.ok({
		target = {
			userId = targetUserId,
			role = role,
			selectedCharacterId = selectedCharacter,
		},
		authorityEpoch = state.authorityEpoch,
		revision = state.revision,
		payload = {
			schemaVersion = state.schemaVersion,
			authorityEpoch = state.authorityEpoch,
			revision = state.revision,
			domains = domains,
		},
	})
end

return table.freeze(ViewerProjectionPreview)
