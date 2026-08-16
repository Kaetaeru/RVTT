--!strict

return function(harness: any)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local UI = ReplicatedStorage.RVTT.Shared.UI
	local Registry = require(UI.DmToolRegistry)
	local Host = require(UI.DmWindowHost)
	local ViewModel = require(UI.DmWorkspaceViewModel)

	local registry = Registry.new()
	registry:register({
		moduleId = "players",
		title = "Players",
		instancePolicy = "singleton",
		commandBindings = { "dm.assign_control" },
	})
	registry:register({
		moduleId = "inspector",
		title = "Inspector",
		instancePolicy = "multiple",
		commandBindings = {},
	})
	registry:register({
		moduleId = "journal",
		title = "Journal",
		instancePolicy = "per_document",
		commandBindings = {},
	})
	registry:register({
		moduleId = "quick",
		title = "Quick",
		instancePolicy = "context_popover",
		commandBindings = { "dm.quick_action" },
	})

	local host = Host.new(registry)
	local domainState = { revision = 7, sensitive = "authority" }
	local players, created = host:open("players")
	harness:expect(created and players ~= nil, "singleton DM window opens")
	local samePlayers, duplicateCreated = host:open("players")
	harness:expect(
		not duplicateCreated and samePlayers == players,
		"singleton open focuses the existing instance"
	)
	local inspectorA = host:open("inspector", "actor:a")
	local inspectorB = host:open("inspector", "actor:b")
	local journal = host:open("journal", "document:one")
	harness:equal(#host.zOrder, 4, "three or more independent DM windows can coexist")
	harness:expect(inspectorA ~= inspectorB, "multiple instance tool creates independent windows")
	harness:expect(journal ~= nil, "per-document window opens with context")
	harness:expect(host:move(inspectorA.instanceId, 77, 88), "window moves locally")
	harness:expect(host:resize(inspectorB.instanceId, 420, 310), "window resizes locally")
	harness:expect(host:dock(players.instanceId, "left"), "window docks locally")
	harness:expect(host:minimize(journal.instanceId), "window minimizes")
	harness:expect(host:restore(journal.instanceId), "window restores")
	harness:equal(domainState.revision, 7, "window layout never mutates domain authority")
	harness:equal(domainState.sensitive, "authority", "local layout cannot overwrite domain data")
	harness:expect(host:close(inspectorA.instanceId), "one window disposes independently")
	harness:expect(
		host.windowsByInstanceId[inspectorB.instanceId] ~= nil,
		"closing one window preserves another"
	)
	harness:expect(
		host.windowsByInstanceId[players.instanceId] ~= nil,
		"closing multiple instance preserves singleton"
	)
	local serialized = host:serializeLayout()
	harness:equal(
		serialized.windowsByInstanceId[players.instanceId].localViewState,
		nil,
		"serialized layout excludes tool-local and projected sensitive state"
	)
	local restoredHost = Host.new(registry)
	harness:expect(restoredHost:restoreLayout(serialized), "validated local window layout restores")
	harness:equal(
		#restoredHost.zOrder,
		#host.zOrder,
		"layout restore preserves independent windows"
	)
	local popover = host:open("quick")
	harness:equal(popover, nil, "context popover does not become a full window")

	local payload: any = {
		domains = {
			session = {
				memberships = {
					["1"] = { role = "dm" },
					["22"] = { role = "player" },
					["23"] = { role = "observer" },
				},
			},
			dm_workspace = {
				control = {},
				quickActions = { { actionId = "b", commandId = "command:b", createdAt = 20 } },
				runtimePatches = {
					actor = { commandId = "command:a", createdAt = 10, revision = 2 },
				},
				recoveryRequests = {
					["recovery:command:c"] = {
						id = "recovery:command:c",
						createdAt = 30,
						status = "requested",
					},
				},
			},
		},
	}
	local view = ViewModel.build(payload, 1, 9, {
		["command:a"] = {
			commandType = "dm.runtime_patch",
			createdAt = 10,
			baseRevision = 8,
			accepted = true,
		},
		["command:d"] = {
			commandType = "dm.request_recovery",
			createdAt = 40,
			baseRevision = 9,
			accepted = true,
		},
	})
	harness:expect(
		view.visible and #view.viewers == 2,
		"DM view lists only previewable player and observer targets"
	)
	harness:equal(
		#view.queue,
		4,
		"queue deduplicates a projected command and retains awaiting command"
	)
	harness:equal(view.queue[1].id, "patch:actor", "queue order is deterministic by real timestamp")
	harness:equal(
		view.queue[4].status,
		"accepted_awaiting_projection",
		"accepted receipt stays distinct from projected confirmation"
	)

	local recoveryView = ViewModel.build(payload, 1, 10, {
		["command:c"] = {
			commandType = "dm.request_recovery",
			createdAt = 30,
			baseRevision = 9,
			accepted = true,
		},
	})
	harness:equal(#recoveryView.queue, 3, "recovery stable id removes the local duplicate")
	harness:equal(
		recoveryView.queue[3].commandId,
		"command:c",
		"recovery stable id derives the original command identity"
	)

	local controlPending = {
		["command:control"] = {
			commandType = "dm.assign_control",
			createdAt = 40,
			baseRevision = 10,
			accepted = true,
			expectedActorId = "actor",
			expectedControllerUserId = 22,
		},
	}
	local awaitingControl = ViewModel.build(payload, 1, 10, controlPending)
	harness:equal(
		awaitingControl.queue[4].status,
		"accepted_awaiting_projection",
		"control success receipt alone does not confirm authority"
	)
	payload.domains.dm_workspace.control.actor = 22
	local preexistingControl = ViewModel.build(payload, 1, 10, controlPending)
	harness:equal(
		preexistingControl.queue[4].status,
		"accepted_awaiting_projection",
		"matching control at the base revision does not confirm the command"
	)
	payload.domains.dm_workspace.control.actor = 23
	local conflictingControl = ViewModel.build(payload, 1, 11, controlPending)
	harness:equal(
		conflictingControl.queue[4].status,
		"accepted_awaiting_projection",
		"newer projection with a different controller is not confirmed"
	)
	payload.domains.dm_workspace.control.actor = 22
	local confirmedControl = ViewModel.build(payload, 1, 12, controlPending)
	harness:equal(
		confirmedControl.queue[4].status,
		"projection_confirmed",
		"newer matching authoritative control projection confirms the command"
	)

	local failures = {}
	for index = 1, ViewModel.MaxTerminalFeedback + 2 do
		failures["failure:" .. tostring(index)] = {
			commandType = "dm.runtime_patch",
			createdAt = index,
			terminalFailure = true,
			failureCode = if index == ViewModel.MaxTerminalFeedback + 2
				then "PRIVATE_SERVER_DETAIL"
				else "STALE_REVISION",
		}
	end
	ViewModel.pruneTerminalFeedback(failures)
	local failureView = ViewModel.build(payload, 1, 12, failures)
	harness:equal(
		#failureView.queue,
		ViewModel.MaxTerminalFeedback + 3,
		"terminal feedback is retained with a bounded local history"
	)
	local redactedFailure: any = nil
	for _, row in failureView.queue do
		if row.commandId == "failure:" .. tostring(ViewModel.MaxTerminalFeedback + 2) then
			redactedFailure = row
		end
	end
	harness:equal(
		redactedFailure.reason,
		"COMMAND_FAILED",
		"unknown terminal details are replaced with a viewer-safe code"
	)
	payload.domains.session.memberships["1"].role = "player"
	local hidden = ViewModel.build(payload, 1, 9, {})
	harness:expect(
		not hidden.visible and hidden.workspace == nil,
		"role loss exposes no DM workspace or placeholder data"
	)

	for _, commandType in
		{ "dm.assign_control", "dm.quick_action", "dm.runtime_patch", "dm.request_recovery" }
	do
		local sample = if commandType == "dm.assign_control"
			then { actorId = "a", controllerUserId = 22 }
			elseif commandType == "dm.quick_action" then { actionId = "action" }
			elseif commandType == "dm.runtime_patch" then { targetId = "a", patch = {} }
			else { target = "checkpoint" }
		local intent = ViewModel.intent(commandType, sample)
		harness:equal(intent.commandType, commandType, "existing DM command binding is preserved")
	end
	local invented = ViewModel.intent("dm.invented_command", {})
	harness:equal(invented, nil, "workspace rejects invented authority commands")
	host:destroy()
	restoredHost:destroy()
end
