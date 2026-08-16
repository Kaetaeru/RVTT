--!strict

return function(harness: any)
	local ScenarioRuntime = require(script.Parent.ScenarioRuntime)
	local scenario = ScenarioRuntime.new(1602, "dm")
	local heroId =
		scenario:bootstrapCharacter(harness, "Grand Session Hero", "scene:grand-session", {
			strength = 16,
			dexterity = 14,
			constitution = 14,
			intelligence = 12,
			wisdom = 12,
			charisma = 10,
		})
	if heroId == nil then
		return
	end

	local preference = scenario:executeAs("player", 1602, "ui.set_preference", {
		key = "accentPaletteId",
		value = "azure",
	})
	if
		scenario:expectOutcome(harness, preference, "Grand session stores a player UI preference")
		== nil
	then
		return
	end

	local registerPack = scenario:execute("content.register_pack", {
		manifest = {
			packId = "pack:grand-original",
			version = "1.0.0",
			rightsStatus = "original",
			dependencies = {},
			definitions = {
				items = {
					["item:grand-sword"] = { equipSlot = "main-hand" },
				},
			},
		},
	})
	if
		scenario:expectOutcome(harness, registerPack, "Grand session registers original content")
		== nil
	then
		return
	end
	local activatePack = scenario:execute("content.activate_pack", {
		packId = "pack:grand-original",
	})
	if
		scenario:expectOutcome(harness, activatePack, "Grand session activates original content")
		== nil
	then
		return
	end

	local authoredScene = scenario:execute("authoring.create_scene", {
		name = "Grand Authored Scene",
	})
	local authoredSceneOutcome = scenario:expectOutcome(
		harness,
		authoredScene,
		"Grand session creates authored scene source"
	)
	if authoredSceneOutcome == nil then
		return
	end
	local authoredSceneId = authoredSceneOutcome.id
	local authoredObject = scenario:execute("authoring.upsert_object", {
		sceneId = authoredSceneId,
		object = {
			id = "object:grand-authored-door",
			kind = "door",
			position = { x = 4, y = 0, z = 4 },
		},
	})
	if
		scenario:expectOutcome(
			harness,
			authoredObject,
			"Grand session authors a stable scene object"
		) == nil
	then
		return
	end
	local compile = scenario:execute("authoring.compile", { sceneId = authoredSceneId })
	if scenario:expectOutcome(harness, compile, "Grand session compiles authored scene") == nil then
		return
	end
	local publish = scenario:execute("authoring.publish", { sceneId = authoredSceneId })
	if
		scenario:expectOutcome(harness, publish, "Grand session publishes authored scene") == nil
	then
		return
	end

	local journal = scenario:executeAs("player", 1602, "journal.create", {
		title = "Grand Session Notes",
		body = "# Session\nCross-slice acceptance note.",
		visibility = "private",
	})
	local journalOutcome =
		scenario:expectOutcome(harness, journal, "Grand session creates player journal")
	if journalOutcome == nil then
		return
	end

	local item = scenario:execute("inventory.create_item", {
		definitionId = "item:grand-sword",
		quantity = 1,
		location = {
			kind = "ground",
			ownerUserId = 1602,
			position = { x = 2, y = 0, z = 2 },
		},
	})
	local itemOutcome = scenario:expectOutcome(harness, item, "Grand session creates world loot")
	if itemOutcome == nil then
		return
	end
	local itemId = itemOutcome.item.id
	local pickup = scenario:executeAs("player", 1602, "inventory.move_item", {
		itemId = itemId,
		location = { kind = "inventory", characterId = heroId },
	})
	if scenario:expectOutcome(harness, pickup, "Grand session picks up world loot") == nil then
		return
	end
	local equip = scenario:executeAs("player", 1602, "inventory.equip", {
		itemId = itemId,
		characterId = heroId,
	})
	if scenario:expectOutcome(harness, equip, "Grand session equips world loot") == nil then
		return
	end

	local door = scenario:execute("scene.spawn_object", {
		kind = "door",
		position = { x = 6, y = 0, z = 0 },
		state = { state = "closed", locked = false },
		interactionIds = { "open" },
	})
	local doorOutcome =
		scenario:expectOutcome(harness, door, "Grand session spawns an exploration door")
	if doorOutcome == nil then
		return
	end
	local interact = scenario:executeAs("player", 1602, "exploration.interact", {
		actorId = heroId,
		objectId = doorOutcome.id,
		interactionId = "open",
	})
	if
		scenario:expectOutcome(harness, interact, "Grand session opens the exploration door")
		== nil
	then
		return
	end

	local challenge = scenario:execute("rules.create_challenge", {
		ability = "strength",
		proficient = true,
		difficultyClass = 1,
		labelKey = "grand.session.check",
	})
	local challengeOutcome =
		scenario:expectOutcome(harness, challenge, "Grand session creates a rules challenge")
	if challengeOutcome == nil then
		return
	end
	local check = scenario:executeAs("player", 1602, "rules.ability_check", {
		actorId = heroId,
		challengeId = challengeOutcome.challengeId,
	})
	local checkOutcome =
		scenario:expectOutcome(harness, check, "Grand session resolves a player ability check")
	if checkOutcome == nil then
		return
	end
	harness:expect(checkOutcome.data.success == true, "Grand session DC 1 check succeeds")

	local target = scenario:execute("scene.spawn_actor", {
		position = { x = 10, y = 0, z = 0 },
	})
	local targetOutcome =
		scenario:expectOutcome(harness, target, "Grand session spawns encounter target")
	if targetOutcome == nil then
		return
	end
	local encounter = scenario:execute("encounter.start", {
		encounterId = "encounter:grand-session",
		participants = { heroId, targetOutcome.id },
		objective = "objective:grand-session",
	})
	if scenario:expectOutcome(harness, encounter, "Grand session starts an encounter") == nil then
		return
	end
	local endEncounter = scenario:execute("encounter.end", {
		reason = "grand-session-resolved",
	})
	if scenario:expectOutcome(harness, endEncounter, "Grand session ends the encounter") == nil then
		return
	end

	local schedule = scenario:execute("time.schedule", {
		scheduleId = "schedule:grand-session",
		afterSeconds = 600,
		payload = { event = "event:grand-session" },
	})
	if
		scenario:expectOutcome(harness, schedule, "Grand session schedules campaign time event")
		== nil
	then
		return
	end
	local activity = scenario:executeAs("player", 1602, "time.start_activity", {
		activityId = "activity:grand-session",
		kind = "rest",
		characterId = heroId,
	})
	if
		scenario:expectOutcome(harness, activity, "Grand session starts a player activity") == nil
	then
		return
	end

	local quickAction = scenario:execute("dm.quick_action", {
		actionId = "action:grand-session-note",
		payload = { documentId = journalOutcome.id },
	})
	if
		scenario:expectOutcome(harness, quickAction, "Grand session records a DM quick action")
		== nil
	then
		return
	end

	local snapshot = scenario:snapshot()
	harness:expect(
		snapshot.revision >= 20,
		"Grand session accumulates one monotonic authority revision stream"
	)
	harness:equal(
		snapshot.domains.ui_preferences.byUser["1602"].accentPaletteId,
		"azure",
		"Grand session keeps UI preference"
	)
	harness:equal(
		snapshot.domains.content.active["pack:grand-original"],
		"1.0.0",
		"Grand session keeps active content version"
	)
	harness:expect(
		snapshot.domains.scene_authoring.published[authoredSceneId] ~= nil,
		"Grand session keeps published scene"
	)
	harness:expect(
		snapshot.domains.journal.documents[journalOutcome.id] ~= nil,
		"Grand session keeps journal document"
	)
	harness:equal(
		snapshot.domains.inventory.locations[itemId].kind,
		"equipped",
		"Grand session keeps equipped item location"
	)
	harness:equal(
		snapshot.domains.exploration.objectStates[doorOutcome.id].state,
		"open",
		"Grand session keeps exploration state"
	)
	harness:expect(
		snapshot.domains.encounter.active == nil,
		"Grand session returns from encounter to exploration"
	)
	harness:equal(
		snapshot.domains.time.activities["activity:grand-session"].status,
		"started",
		"Grand session keeps active downtime"
	)
	harness:equal(
		#snapshot.domains.dm_workspace.quickActions,
		1,
		"Grand session keeps DM audit action"
	)

	local restored = ScenarioRuntime.new(1602, "dm")
	local restore = restored:restore(snapshot)
	harness:expect(restore.ok, "Grand cross-slice snapshot restores")
	if restore.ok then
		local restoredDomains = restored:snapshot().domains
		harness:equal(
			restoredDomains.inventory.locations[itemId].kind,
			"equipped",
			"restore keeps cross-slice inventory"
		)
		harness:expect(
			restoredDomains.scene_authoring.published[authoredSceneId] ~= nil,
			"restore keeps cross-slice published scene"
		)
		harness:expect(
			restoredDomains.journal.documents[journalOutcome.id] ~= nil,
			"restore keeps cross-slice journal"
		)
		harness:equal(
			restoredDomains.exploration.objectStates[doorOutcome.id].state,
			"open",
			"restore keeps cross-slice exploration"
		)
		harness:equal(
			restoredDomains.time.activities["activity:grand-session"].status,
			"started",
			"restore keeps cross-slice activity"
		)
	end
end
