--!strict

return function(harness: any)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local StarterPlayer = game:GetService("StarterPlayer")
	local UI = ReplicatedStorage.RVTT.Shared.UI
	local Signal = require(ReplicatedStorage.RVTT.Shared.Core.Signal)
	local ViewModel = require(UI.EntryRecoveryViewModel)
	local ShellContract = require(UI.ShellContract)
	local ViewState = require(UI.ViewState)
	local UIRecoveryCoordinator =
		require(StarterPlayer.StarterPlayerScripts.RVTT.Client.UIRecoveryCoordinator)
	local Store = require(StarterPlayer.StarterPlayerScripts.RVTT.Client.UiPreferenceStore)

	local initialReplica: any = {
		revision = -1,
		Changed = Signal.new(),
		RebuildStarted = Signal.new(),
		RebuildFinished = Signal.new(),
		RebuildFailed = Signal.new(),
	}
	local fullSyncRequests = 0
	local recovery = UIRecoveryCoordinator.new(initialReplica, function()
		fullSyncRequests += 1
	end)
	harness:equal(
		recovery:snapshot().state,
		ViewState.LOADING,
		"an invalid initial Replica starts in loading"
	)
	initialReplica.revision = 0
	initialReplica.Changed:Fire()
	task.wait()
	harness:equal(
		recovery:snapshot().state,
		ViewState.READY,
		"a normal first Projection releases initial loading"
	)

	local protectedStates = {
		ViewState.REBUILDING,
		ViewState.RECOVERY,
		ViewState.NETWORK_ERROR,
		ViewState.STALE,
		ViewState.CONFLICT,
		ViewState.FATAL,
	}
	for _, protectedState in protectedStates do
		recovery:_set(protectedState, "protected", protectedState == ViewState.NETWORK_ERROR)
		initialReplica.Changed:Fire()
		task.wait()
		harness:equal(
			recovery:snapshot().state,
			protectedState,
			"Replica changes do not clear explicit " .. protectedState .. " state"
		)
	end
	harness:equal(
		fullSyncRequests,
		0,
		"normal initial Projection does not request a forged full sync"
	)
	recovery:destroy()

	local observer = ViewModel.build({ domains = {} }, 22, nil, false)
	harness:equal(observer.role, "observer", "missing membership enters observer-first")
	harness:expect(not observer.canReady, "observer cannot fabricate ready authority")
	harness:expect(not observer.canEnterGameplay, "observer cannot optimistically enter gameplay")

	local payload: any = {
		domains = {
			session = {
				phase = "lobby",
				memberships = { ["22"] = { role = "player" } },
				selectedCharacter = { ["22"] = "character:hero" },
				ready = { ["22"] = false },
				connections = { ["22"] = "connected" },
			},
			scene = {
				actors = {
					["actor:hero"] = {
						id = "actor:hero",
						ownerUserId = 22,
						controllerUserId = 22,
					},
				},
			},
		},
	}
	local player = ViewModel.build(payload, 22, nil, true)
	harness:equal(player.role, "player", "authoritative projection changes the role")
	harness:equal(player.state, "pending", "pending remains presentation-only")
	harness:expect(not player.canReady, "pending state does not unlock another command")
	harness:equal(
		ShellContract.resolve(payload, 22).surface,
		"session",
		"lobby projection keeps the player on the entry surface"
	)
	harness:equal(
		ViewModel.validSelection(payload, 22, "actor:hero"),
		"actor:hero",
		"visible controlled semantic selection can be restored"
	)

	payload.domains.session.memberships["22"].role = "observer"
	payload.domains.session.selectedCharacter["22"] = nil
	payload.domains.scene.actors["actor:hero"].controllerUserId = nil
	payload.domains.scene.actors["actor:hero"].ownerUserId = 1
	harness:equal(
		ViewModel.validSelection(payload, 22, "actor:hero"),
		nil,
		"role revocation clears a no-longer-valid authority selection"
	)
	harness:expect(
		not ShellContract.isSurfaceAllowed("observer", "management"),
		"role revocation removes management capability"
	)

	local permission = ViewModel.safeError("UNAUTHORIZED")
	harness:equal(permission.state, "permission_denied", "permission has a distinct safe state")
	harness:expect(
		string.find(permission.message, "character:hero", 1, true) == nil,
		"viewer-safe errors do not echo hidden identifiers"
	)
	local network = ViewModel.safeError("CLIENT_TIMEOUT")
	harness:equal(network.state, "network_error", "network failure has a distinct state")
	harness:expect(network.retryable, "network recovery may request a safe full sync")

	local preferences = Store.new()
	preferences:set("uiScale", 1.2)
	ViewModel.build(payload, 22, { state = "rebuilding" }, false)
	harness:equal(preferences:get("uiScale"), 1.2, "projection rebuild preserves local preferences")
	preferences:destroy()
end
