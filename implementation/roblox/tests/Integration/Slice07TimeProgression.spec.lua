--!strict

return function(harness)
	local ScenarioRuntime = require(script.Parent.ScenarioRuntime)
	local scenario = ScenarioRuntime.new(707, "dm")
	local heroId = scenario:bootstrapCharacter(harness, "Slice 07 Hero", "scene:slice-07", nil)
	if heroId == nil then
		return
	end

	local deniedSchedule = scenario:executeAs("player", 707, "time.schedule", {
		scheduleId = "schedule:denied",
		afterSeconds = 60,
	})
	harness:expect(not deniedSchedule.ok, "player cannot author the campaign schedule")
	if not deniedSchedule.ok then
		harness:equal(deniedSchedule.error.code, "UNAUTHORIZED", "schedule denial is explicit")
	end

	local schedule = scenario:execute("time.schedule", {
		scheduleId = "schedule:slice-07",
		afterSeconds = 3600,
		payload = { event = "event:test" },
	})
	local scheduleOutcome = scenario:expectOutcome(harness, schedule, "Slice 07 creates a campaign schedule")
	if scheduleOutcome == nil then
		return
	end
	harness:equal(scheduleOutcome.dueAt, 3600, "schedule due time is based on campaign time")
	harness:equal(scheduleOutcome.status, "scheduled", "new schedule starts scheduled")

	local duplicateSchedule = scenario:execute("time.schedule", {
		scheduleId = "schedule:slice-07",
		afterSeconds = 10,
	})
	harness:expect(not duplicateSchedule.ok, "duplicate schedule identity is rejected")
	if not duplicateSchedule.ok then
		harness:equal(duplicateSchedule.error.code, "CONFLICT", "duplicate schedule returns conflict")
	end

	local deniedAdvance = scenario:executeAs("player", 707, "time.advance", { seconds = 1800 })
	harness:expect(not deniedAdvance.ok, "player cannot advance campaign time")
	if not deniedAdvance.ok then
		harness:equal(deniedAdvance.error.code, "UNAUTHORIZED", "time advance denial is explicit")
	end

	local firstAdvance = scenario:execute("time.advance", { seconds = 1800 })
	local firstAdvanceOutcome = scenario:expectOutcome(harness, firstAdvance, "Slice 07 advances campaign time before due")
	if firstAdvanceOutcome == nil then
		return
	end
	harness:equal(firstAdvanceOutcome.campaignSeconds, 1800, "campaign time advances by the requested duration")
	harness:equal(#firstAdvanceOutcome.due, 0, "schedule is not due before its deadline")

	local invalidActivity = scenario:executeAs("player", 707, "time.start_activity", {
		activityId = "activity:invalid",
		kind = "unsupported",
		characterId = heroId,
	})
	harness:expect(not invalidActivity.ok, "unsupported activity kind is rejected")
	if not invalidActivity.ok then
		harness:equal(invalidActivity.error.code, "VALIDATION_FAILED", "invalid activity uses validation error")
	end

	local activity = scenario:executeAs("player", 707, "time.start_activity", {
		activityId = "activity:slice-07",
		kind = "training",
		characterId = heroId,
	})
	local activityOutcome = scenario:expectOutcome(harness, activity, "Slice 07 starts an owned activity")
	if activityOutcome == nil then
		return
	end
	harness:equal(activityOutcome.status, "started", "new activity starts active")
	harness:equal(activityOutcome.startedAt, 1800, "activity records authoritative campaign time")
	harness:equal(activityOutcome.ownerUserId, 707, "activity records the authoritative owner")

	local duplicateActivity = scenario:executeAs("player", 707, "time.start_activity", {
		activityId = "activity:slice-07",
		kind = "rest",
		characterId = heroId,
	})
	harness:expect(not duplicateActivity.ok, "duplicate activity identity is rejected")
	if not duplicateActivity.ok then
		harness:equal(duplicateActivity.error.code, "CONFLICT", "duplicate activity returns conflict")
	end

	local secondAdvance = scenario:execute("time.advance", { seconds = 1800 })
	local secondAdvanceOutcome = scenario:expectOutcome(harness, secondAdvance, "Slice 07 advances campaign time to the deadline")
	if secondAdvanceOutcome == nil then
		return
	end
	harness:equal(secondAdvanceOutcome.campaignSeconds, 3600, "campaign time reaches the deadline")
	harness:equal(#secondAdvanceOutcome.due, 1, "due schedule is emitted once")
	harness:equal(secondAdvanceOutcome.due[1], "schedule:slice-07", "the expected schedule becomes due")
	harness:equal(
		scenario:snapshot().domains.time.schedules["schedule:slice-07"].status,
		"due",
		"schedule state commits as due"
	)

	local deniedResolve = scenario:executeAs("player", 999, "time.resolve_activity", {
		activityId = "activity:slice-07",
		status = "completed",
	})
	harness:expect(not deniedResolve.ok, "unrelated player cannot resolve another user's activity")
	if not deniedResolve.ok then
		harness:equal(deniedResolve.error.code, "UNAUTHORIZED", "activity ownership denial is explicit")
	end

	local resolve = scenario:executeAs("player", 707, "time.resolve_activity", {
		activityId = "activity:slice-07",
		status = "completed",
	})
	local resolveOutcome = scenario:expectOutcome(harness, resolve, "Slice 07 completes the owned activity")
	if resolveOutcome == nil then
		return
	end
	harness:equal(resolveOutcome.status, "completed", "activity commits its terminal status")
	harness:equal(resolveOutcome.resolvedAt, 3600, "activity completion records campaign time")

	local repeatedAdvance = scenario:execute("time.advance", { seconds = 0 })
	local repeatedAdvanceOutcome = scenario:expectOutcome(harness, repeatedAdvance, "Slice 07 re-evaluates due schedules safely")
	if repeatedAdvanceOutcome == nil then
		return
	end
	harness:equal(#repeatedAdvanceOutcome.due, 0, "already due schedule is not emitted twice")

	local persisted = scenario:snapshot()
	local restored = ScenarioRuntime.new(707, "dm")
	local restore = restored:restore(persisted)
	harness:expect(restore.ok, "Slice 07 snapshot restores")
	if restore.ok then
		local restoredTime = restored:snapshot().domains.time
		harness:equal(restoredTime.campaignSeconds, 3600, "restore preserves campaign time")
		harness:equal(restoredTime.schedules["schedule:slice-07"].status, "due", "restore preserves schedule state")
		harness:equal(restoredTime.activities["activity:slice-07"].status, "completed", "restore preserves activity state")
	end
end
