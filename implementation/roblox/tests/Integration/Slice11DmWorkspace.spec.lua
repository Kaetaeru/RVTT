--!strict

return function(harness)
	local ScenarioRuntime = require(script.Parent.ScenarioRuntime)
	local scenario = ScenarioRuntime.new(1111, "dm")
	local heroId = scenario:bootstrapCharacter(harness, "Slice 11 Hero", "scene:slice-11", nil)
	if heroId == nil then
		return
	end

	local deniedControl = scenario:executeAs("player", 1111, "dm.assign_control", {
		actorId = heroId,
		controllerUserId = 2222,
	})
	harness:expect(not deniedControl.ok, "player cannot assign actor control")
	if not deniedControl.ok then
		harness:equal(
			deniedControl.error.code,
			"UNAUTHORIZED",
			"control assignment denial is explicit"
		)
	end

	local control = scenario:execute("dm.assign_control", {
		actorId = heroId,
		controllerUserId = 2222,
	})
	local controlOutcome =
		scenario:expectOutcome(harness, control, "Slice 11 assigns actor control")
	if controlOutcome == nil then
		return
	end
	harness:equal(controlOutcome.actorId, heroId, "control assignment targets the expected actor")
	harness:equal(
		controlOutcome.controllerUserId,
		2222,
		"control assignment stores the expected controller"
	)
	harness:equal(
		scenario:snapshot().domains.scene.actors[heroId].controllerUserId,
		2222,
		"control assignment updates authoritative actor state"
	)

	local deniedAction = scenario:executeAs("player", 1111, "dm.quick_action", {
		actionId = "action:denied",
	})
	harness:expect(not deniedAction.ok, "player cannot execute a DM quick action")
	if not deniedAction.ok then
		harness:equal(deniedAction.error.code, "UNAUTHORIZED", "quick action denial is explicit")
	end

	local quickAction = scenario:execute("dm.quick_action", {
		actionId = "action:reveal-area",
		payload = { regionId = "region:slice-11" },
	})
	local quickActionOutcome =
		scenario:expectOutcome(harness, quickAction, "Slice 11 records a DM quick action")
	if quickActionOutcome == nil then
		return
	end
	harness:equal(
		quickActionOutcome.actionId,
		"action:reveal-area",
		"quick action keeps its stable action id"
	)
	harness:equal(
		quickActionOutcome.payload.regionId,
		"region:slice-11",
		"quick action keeps its bounded payload"
	)
	harness:expect(
		type(quickActionOutcome.commandId) == "string",
		"quick action records its command id"
	)
	harness:equal(
		#scenario:snapshot().domains.dm_workspace.quickActions,
		1,
		"quick action is appended once"
	)

	local firstPatch = scenario:execute("dm.runtime_patch", {
		targetId = heroId,
		patch = { visible = false },
	})
	local firstPatchOutcome =
		scenario:expectOutcome(harness, firstPatch, "Slice 11 applies a runtime patch")
	if firstPatchOutcome == nil then
		return
	end
	harness:equal(firstPatchOutcome.revision, 1, "first runtime patch starts at revision one")
	harness:expect(
		firstPatchOutcome.promoted == false,
		"runtime patch is not implicitly promoted to source"
	)

	local secondPatch = scenario:execute("dm.runtime_patch", {
		targetId = heroId,
		patch = { visible = true, lighting = "dim" },
	})
	local secondPatchOutcome =
		scenario:expectOutcome(harness, secondPatch, "Slice 11 replaces the runtime patch")
	if secondPatchOutcome == nil then
		return
	end
	harness:equal(secondPatchOutcome.revision, 2, "replacement runtime patch increments revision")
	harness:expect(
		secondPatchOutcome.patch.visible == true,
		"replacement patch stores current values"
	)

	local deniedPatch = scenario:executeAs("player", 1111, "dm.runtime_patch", {
		targetId = heroId,
		patch = { visible = false },
	})
	harness:expect(not deniedPatch.ok, "player cannot mutate the DM runtime patch")
	if not deniedPatch.ok then
		harness:equal(deniedPatch.error.code, "UNAUTHORIZED", "runtime patch denial is explicit")
	end
	harness:equal(
		scenario:snapshot().domains.dm_workspace.runtimePatches[heroId].revision,
		2,
		"denied runtime patch does not advance revision"
	)

	local recovery = scenario:execute("dm.request_recovery", {
		target = "checkpoint:slice-11",
	})
	local recoveryOutcome =
		scenario:expectOutcome(harness, recovery, "Slice 11 records a recovery request")
	if recoveryOutcome == nil then
		return
	end
	harness:equal(
		recoveryOutcome.status,
		"requested",
		"recovery request starts pending operator review"
	)
	harness:equal(
		recoveryOutcome.target,
		"checkpoint:slice-11",
		"recovery request keeps its target"
	)
	harness:expect(
		string.sub(recoveryOutcome.id, 1, 9) == "recovery:",
		"recovery request has a stable command-derived id"
	)

	local deniedRecovery = scenario:executeAs("player", 1111, "dm.request_recovery", {
		target = "checkpoint:denied",
	})
	harness:expect(not deniedRecovery.ok, "player cannot request operator recovery")
	if not deniedRecovery.ok then
		harness:equal(
			deniedRecovery.error.code,
			"UNAUTHORIZED",
			"recovery request denial is explicit"
		)
	end

	local persisted = scenario:snapshot()
	local restored = ScenarioRuntime.new(1111, "dm")
	local restore = restored:restore(persisted)
	harness:expect(restore.ok, "Slice 11 DM workspace snapshot restores")
	if restore.ok then
		local restoredDomains = restored:snapshot().domains
		harness:equal(
			restoredDomains.dm_workspace.control[heroId],
			2222,
			"restore preserves control assignment"
		)
		harness:equal(
			restoredDomains.dm_workspace.runtimePatches[heroId].revision,
			2,
			"restore preserves runtime patch revision"
		)
		harness:expect(
			restoredDomains.dm_workspace.recoveryRequests[recoveryOutcome.id] ~= nil,
			"restore preserves recovery request"
		)
	end
end
