--!strict

return function(harness)
	local ScenarioRuntime = require(script.Parent.ScenarioRuntime)
	local scenario = ScenarioRuntime.new(202, "dm")
	local heroId = scenario:bootstrapCharacter(harness, "Slice 02 Hero", "scene:slice-02", {
		strength = 20,
		dexterity = 12,
		constitution = 14,
		intelligence = 10,
		wisdom = 14,
		charisma = 10,
	})
	if heroId == nil then
		return
	end

	local easyChallenge = scenario:execute("rules.create_challenge", {
		ability = "strength",
		proficient = true,
		difficultyClass = 1,
		labelKey = "test.slice02.easy",
	})
	local easyChallengeOutcome =
		scenario:expectOutcome(harness, easyChallenge, "Slice 02 creates an easy ability challenge")
	if easyChallengeOutcome == nil then
		return
	end

	local easyCheck = scenario:execute("rules.ability_check", {
		actorId = heroId,
		challengeId = easyChallengeOutcome.challengeId,
		modifier = 999,
	})
	local easyCheckOutcome = scenario:expectOutcome(
		harness,
		easyCheck,
		"Slice 02 resolves a server-authoritative ability check"
	)
	if easyCheckOutcome == nil then
		return
	end
	harness:equal(
		easyCheckOutcome.kind,
		"ability_check",
		"ability check creates the right record kind"
	)
	harness:equal(easyCheckOutcome.data.modifier, 7, "ability modifier is derived on the server")
	harness:equal(easyCheckOutcome.data.difficultyClass, 1, "challenge DC is authoritative")
	harness:expect(easyCheckOutcome.data.success == true, "DC 1 ability check succeeds")
	harness:expect(
		easyCheckOutcome.data.natural >= 1 and easyCheckOutcome.data.natural <= 20,
		"ability check natural roll is bounded"
	)

	local hardChallenge = scenario:execute("rules.create_challenge", {
		ability = "charisma",
		proficient = false,
		difficultyClass = 40,
		labelKey = "test.slice02.hard",
	})
	local hardChallengeOutcome =
		scenario:expectOutcome(harness, hardChallenge, "Slice 02 creates a hard ability challenge")
	if hardChallengeOutcome == nil then
		return
	end

	local hardCheck = scenario:execute("rules.ability_check", {
		actorId = heroId,
		challengeId = hardChallengeOutcome.challengeId,
	})
	local hardCheckOutcome =
		scenario:expectOutcome(harness, hardCheck, "Slice 02 resolves a failed ability check")
	if hardCheckOutcome == nil then
		return
	end
	harness:equal(hardCheckOutcome.data.modifier, 0, "non-proficient modifier is derived")
	harness:expect(hardCheckOutcome.data.success == false, "DC 40 ability check fails")

	local saveChallenge = scenario:execute("rules.create_challenge", {
		ability = "wisdom",
		proficient = false,
		difficultyClass = 1,
		labelKey = "test.slice02.save",
	})
	local saveChallengeOutcome =
		scenario:expectOutcome(harness, saveChallenge, "Slice 02 creates a saving throw challenge")
	if saveChallengeOutcome == nil then
		return
	end

	local savingThrow = scenario:execute("rules.saving_throw", {
		actorId = heroId,
		challengeId = saveChallengeOutcome.challengeId,
	})
	local savingThrowOutcome =
		scenario:expectOutcome(harness, savingThrow, "Slice 02 resolves a saving throw")
	if savingThrowOutcome == nil then
		return
	end
	harness:equal(
		savingThrowOutcome.kind,
		"saving_throw",
		"saving throw creates the right record kind"
	)
	harness:equal(savingThrowOutcome.data.modifier, 4, "saving throw proficiency is server-derived")
	harness:expect(savingThrowOutcome.data.success == true, "DC 1 saving throw succeeds")

	local target = scenario:execute("scene.spawn_actor", {
		position = { x = 8, y = 0, z = 0 },
	})
	local targetOutcome =
		scenario:expectOutcome(harness, target, "Slice 02 spawns an attack target")
	if targetOutcome == nil then
		return
	end
	local targetId = targetOutcome.id

	local setTargetState = scenario:execute("rules.set_actor_state", {
		actorId = targetId,
		currentHitPoints = 20,
		maximumHitPoints = 20,
		temporaryHitPoints = 3,
	})
	if
		scenario:expectOutcome(harness, setTargetState, "Slice 02 initializes target hit points")
		== nil
	then
		return
	end

	local attack = scenario:execute("rules.attack", {
		attackerId = heroId,
		targetId = targetId,
		profileId = "attack.unarmed",
		attackBonus = 999,
		armorClass = -999,
		damage = 999,
	})
	local attackOutcome =
		scenario:expectOutcome(harness, attack, "Slice 02 resolves a server-authoritative attack")
	if attackOutcome == nil then
		return
	end
	harness:equal(attackOutcome.kind, "attack", "attack creates the right record kind")
	harness:equal(attackOutcome.data.modifier, 7, "client attack bonus is ignored")
	harness:equal(attackOutcome.data.armorClass, 10, "client armor class is ignored")
	harness:expect(attackOutcome.data.damage >= 0, "attack damage is non-negative")
	harness:expect(
		attackOutcome.data.damage <= 15,
		"unarmed damage stays within server formula bounds"
	)

	local targetState = scenario:snapshot().domains.rules.actorStates[targetId]
	harness:expect(targetState ~= nil, "target hit point state exists")
	if targetState ~= nil then
		if attackOutcome.data.hit then
			harness:equal(
				targetState.currentHitPoints,
				attackOutcome.data.targetHitPoints,
				"attack projection matches committed hit points"
			)
			harness:expect(
				targetState.temporaryHitPoints <= 3,
				"temporary hit points absorb damage first"
			)
		else
			harness:equal(
				targetState.currentHitPoints,
				20,
				"miss does not mutate current hit points"
			)
			harness:equal(
				targetState.temporaryHitPoints,
				3,
				"miss does not mutate temporary hit points"
			)
		end
	end

	local deniedChallenge = scenario:executeAs("player", 202, "rules.create_challenge", {
		ability = "strength",
		difficultyClass = 10,
	})
	harness:expect(not deniedChallenge.ok, "player cannot create a DM challenge")
	if not deniedChallenge.ok then
		harness:equal(deniedChallenge.error.code, "UNAUTHORIZED", "DM challenge denial is explicit")
	end

	local duplicateCommandId = "slice02:duplicate-check"
	local firstDuplicate = scenario:executeDuplicate(duplicateCommandId, "rules.create_challenge", {
		ability = "wisdom",
		difficultyClass = 10,
	})
	local secondDuplicate =
		scenario:executeDuplicate(duplicateCommandId, "rules.create_challenge", {
			ability = "charisma",
			difficultyClass = 30,
		})
	harness:expect(
		firstDuplicate.ok and secondDuplicate.ok,
		"duplicate command returns a terminal result"
	)
	if firstDuplicate.ok and secondDuplicate.ok then
		harness:equal(
			secondDuplicate.value.outcome.challengeId,
			firstDuplicate.value.outcome.challengeId,
			"duplicate command is idempotent"
		)
		harness:equal(
			secondDuplicate.value.revision,
			firstDuplicate.value.revision,
			"duplicate command does not create a new revision"
		)
	end
end
