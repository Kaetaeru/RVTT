--!strict

return function(harness)
	local ScenarioRuntime = require(script.Parent.ScenarioRuntime)
	local scenario = ScenarioRuntime.new(404, "dm")
	local heroId = scenario:bootstrapCharacter(harness, "Slice 04 Hero", "scene:slice-04", {
		strength = 18,
		dexterity = 16,
		constitution = 14,
		intelligence = 10,
		wisdom = 12,
		charisma = 10,
	})
	if heroId == nil then
		return
	end

	local target = scenario:execute("scene.spawn_actor", {
		position = { x = 6, y = 0, z = 0 },
	})
	local targetOutcome =
		scenario:expectOutcome(harness, target, "Slice 04 spawns an encounter target")
	if targetOutcome == nil then
		return
	end
	local targetId = targetOutcome.id

	local deniedStart = scenario:executeAs("player", 404, "encounter.start", {
		participants = { heroId, targetId },
	})
	harness:expect(not deniedStart.ok, "player cannot start an encounter")
	if not deniedStart.ok then
		harness:equal(deniedStart.error.code, "UNAUTHORIZED", "encounter start denial is explicit")
	end

	local start = scenario:execute("encounter.start", {
		encounterId = "encounter:slice-04",
		participants = { heroId, targetId },
		objective = "objective:slice-04",
	})
	local startOutcome = scenario:expectOutcome(harness, start, "Slice 04 starts an encounter")
	if startOutcome == nil then
		return
	end
	harness:equal(startOutcome.id, "encounter:slice-04", "encounter keeps its requested identity")
	harness:equal(startOutcome.status, "active", "encounter starts active")
	harness:equal(startOutcome.round, 1, "encounter starts on round one")
	harness:equal(startOutcome.cursor, 1, "encounter starts at the first timeline entry")
	harness:equal(#startOutcome.timeline, 2, "encounter has both participants")
	harness:expect(startOutcome.opportunities.action == true, "active turn starts with an action")
	harness:expect(
		startOutcome.opportunities.reaction == true,
		"active turn starts with a reaction"
	)
	harness:equal(
		#scenario:snapshot().domains.encounter.checkpoints,
		1,
		"encounter start creates a checkpoint"
	)

	local duplicateStart = scenario:execute("encounter.start", {
		participants = { heroId },
	})
	harness:expect(not duplicateStart.ok, "second active encounter is rejected")
	if not duplicateStart.ok then
		harness:equal(duplicateStart.error.code, "CONFLICT", "duplicate encounter returns conflict")
	end

	local guard = 0
	while
		scenario:snapshot().domains.encounter.active.timeline[scenario:snapshot().domains.encounter.active.cursor].actorId
			~= heroId
		and guard < 3
	do
		guard += 1
		local advance = scenario:execute("encounter.end_turn", {})
		if
			scenario:expectOutcome(harness, advance, "DM advances to the controlled actor turn")
			== nil
		then
			return
		end
	end

	local active = scenario:snapshot().domains.encounter.active
	local currentEntry = active.timeline[active.cursor]
	harness:equal(currentEntry.actorId, heroId, "test reaches the controlled actor turn")

	local attack = scenario:executeAs("player", 404, "rules.attack", {
		attackerId = heroId,
		targetId = targetId,
		profileId = "attack.unarmed",
	})
	local attackOutcome = scenario:expectOutcome(
		harness,
		attack,
		"controlled actor uses the encounter action opportunity"
	)
	if attackOutcome == nil then
		return
	end
	harness:equal(attackOutcome.kind, "attack", "encounter attack creates a roll record")
	harness:expect(
		scenario:snapshot().domains.encounter.active.opportunities.action == false,
		"attack consumes the action opportunity"
	)

	local repeatedAttack = scenario:executeAs("player", 404, "rules.attack", {
		attackerId = heroId,
		targetId = targetId,
		profileId = "attack.unarmed",
	})
	harness:expect(not repeatedAttack.ok, "second action in the same turn is rejected")
	if not repeatedAttack.ok then
		harness:equal(repeatedAttack.error.code, "CONFLICT", "spent action returns conflict")
	end

	local deniedTurn = scenario:executeAs("player", 999, "encounter.end_turn", {})
	harness:expect(not deniedTurn.ok, "unrelated player cannot end the active turn")
	if not deniedTurn.ok then
		harness:equal(deniedTurn.error.code, "UNAUTHORIZED", "turn ownership denial is explicit")
	end

	local completedRound = scenario:snapshot().domains.encounter.active.round
	local completedCursor = scenario:snapshot().domains.encounter.active.cursor
	local endControlledTurn = scenario:executeAs("player", 404, "encounter.end_turn", {})
	local endControlledTurnOutcome =
		scenario:expectOutcome(harness, endControlledTurn, "controller ends the active turn")
	if endControlledTurnOutcome == nil then
		return
	end
	harness:expect(
		endControlledTurnOutcome.cursor ~= completedCursor
			or endControlledTurnOutcome.round > completedRound,
		"ending a turn advances cursor or round"
	)
	harness:expect(endControlledTurnOutcome.opportunities.action == true, "next turn resets action")
	harness:expect(
		endControlledTurnOutcome.opportunities.reaction == true,
		"next turn resets reaction"
	)
	harness:expect(
		#scenario:snapshot().domains.encounter.checkpoints >= 2,
		"turn transition adds a checkpoint"
	)

	local epochBeforeRollback = scenario:snapshot().authorityEpoch
	local rollback = scenario:execute("encounter.rollback", { checkpointIndex = 1 })
	local rollbackOutcome =
		scenario:expectOutcome(harness, rollback, "Slice 04 rolls back to the first checkpoint")
	if rollbackOutcome == nil then
		return
	end
	harness:equal(rollbackOutcome.round, 1, "rollback restores the checkpoint round")
	harness:equal(rollbackOutcome.cursor, 1, "rollback restores the checkpoint cursor")
	harness:expect(
		rollbackOutcome.opportunities.action == true,
		"rollback restores action opportunity"
	)
	harness:expect(
		scenario:snapshot().authorityEpoch ~= epochBeforeRollback,
		"rollback refreshes authority epoch"
	)
	local history = scenario:snapshot().domains.encounter.history
	harness:equal(history[#history].kind, "rollback", "rollback is recorded in encounter history")

	local ended = scenario:execute("encounter.end", { reason = "acceptance-complete" })
	local endedOutcome = scenario:expectOutcome(harness, ended, "Slice 04 ends the encounter")
	if endedOutcome == nil then
		return
	end
	harness:equal(endedOutcome.status, "ended", "ended encounter is marked ended")
	harness:equal(endedOutcome.reason, "acceptance-complete", "encounter end reason is retained")
	harness:expect(
		scenario:snapshot().domains.encounter.active == nil,
		"encounter returns to inactive state"
	)

	local persisted = scenario:snapshot()
	local restored = ScenarioRuntime.new(404, "dm")
	local restore = restored:restore(persisted)
	harness:expect(restore.ok, "Slice 04 snapshot restores")
	if restore.ok then
		harness:expect(
			restored:snapshot().domains.encounter.active == nil,
			"restore preserves the ended encounter state"
		)
		harness:expect(
			#restored:snapshot().domains.encounter.history >= 2,
			"restore preserves turn and rollback history"
		)
	end
end
