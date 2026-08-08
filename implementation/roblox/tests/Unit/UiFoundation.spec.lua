--!strict

return function(harness: any)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local StarterPlayer = game:GetService("StarterPlayer")
	local UI = ReplicatedStorage.RVTT.Shared.UI
	local PreferenceSchema = require(UI.PreferenceSchema)
	local ShellContract = require(UI.ShellContract)
	local ThemeContract = require(UI.ThemeContract)
	local ViewState = require(UI.ViewState)
	local Store = require(StarterPlayer.StarterPlayerScripts.RVTT.Client.UiPreferenceStore)

	local defaults = PreferenceSchema.defaults()
	harness:equal(defaults.accentPaletteId, "gold", "accent default comes from reviewed palette")
	harness:equal(defaults.uiScale, 1, "UI scale default is stable")
	harness:equal(defaults.textScale, 1, "text scale default is stable")
	harness:equal(defaults.actionMatrixRows, 2, "action matrix defaults to two rows")
	harness:equal(defaults.motion, "full", "motion defaults to full")

	local validScale, clampedScale = PreferenceSchema.normalize("uiScale", 4)
	harness:expect(validScale, "known numeric preference is normalized")
	harness:equal(clampedScale, 1.4, "UI scale clamps to the documented maximum")
	local validText, clampedText = PreferenceSchema.normalize("textScale", 0.1)
	harness:expect(validText, "text scale is a known preference")
	harness:equal(clampedText, 0.9, "text scale clamps to the documented minimum")
	local validRows, normalizedRows = PreferenceSchema.normalize("actionMatrixRows", 3.8)
	harness:expect(validRows, "action matrix rows are supported")
	harness:equal(normalizedRows, 4, "action matrix rows normalize to an integer")

	local validMotion = PreferenceSchema.normalize("motion", "reduced")
	harness:expect(validMotion, "reviewed motion enum is accepted")
	local invalidMotion, _, invalidMotionError = PreferenceSchema.normalize("motion", "cinematic")
	harness:expect(not invalidMotion, "unknown motion enum is rejected")
	harness:equal(invalidMotionError, "INVALID_PREFERENCE_VALUE", "invalid enum is explicit")
	local unknown, _, unknownError = PreferenceSchema.normalize("minimap", "medium")
	harness:expect(not unknown, "removed minimap preference is not admitted")
	harness:equal(unknownError, "UNKNOWN_PREFERENCE", "unknown preference is explicit")

	local store = Store.new()
	local changed, storedScale = store:set("uiScale", 1.2)
	harness:expect(changed, "local preference store accepts a known key")
	harness:equal(storedScale, 1.2, "local store returns the normalized value")
	harness:equal(store:get("uiScale"), 1.2, "local store exposes current values")
	local rejected = store:set("authorityRole", "dm")
	harness:expect(not rejected, "local store rejects authority-shaped unknown keys")
	local reset, resetScale = store:reset("uiScale")
	harness:expect(reset, "known preference can be reset")
	harness:equal(resetScale, 1, "reset restores the centralized default")

	local bindingInput = { Confirm = "keyboard-e" }
	local bindingAccepted = store:set("bindings", bindingInput)
	harness:expect(bindingAccepted, "binding overrides use the explicit binding API")
	bindingInput.Confirm = "keyboard-enter"
	harness:equal(
		store:get("bindings").Confirm,
		"keyboard-e",
		"binding input is copied instead of becoming hidden shared state"
	)
	store:resetAll()
	harness:equal(store:get("uiScale"), 1, "reset all restores UI scale")
	harness:expect(next(store:get("bindings")) == nil, "reset all clears binding overrides")

	local authorityState: any = {
		revision = 44,
		domains = {
			session = {
				phase = "active",
				memberships = {
					["12"] = { role = "player" },
					["13"] = { role = "admin" },
				},
			},
			encounter = { active = nil },
		},
	}
	local playerContext = ShellContract.resolve(authorityState, 12)
	harness:equal(playerContext.role, "player", "projected player role is retained")
	harness:equal(playerContext.mode, "exploration", "active non-encounter mode is exploration")
	harness:equal(playerContext.surface, "gameplay", "player uses the gameplay surface")
	local unknownContext = ShellContract.resolve(authorityState, 13)
	harness:equal(unknownContext.role, "observer", "unknown role fails closed to observer")
	harness:expect(
		not ShellContract.isSurfaceAllowed(unknownContext.role, "dm"),
		"failed-closed role cannot open a DM surface"
	)
	authorityState.domains.session.memberships["14"] = { role = "dm" }
	authorityState.domains.encounter.active = { status = "active" }
	local dmContext = ShellContract.resolve(authorityState, 14)
	harness:equal(dmContext.mode, "encounter", "encounter mode comes from projection")
	harness:equal(dmContext.surface, "dm", "projected DM receives the DM surface")

	store:set("accentPaletteId", "azure")
	store:set("motion", "minimal")
	local theme = ThemeContract.resolve(store:snapshot())
	harness:equal(theme.accentId, "azure", "theme resolves the local accent")
	harness:equal(theme.motionScale, 0, "minimal motion resolves without animation duration")
	harness:expect(
		ThemeContract.resolve({ accentPaletteId = "gold" }).colors.danger
			== ThemeContract.resolve({ accentPaletteId = "azure" }).colors.danger,
		"semantic danger color is independent from accent"
	)
	harness:equal(
		authorityState.revision,
		44,
		"theme and preferences do not mutate authority revision"
	)
	harness:equal(
		authorityState.domains.session.memberships["12"].role,
		"player",
		"mode mapping does not mutate projected authority"
	)

	local stateNames = {
		"loading",
		"empty",
		"ready",
		"pending",
		"partial",
		"stale",
		"permission_denied",
		"network_error",
		"validation_error",
		"conflict",
		"recovery",
	}
	for _, stateName in stateNames do
		harness:expect(ViewState.isValid(stateName), stateName .. " is a shared view state")
	end
	harness:expect(not ViewState.isValid("spinner_only"), "spinner-only is not a view state")
	store:destroy()
end
