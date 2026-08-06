--!strict

return function(harness)
	local ScenarioRuntime = require(script.Parent.ScenarioRuntime)
	local scenario = ScenarioRuntime.new(505, "player")

	local draft = scenario:execute("character.create_draft", { name = "" })
	local draftOutcome = scenario:expectOutcome(harness, draft, "Slice 05 creates a character draft")
	if draftOutcome == nil then
		return
	end
	local characterId = draftOutcome.id
	harness:equal(draftOutcome.status, "draft", "new character starts as a draft")
	harness:equal(draftOutcome.level, 1, "new character starts at level one")
	harness:equal(draftOutcome.revision, 1, "new draft starts at revision one")

	local incompleteActivation = scenario:execute("character.activate", {
		characterId = characterId,
	})
	harness:expect(not incompleteActivation.ok, "incomplete character draft cannot activate")
	if not incompleteActivation.ok then
		harness:equal(incompleteActivation.error.code, "CONFLICT", "incomplete activation returns conflict")
	end
	harness:expect(
		scenario:snapshot().domains.character.drafts[characterId] ~= nil,
		"failed activation keeps the draft"
	)

	local invalidAbilities = scenario:execute("character.update_draft", {
		characterId = characterId,
		patch = {
			abilities = {
				strength = 30,
				dexterity = 10,
				constitution = 10,
				intelligence = 10,
				wisdom = 10,
				charisma = 10,
			},
		},
	})
	harness:expect(not invalidAbilities.ok, "invalid ability scores are rejected")
	if not invalidAbilities.ok then
		harness:equal(invalidAbilities.error.code, "VALIDATION_FAILED", "invalid ability scores use validation error")
	end

	local update = scenario:execute("character.update_draft", {
		characterId = characterId,
		patch = {
			name = "Slice 05 Hero",
			ancestryId = "ancestry:test",
			backgroundId = "background:test",
			classId = "class:test",
			abilities = {
				strength = 16,
				dexterity = 14,
				constitution = 14,
				intelligence = 10,
				wisdom = 12,
				charisma = 8,
			},
			choices = { language = "common" },
			serverOnlyMutation = "ignored",
		},
	})
	local updateOutcome = scenario:expectOutcome(harness, update, "Slice 05 updates the character draft")
	if updateOutcome == nil then
		return
	end
	harness:equal(updateOutcome.name, "Slice 05 Hero", "draft name updates")
	harness:equal(updateOutcome.abilities.strength, 16, "draft ability scores update")
	harness:equal(updateOutcome.revision, 2, "valid draft update increments revision")
	harness:expect(updateOutcome.serverOnlyMutation == nil, "draft update ignores fields outside the allowlist")

	local deniedUpdate = scenario:executeAs("player", 999, "character.update_draft", {
		characterId = characterId,
		patch = { name = "Stolen Character" },
	})
	harness:expect(not deniedUpdate.ok, "non-owner cannot update a character draft")
	if not deniedUpdate.ok then
		harness:equal(deniedUpdate.error.code, "UNAUTHORIZED", "draft ownership denial is explicit")
	end

	local activation = scenario:execute("character.activate", {
		characterId = characterId,
	})
	local activationOutcome = scenario:expectOutcome(harness, activation, "Slice 05 activates a complete character")
	if activationOutcome == nil then
		return
	end
	harness:equal(activationOutcome.status, "active", "activated character is active")
	harness:equal(activationOutcome.revision, 3, "activation increments character revision")
	local characterState = scenario:snapshot().domains.character
	harness:expect(characterState.drafts[characterId] == nil, "activation removes the draft entry")
	harness:expect(characterState.characters[characterId] ~= nil, "activation creates the active character entry")

	local skippedLevel = scenario:execute("character.level_up", {
		characterId = characterId,
		level = 3,
	})
	harness:expect(not skippedLevel.ok, "level-up cannot skip a level")
	if not skippedLevel.ok then
		harness:equal(skippedLevel.error.code, "CONFLICT", "invalid next level returns conflict")
	end

	local deniedLevel = scenario:executeAs("player", 999, "character.level_up", {
		characterId = characterId,
		level = 2,
	})
	harness:expect(not deniedLevel.ok, "non-owner cannot level another character")
	if not deniedLevel.ok then
		harness:equal(deniedLevel.error.code, "UNAUTHORIZED", "level ownership denial is explicit")
	end

	local levelUp = scenario:execute("character.level_up", {
		characterId = characterId,
		level = 2,
		choices = { feature = "feature:test" },
	})
	local levelOutcome = scenario:expectOutcome(harness, levelUp, "Slice 05 advances the character one level")
	if levelOutcome == nil then
		return
	end
	harness:equal(levelOutcome.level, 2, "valid level-up advances exactly one level")
	harness:equal(levelOutcome.choices[2].feature, "feature:test", "level choices are stored by level")
	harness:equal(levelOutcome.revision, 4, "level-up increments character revision")

	local persisted = scenario:snapshot()
	local restored = ScenarioRuntime.new(505, "player")
	local restore = restored:restore(persisted)
	harness:expect(restore.ok, "Slice 05 snapshot restores")
	if restore.ok then
		local restoredCharacter = restored:snapshot().domains.character.characters[characterId]
		harness:equal(restoredCharacter.status, "active", "restore preserves activation state")
		harness:equal(restoredCharacter.level, 2, "restore preserves character level")
		harness:equal(restoredCharacter.revision, 4, "restore preserves character revision")
	end
end
