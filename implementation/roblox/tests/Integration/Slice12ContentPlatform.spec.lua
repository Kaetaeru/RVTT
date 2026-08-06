--!strict

return function(harness)
	local ScenarioRuntime = require(script.Parent.ScenarioRuntime)
	local scenario = ScenarioRuntime.new(1212, "dm")

	local deniedRegister = scenario:executeAs("player", 1212, "content.register_pack", {
		manifest = {
			packId = "pack:denied",
			version = "1.0.0",
			rightsStatus = "original",
		},
	})
	harness:expect(not deniedRegister.ok, "player cannot register a content pack")
	if not deniedRegister.ok then
		harness:equal(deniedRegister.error.code, "UNAUTHORIZED", "content registration denial is explicit")
	end

	local basePack = scenario:execute("content.register_pack", {
		manifest = {
			packId = "pack:base",
			version = "1.0.0",
			rightsStatus = "approved",
			dependencies = {},
		},
	})
	local basePackOutcome = scenario:expectOutcome(harness, basePack, "Slice 12 registers an approved base pack")
	if basePackOutcome == nil then
		return
	end
	harness:equal(basePackOutcome.packId, "pack:base", "base pack keeps its stable identity")
	harness:equal(basePackOutcome.version, "1.0.0", "base pack keeps its version")

	local dependentPack = scenario:execute("content.register_pack", {
		manifest = {
			packId = "pack:dependent",
			version = "2.0.0",
			rightsStatus = "original",
			dependencies = { "pack:base" },
		},
	})
	if scenario:expectOutcome(harness, dependentPack, "Slice 12 registers a dependent original pack") == nil then
		return
	end

	local blockedPack = scenario:execute("content.register_pack", {
		manifest = {
			packId = "pack:blocked",
			version = "1.0.0",
			rightsStatus = "blocked",
			dependencies = {},
		},
	})
	if scenario:expectOutcome(harness, blockedPack, "Slice 12 records a rights-blocked pack without activating it") == nil then
		return
	end

	local duplicatePack = scenario:execute("content.register_pack", {
		manifest = {
			packId = "pack:base",
			version = "9.9.9",
			rightsStatus = "approved",
		},
	})
	harness:expect(not duplicatePack.ok, "duplicate pack identity is rejected")
	if not duplicatePack.ok then
		harness:equal(duplicatePack.error.code, "CONFLICT", "duplicate pack returns conflict")
	end

	local missingDependency = scenario:execute("content.activate_pack", {
		packId = "pack:dependent",
	})
	harness:expect(not missingDependency.ok, "dependent pack cannot activate before its dependency")
	if not missingDependency.ok then
		harness:equal(missingDependency.error.code, "CONFLICT", "inactive dependency returns conflict")
	end

	local activateBase = scenario:execute("content.activate_pack", {
		packId = "pack:base",
	})
	local activateBaseOutcome = scenario:expectOutcome(harness, activateBase, "Slice 12 activates the base pack")
	if activateBaseOutcome == nil then
		return
	end
	harness:equal(activateBaseOutcome.version, "1.0.0", "activation freezes the base pack version")

	local activateDependent = scenario:execute("content.activate_pack", {
		packId = "pack:dependent",
	})
	local activateDependentOutcome = scenario:expectOutcome(harness, activateDependent, "Slice 12 activates the dependency-complete pack")
	if activateDependentOutcome == nil then
		return
	end
	harness:equal(activateDependentOutcome.version, "2.0.0", "dependent pack activation freezes its version")

	local blockedActivation = scenario:execute("content.activate_pack", {
		packId = "pack:blocked",
	})
	harness:expect(not blockedActivation.ok, "rights-blocked pack cannot activate")
	if not blockedActivation.ok then
		harness:equal(blockedActivation.error.code, "CONFLICT", "rights blocker returns conflict")
	end
	harness:expect(
		scenario:snapshot().domains.content.active["pack:blocked"] == nil,
		"rights-blocked pack never enters the active snapshot"
	)

	local localization = scenario:execute("content.localization", {
		locale = "ko-KR",
		entries = {
			["ui.action.confirm"] = "확인",
			["ui.action.cancel"] = "취소",
		},
	})
	local localizationOutcome = scenario:expectOutcome(harness, localization, "Slice 12 registers localization entries")
	if localizationOutcome == nil then
		return
	end
	harness:equal(localizationOutcome.locale, "ko-KR", "localization keeps its locale identity")
	harness:equal(localizationOutcome.count, 2, "localization reports the compiled entry count")

	local deniedLocalization = scenario:executeAs("player", 1212, "content.localization", {
		locale = "en-US",
		entries = { ["ui.action.confirm"] = "Confirm" },
	})
	harness:expect(not deniedLocalization.ok, "player cannot replace localization authority data")
	if not deniedLocalization.ok then
		harness:equal(deniedLocalization.error.code, "UNAUTHORIZED", "localization denial is explicit")
	end

	local persisted = scenario:snapshot()
	local restored = ScenarioRuntime.new(1212, "dm")
	local restore = restored:restore(persisted)
	harness:expect(restore.ok, "Slice 12 content snapshot restores")
	if restore.ok then
		local restoredContent = restored:snapshot().domains.content
		harness:equal(restoredContent.active["pack:base"], "1.0.0", "restore preserves base pack version")
		harness:equal(restoredContent.active["pack:dependent"], "2.0.0", "restore preserves dependent pack version")
		harness:equal(restoredContent.localization["ko-KR"]["ui.action.confirm"], "확인", "restore preserves localization entries")
	end
end
