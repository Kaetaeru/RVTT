--!strict

return function(harness: any)
	local UI = game:GetService("ReplicatedStorage").RVTT.Shared.UI
	local ViewModel = require(UI.GameplayHudViewModel)

	local payload: any = {
		domains = {
			session = {
				phase = "active",
				memberships = { ["101"] = { role = "player" } },
			},
			scene = {
				actors = {
					hero = {
						id = "hero",
						controllerUserId = 101,
						sourceCharacterId = "hero-character",
						position = { x = 0, y = 0, z = 0 },
					},
					enemy = {
						id = "enemy",
						controllerUserId = 202,
						position = { x = 8, y = 0, z = 0 },
					},
				},
			},
			character = {
				characters = {
					["hero-character"] = { name = "테스트 영웅" },
				},
			},
			rules = {
				actorStates = {
					hero = { currentHitPoints = 9, maximumHitPoints = 12 },
				},
			},
			encounter = {
				active = {
					id = "encounter:test",
					status = "active",
					round = 2,
					activeActorId = "hero",
					timeline = {
						{ actorId = "hero", initiative = 18 },
						{ actorId = "enemy", initiative = 12 },
					},
					opportunities = {
						action = true,
						bonusAction = false,
						reaction = true,
					},
					movementRemaining = 3,
				},
			},
		},
	}
	local feedback = ViewModel.initialFeedback(42)
	local state = ViewModel.build(payload, 101, "hero", 42, nil, feedback)
	harness:equal(state.mode, "encounter", "active encounter composes encounter HUD mode")
	harness:equal(state.selectedActorId, "hero", "HUD uses the shared semantic actor selection")
	harness:equal(
		state.selectedActorLabel,
		"테스트 영웅",
		"selected actor uses projected name"
	)
	harness:equal(state.hitPoints, 9, "HUD reads projected current hit points")
	harness:equal(state.maximumHitPoints, 12, "HUD reads projected maximum hit points")
	harness:equal(#state.timeline, 2, "initiative uses only projected timeline entries")
	harness:equal(state.activeActorId, "hero", "active turn uses projected active actor")
	harness:equal(#state.resources, 4, "resource rail omits no projected turn resources")
	harness:expect(state.canEndTurn, "projected active controller receives End Turn entry")
	harness:expect(state.reactionVisible, "projected reaction opportunity is presented")
	harness:expect(state.reactionAvailable, "available reaction is distinguished")
	harness:equal(
		payload.domains.encounter.active.round,
		2,
		"HUD composition does not mutate authority"
	)

	local rawMovementPreview = {
		actorId = "hero",
		target = { kind = "surface", position = Vector3.new(5, 0, 0) },
		action = {
			kind = "move",
			label = "이동",
			enabled = false,
			disabledReason = "남은 이동 거리가 부족합니다",
			projectionRevision = 42,
		},
	}
	local movementPreview = ViewModel.preview(payload, "hero", rawMovementPreview, 42)
	harness:expect(movementPreview ~= nil, "projected movement intent creates a preview")
	if movementPreview ~= nil then
		harness:equal(
			movementPreview.distance,
			5,
			"preview derives distance from projected position"
		)
		harness:equal(movementPreview.remaining, 3, "preview uses projected remaining movement")
		harness:equal(movementPreview.excess, 2, "preview distinguishes the excess segment")
		harness:equal(#movementPreview.riskLabels, 0, "preview invents no unprojected risks")
		harness:expect(not movementPreview.enabled, "projected unavailable movement stays disabled")
	end
	local stalePreview = ViewModel.preview(payload, "hero", rawMovementPreview, 43)
	harness:expect(
		stalePreview ~= nil and stalePreview.state == "stale",
		"revision mismatch marks preview stale"
	)
	harness:expect(stalePreview ~= nil and not stalePreview.enabled, "stale preview cannot confirm")
	local hiddenTargetPreview = ViewModel.preview(payload, "hero", {
		actorId = "hero",
		target = { kind = "actor", actorId = "hidden-enemy" },
		action = {
			kind = "attack",
			label = "공격",
			enabled = true,
			projectionRevision = 42,
		},
	}, 42)
	harness:equal(hiddenTargetPreview, nil, "unprojected target is absent from attack preview")

	local pending = ViewModel.pendingFeedback("move", "command:move", 42)
	harness:equal(pending.state, "pending", "submitted action is not shown as success")
	local accepted = ViewModel.resolveFeedback(pending, true, nil, 43)
	harness:equal(accepted.state, "partial", "receipt approval waits for projection reconciliation")
	harness:equal(
		ViewModel.reconcileFeedback(accepted, 42).state,
		"partial",
		"older projection cannot reconcile an accepted action"
	)
	harness:equal(
		ViewModel.reconcileFeedback(accepted, 43).state,
		"ready",
		"matching authority revision completes reconciliation"
	)
	harness:equal(
		ViewModel.resolveFeedback(pending, false, "STALE_REVISION", nil).state,
		"stale",
		"stale denial is distinct"
	)
	harness:equal(
		ViewModel.resolveFeedback(pending, false, "UNAUTHORIZED", nil).state,
		"permission_denied",
		"permission absence is distinct from availability"
	)
	harness:equal(
		ViewModel.resolveFeedback(pending, false, "CONFLICT", nil).state,
		"conflict",
		"authority conflict is distinct"
	)
	harness:equal(
		ViewModel.resolveFeedback(pending, false, "OPPORTUNITY_EXPIRED", nil).state,
		"expired",
		"an expired reaction opportunity is distinct"
	)
	local acceptedWithoutRevision = ViewModel.resolveFeedback(pending, true, nil, nil)
	harness:equal(
		ViewModel.reconcileFeedback(acceptedWithoutRevision, 43).state,
		"ready",
		"a later authority projection reconciles a receipt without an explicit revision"
	)

	local opportunities = payload.domains.encounter.active.opportunities
	payload.domains.encounter.active.opportunities = nil
	local redacted = ViewModel.build(payload, 101, "hero", 42, nil, feedback)
	harness:equal(#redacted.resources, 0, "unprojected resources create no placeholders")
	harness:expect(not redacted.reactionVisible, "reaction is absent without projected opportunity")
	harness:expect(redacted.canEndTurn, "turn control remains based on projected actor control")
	payload.domains.encounter.active.opportunities = opportunities
	payload.domains.encounter.active = nil
	local exploration = ViewModel.build(payload, 101, "hero", 44, nil, feedback)
	harness:equal(exploration.mode, "exploration", "inactive encounter composes exploration HUD")
	harness:equal(
		exploration.selectedActorId,
		"hero",
		"mode transition preserves semantic selection"
	)
	harness:equal(#exploration.timeline, 0, "exploration creates no initiative placeholders")
end
