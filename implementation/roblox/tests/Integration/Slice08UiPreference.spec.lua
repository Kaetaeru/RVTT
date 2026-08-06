--!strict

return function(harness)
	local ScenarioRuntime = require(script.Parent.ScenarioRuntime)
	local scenario = ScenarioRuntime.new(808, "player")

	local scale = scenario:execute("ui.set_preference", {
		key = "uiScale",
		value = 1.4,
	})
	local scaleOutcome = scenario:expectOutcome(harness, scale, "Slice 08 stores a valid UI scale")
	if scaleOutcome == nil then
		return
	end
	harness:equal(scaleOutcome.uiScale, 1.4, "UI scale uses the requested supported value")

	local motion = scenario:execute("ui.set_preference", {
		key = "reducedMotion",
		value = true,
	})
	local motionOutcome = scenario:expectOutcome(harness, motion, "Slice 08 stores reduced motion")
	if motionOutcome == nil then
		return
	end
	harness:expect(motionOutcome.reducedMotion == true, "reduced motion remains enabled")
	harness:equal(motionOutcome.uiScale, 1.4, "preference updates preserve existing values")

	local accent = scenario:execute("ui.set_preference", {
		key = "accentPaletteId",
		value = "teal",
	})
	local accentOutcome = scenario:expectOutcome(harness, accent, "Slice 08 stores an approved accent palette")
	if accentOutcome == nil then
		return
	end
	harness:equal(accentOutcome.accentPaletteId, "teal", "approved accent palette is retained")

	local invalidScale = scenario:execute("ui.set_preference", {
		key = "uiScale",
		value = 2,
	})
	harness:expect(not invalidScale.ok, "unsupported UI scale is rejected")
	if not invalidScale.ok then
		harness:equal(invalidScale.error.code, "VALIDATION_FAILED", "invalid UI scale uses validation error")
	end

	local invalidAccent = scenario:execute("ui.set_preference", {
		key = "accentPaletteId",
		value = "neon-rainbow",
	})
	harness:expect(not invalidAccent.ok, "unapproved accent palette is rejected")
	if not invalidAccent.ok then
		harness:equal(invalidAccent.error.code, "VALIDATION_FAILED", "invalid accent uses validation error")
	end

	local otherUser = scenario:executeAs("player", 809, "ui.set_preference", {
		key = "accentPaletteId",
		value = "silver",
	})
	local otherUserOutcome = scenario:expectOutcome(harness, otherUser, "Slice 08 stores another user's preference separately")
	if otherUserOutcome == nil then
		return
	end
	harness:equal(otherUserOutcome.accentPaletteId, "silver", "other user receives the requested palette")
	local preferences = scenario:snapshot().domains.ui_preferences.byUser
	harness:equal(preferences["808"].accentPaletteId, "teal", "first user's accent is isolated")
	harness:equal(preferences["809"].accentPaletteId, "silver", "second user's accent is isolated")

	local unknownPreference = scenario:execute("ui.set_preference", {
		key = "rawThemeHex",
		value = "#ffffff",
	})
	harness:expect(not unknownPreference.ok, "unknown UI preference key is rejected")
	if not unknownPreference.ok then
		harness:equal(unknownPreference.error.code, "VALIDATION_FAILED", "unknown preference uses validation error")
	end

	local persisted = scenario:snapshot()
	local restored = ScenarioRuntime.new(808, "player")
	local restore = restored:restore(persisted)
	harness:expect(restore.ok, "Slice 08 preference snapshot restores")
	if restore.ok then
		local restoredPreferences = restored:snapshot().domains.ui_preferences.byUser
		harness:equal(restoredPreferences["808"].uiScale, 1.4, "restore preserves UI scale")
		harness:expect(restoredPreferences["808"].reducedMotion == true, "restore preserves reduced motion")
		harness:equal(restoredPreferences["808"].accentPaletteId, "teal", "restore preserves accent palette")
	end
end
