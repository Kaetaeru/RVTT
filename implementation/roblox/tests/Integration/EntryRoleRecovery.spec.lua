--!strict

return function(harness: any)
	local Server = game:GetService("ServerScriptService").RVTT.Server
	local ScenarioRuntime = require(script.Parent.ScenarioRuntime)
	local Builder = require(Server.Projection.ProjectionBuilder).new()
	local scenario = ScenarioRuntime.new(1, "dm")

	harness:expect(scenario:execute("session.join", {}).ok, "DM joins authoritatively")
	local observerJoin = scenario:executeAs("observer", 22, "session.join", {})
	harness:expect(observerJoin.ok, "non-DM joins the session")
	harness:equal(
		scenario:snapshot().domains.session.memberships["22"].role,
		"observer",
		"non-DM join is observer-first even when transport role is not trusted"
	)

	local draft = scenario:execute("character.create_draft", { name = "Assigned Hero" })
	local characterId = draft.value.outcome.id
	harness:expect(
		scenario:execute("character.activate", { characterId = characterId }).ok,
		"DM activates an assignable character"
	)
	local optimistic =
		scenario:executeAs("player", 22, "session.select_character", { characterId = characterId })
	harness:expect(
		not optimistic.ok and optimistic.error.code == "UNAUTHORIZED",
		"local or transport player claim cannot self-assign"
	)

	local assignmentId = "entry-role-recovery:assign-once"
	local assigned = scenario:executeDuplicate(
		assignmentId,
		"session.assign_character",
		{ userId = 22, characterId = characterId }
	)
	local revisionAfterAssignment = scenario:snapshot().revision
	local duplicate = scenario:executeDuplicate(
		assignmentId,
		"session.assign_character",
		{ userId = 22, characterId = characterId }
	)
	harness:expect(assigned.ok and duplicate.ok, "assignment retry returns the committed result")
	harness:equal(
		scenario:snapshot().revision,
		revisionAfterAssignment,
		"idempotent retry does not duplicate the domain mutation"
	)
	harness:equal(
		scenario:snapshot().domains.session.memberships["22"].role,
		"player",
		"DM assignment authoritatively transitions observer to player"
	)
	harness:expect(
		scenario:executeAs("player", 22, "session.ready", { ready = true }).ok,
		"assigned connected player can submit ready"
	)
	harness:expect(
		scenario:snapshot().domains.session.ready["22"] == true,
		"ready state is stored only after authoritative command"
	)

	local playerProjection = Builder:build(scenario:snapshot(), 22, "player")
	harness:expect(
		next(playerProjection.payload.domains.dm_workspace) == nil,
		"player receives no DM workspace projection"
	)
	local revoke = scenario:execute("session.assign_character", { userId = 22, characterId = nil })
	harness:expect(revoke.ok, "DM can revoke the assignment atomically")
	local state = scenario:snapshot()
	harness:equal(
		state.domains.session.memberships["22"].role,
		"observer",
		"revocation restores observer"
	)
	harness:equal(state.domains.session.selectedCharacter["22"], nil, "revocation clears selection")
	harness:equal(state.domains.session.ready["22"], nil, "revocation clears ready")

	local observerProjection = Builder:build(state, 22, "observer")
	local publicCharacter = observerProjection.payload.domains.character.characters[characterId]
	harness:expect(
		type(publicCharacter) == "table" and publicCharacter.abilities == nil,
		"revoked observer retains no private character fields"
	)
	harness:expect(
		next(observerProjection.payload.domains.dm_workspace) == nil,
		"observer receives no DM workspace projection"
	)
end
