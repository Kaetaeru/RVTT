--!strict

return function(harness)
	local ScenarioRuntime = require(script.Parent.ScenarioRuntime)
	local scenario = ScenarioRuntime.new(303, "dm")
	local heroId = scenario:bootstrapCharacter(harness, "Slice 03 Hero", "scene:slice-03", {
		strength = 12,
		dexterity = 14,
		constitution = 12,
		intelligence = 12,
		wisdom = 14,
		charisma = 10,
	})
	if heroId == nil then
		return
	end

	local door = scenario:execute("scene.spawn_object", {
		kind = "door",
		position = { x = 4, y = 0, z = 0 },
		state = { state = "closed", locked = false },
		interactionIds = { "open", "close" },
	})
	local doorOutcome = scenario:expectOutcome(harness, door, "Slice 03 spawns an unlocked door")
	if doorOutcome == nil then
		return
	end
	local doorId = doorOutcome.id

	local openDoor = scenario:executeAs("player", 303, "exploration.interact", {
		actorId = heroId,
		objectId = doorId,
		interactionId = "open",
	})
	local openDoorOutcome =
		scenario:expectOutcome(harness, openDoor, "Slice 03 opens a door through the player route")
	if openDoorOutcome == nil then
		return
	end
	harness:equal(openDoorOutcome.object.state, "open", "door state commits as open")
	harness:equal(openDoorOutcome.object.revision, 1, "door interaction increments object revision")
	harness:equal(
		openDoorOutcome.object.lastActorId,
		heroId,
		"door records the authoritative actor"
	)

	local unavailable = scenario:executeAs("player", 303, "exploration.interact", {
		actorId = heroId,
		objectId = doorId,
		interactionId = "activate",
	})
	harness:expect(not unavailable.ok, "unavailable interaction is rejected")
	if not unavailable.ok then
		harness:equal(
			unavailable.error.code,
			"CONFLICT",
			"unavailable interaction returns conflict"
		)
	end
	harness:equal(
		scenario:snapshot().domains.exploration.objectStates[doorId].revision,
		1,
		"rejected interaction does not advance object revision"
	)

	local lockedDoor = scenario:execute("scene.spawn_object", {
		kind = "door",
		position = { x = 8, y = 0, z = 0 },
		state = { state = "closed", locked = true },
		interactionIds = { "open" },
	})
	local lockedDoorOutcome =
		scenario:expectOutcome(harness, lockedDoor, "Slice 03 spawns a locked door")
	if lockedDoorOutcome == nil then
		return
	end
	local lockedDoorId = lockedDoorOutcome.id

	local lockedOpen = scenario:executeAs("player", 303, "exploration.interact", {
		actorId = heroId,
		objectId = lockedDoorId,
		interactionId = "open",
	})
	harness:expect(not lockedOpen.ok, "locked door rejects open")
	if not lockedOpen.ok then
		harness:equal(lockedOpen.error.code, "CONFLICT", "locked door returns conflict")
	end
	harness:expect(
		scenario:snapshot().domains.exploration.objectStates[lockedDoorId] == nil,
		"locked door rejection does not create mutable object state"
	)

	local hiddenObject = scenario:execute("scene.spawn_object", {
		kind = "trap",
		position = { x = 12, y = 0, z = 0 },
		state = { state = "armed" },
		interactionIds = { "inspect" },
		searchDc = 1,
		knowledgeIds = { "knowledge:trap-03" },
		hidden = true,
	})
	local hiddenObjectOutcome =
		scenario:expectOutcome(harness, hiddenObject, "Slice 03 spawns a hidden searchable object")
	if hiddenObjectOutcome == nil then
		return
	end
	local hiddenObjectId = hiddenObjectOutcome.id

	local hiddenInteract = scenario:executeAs("player", 303, "exploration.interact", {
		actorId = heroId,
		objectId = hiddenObjectId,
		interactionId = "inspect",
	})
	harness:expect(not hiddenInteract.ok, "hidden object is not interactable before discovery")
	if not hiddenInteract.ok then
		harness:equal(
			hiddenInteract.error.code,
			"NOT_FOUND",
			"hidden object uses non-disclosing denial"
		)
	end

	local search = scenario:executeAs("player", 303, "exploration.search", {
		actorId = heroId,
		objectId = hiddenObjectId,
	})
	local searchOutcome =
		scenario:expectOutcome(harness, search, "Slice 03 resolves a successful search")
	if searchOutcome == nil then
		return
	end
	harness:expect(searchOutcome.resolution.success == true, "DC 1 search succeeds")
	harness:equal(#searchOutcome.revealed, 1, "successful search reveals one knowledge entry")
	harness:equal(
		searchOutcome.revealed[1],
		"knowledge:trap-03",
		"search reveals the expected knowledge"
	)
	harness:expect(
		scenario:snapshot().domains.scene.objects[hiddenObjectId].hidden == false,
		"successful search reveals the object"
	)
	harness:expect(
		scenario:snapshot().domains.exploration.knowledge["303:knowledge:trap-03"] == true,
		"knowledge is scoped to the searching user"
	)

	local hardSecret = scenario:execute("scene.spawn_object", {
		kind = "secret",
		position = { x = 16, y = 0, z = 0 },
		state = { state = "hidden" },
		interactionIds = { "inspect" },
		searchDc = 40,
		knowledgeIds = { "knowledge:secret-03" },
		hidden = true,
	})
	local hardSecretOutcome =
		scenario:expectOutcome(harness, hardSecret, "Slice 03 spawns a hard secret")
	if hardSecretOutcome == nil then
		return
	end
	local hardSecretId = hardSecretOutcome.id

	local failedSearch = scenario:executeAs("player", 303, "exploration.search", {
		actorId = heroId,
		objectId = hardSecretId,
	})
	local failedSearchOutcome = scenario:expectOutcome(
		harness,
		failedSearch,
		"Slice 03 records a failed search without revealing knowledge"
	)
	if failedSearchOutcome == nil then
		return
	end
	harness:expect(failedSearchOutcome.resolution.success == false, "DC 40 search fails")
	harness:equal(#failedSearchOutcome.revealed, 0, "failed search reveals no knowledge entries")
	harness:expect(
		scenario:snapshot().domains.scene.objects[hardSecretId].hidden == true,
		"failed search keeps the secret object hidden"
	)
	harness:expect(
		scenario:snapshot().domains.exploration.knowledge["303:knowledge:secret-03"] == nil,
		"failed search creates no knowledge record"
	)

	local fog = scenario:execute("exploration.set_fog", {
		regionId = "region:slice-03",
		hidden = true,
	})
	local fogOutcome = scenario:expectOutcome(harness, fog, "Slice 03 applies manual fog")
	if fogOutcome == nil then
		return
	end
	harness:expect(fogOutcome.hidden == true, "manual fog is hidden")
	harness:equal(fogOutcome.revision, 1, "manual fog starts at revision one")

	local deniedFog = scenario:executeAs("player", 303, "exploration.set_fog", {
		regionId = "region:slice-03",
		hidden = false,
	})
	harness:expect(not deniedFog.ok, "player cannot mutate manual fog")
	if not deniedFog.ok then
		harness:equal(deniedFog.error.code, "UNAUTHORIZED", "manual fog denial is explicit")
	end
	harness:expect(
		scenario:snapshot().domains.exploration.fog["region:slice-03"].hidden == true,
		"denied fog command does not mutate state"
	)

	local persisted = scenario:snapshot()
	local restored = ScenarioRuntime.new(303, "dm")
	local restore = restored:restore(persisted)
	harness:expect(restore.ok, "Slice 03 snapshot restores")
	if restore.ok then
		local restoredDomains = restored:snapshot().domains
		harness:equal(
			restoredDomains.exploration.objectStates[doorId].state,
			"open",
			"restore preserves object interaction state"
		)
		harness:expect(
			restoredDomains.exploration.knowledge["303:knowledge:trap-03"] == true,
			"restore preserves user knowledge"
		)
		harness:expect(
			restoredDomains.exploration.fog["region:slice-03"].hidden == true,
			"restore preserves fog state"
		)
	end
end
