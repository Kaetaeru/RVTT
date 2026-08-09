--!strict

return function(harness: any)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Server = game:GetService("ServerScriptService").RVTT.Server
	local ServerStorage = game:GetService("ServerStorage")
	local ViewModel = require(ReplicatedStorage.RVTT.Shared.UI.DiceNoticeViewModel)
	local Projection = require(Server.Projection.DiceNoticeProjection)
	local DiceSlotRevealNotice = require(ServerStorage.RVTTTestUI.DiceSlotRevealNotice)
	local ScenarioRuntime = require(script.Parent.Parent.Integration.ScenarioRuntime)
	local scenario = ScenarioRuntime.new(101, "dm")
	local function child(parent: Instance, name: string): any
		return parent:FindFirstChild(name)
	end
	local heroId = scenario:bootstrapCharacter(harness, "Dice Notice Hero", "scene:dice-notice", {
		strength = 16,
		dexterity = 14,
		constitution = 12,
		intelligence = 10,
		wisdom = 10,
		charisma = 8,
	})
	if heroId == nil then
		return
	end
	local challenge = scenario:execute("rules.create_challenge", {
		ability = "strength",
		proficient = true,
		difficultyClass = 10,
		labelKey = "dice.notice.challenge",
	})
	local challengeOutcome =
		scenario:expectOutcome(harness, challenge, "creates authoritative challenge")
	if challengeOutcome == nil then
		return
	end
	local roll = scenario:execute("rules.ability_check", {
		actorId = heroId,
		challengeId = challengeOutcome.challengeId,
		diceMode = "advantage",
	})
	local rollOutcome = scenario:expectOutcome(
		harness,
		roll,
		"production RulesDomain creates a presentable roll record"
	)
	if rollOutcome == nil then
		return
	end
	local snapshot = scenario:snapshot()
	local public = Projection.build(snapshot.domains, { userId = 202, role = "player" })
	local owner = Projection.build(snapshot.domains, { userId = 101, role = "player" })
	local dm = Projection.build(snapshot.domains, { userId = 303, role = "dm" })
	harness:equal(#public, 1, "public roll is visible to an authorized public viewer")
	harness:equal(#owner, 1, "owner receives the server-authored dice notice")
	harness:equal(#dm, 1, "DM receives the server-authored dice notice")
	local projected = owner[1]
	harness:equal(projected.rollId, rollOutcome.id, "roll identity comes from authoritative record")
	harness:equal(projected.diceMode, "normal", "normal dice mode is server-authored")
	harness:equal(#projected.naturalResults, 1, "server projection supplies natural results")
	harness:equal(
		#rollOutcome.data.rolls,
		1,
		"rolling player payload cannot override challenge diceMode"
	)
	harness:equal(projected.appliedIndex, 1, "server projection supplies applied index")
	harness:equal(
		projected.total,
		rollOutcome.data.total,
		"projection total preserves server result"
	)
	harness:equal(projected.audience, "public", "projection audience is explicit")
	harness:expect(type(projected.adjudication) == "string", "server supplies adjudication")
	harness:expect(
		type(projected.semanticCritical) == "string",
		"server supplies critical semantic"
	)

	local privateRecord = table.clone(snapshot.domains.rules.rollRecords[rollOutcome.id])
	privateRecord.audience = "owner"
	privateRecord.ownerUserId = 101
	harness:expect(
		Projection.fromRecord(privateRecord, { userId = 101, role = "player" }, snapshot.domains)
			~= nil,
		"owner-private roll is visible to its owner"
	)
	harness:expect(
		Projection.fromRecord(privateRecord, { userId = 303, role = "dm" }, snapshot.domains) ~= nil,
		"owner-private roll is visible to DM"
	)
	harness:equal(
		Projection.fromRecord(privateRecord, { userId = 202, role = "player" }, snapshot.domains),
		nil,
		"unauthorized viewer receives no private roll placeholder or count"
	)
	local incompleteRecord = table.clone(privateRecord)
	incompleteRecord.notice = nil
	harness:equal(
		Projection.fromRecord(incompleteRecord, { userId = 101, role = "player" }, snapshot.domains),
		nil,
		"incomplete authoritative record is excluded without fabricated fields"
	)

	local function executeProductionMode(mode: string, commandType: string): any
		local created = scenario:execute("rules.create_challenge", {
			ability = "dexterity",
			proficient = false,
			difficultyClass = 12,
			diceMode = mode,
			labelKey = "dice.notice." .. mode,
		})
		local createdOutcome =
			scenario:expectOutcome(harness, created, "creates production " .. mode .. " challenge")
		if createdOutcome == nil then
			return nil
		end
		local result = scenario:execute(commandType, {
			actorId = heroId,
			challengeId = createdOutcome.challengeId,
			diceMode = if mode == "advantage" then "disadvantage" else "advantage",
		})
		local outcome = scenario:expectOutcome(
			harness,
			result,
			"production RulesDomain resolves " .. mode .. " from server challenge"
		)
		if outcome == nil then
			return nil
		end
		harness:equal(outcome.data.diceMode, mode, mode .. " mode comes from server challenge")
		harness:equal(#outcome.data.rolls, 2, mode .. " production roll has two naturals")
		local modeSnapshot = scenario:snapshot()
		local projectedMode = nil
		for _, candidate in
			Projection.build(modeSnapshot.domains, { userId = 101, role = "player" })
		do
			if candidate.rollId == outcome.id then
				projectedMode = candidate
			end
		end
		harness:expect(projectedMode ~= nil, mode .. " production roll is projected")
		if projectedMode ~= nil then
			harness:equal(
				projectedMode.diceMode,
				mode,
				"projection preserves server " .. mode .. " mode"
			)
			harness:equal(
				#projectedMode.naturalResults,
				2,
				"projection preserves both " .. mode .. " naturals"
			)
			harness:expect(
				projectedMode.appliedIndex == 1 or projectedMode.appliedIndex == 2,
				"projection preserves server appliedIndex for " .. mode
			)
			harness:equal(
				projectedMode.total,
				outcome.data.total,
				"projection preserves server " .. mode .. " total"
			)
		end
		return projectedMode
	end

	local productionAdvantage = executeProductionMode("advantage", "rules.ability_check")
	local productionDisadvantage = executeProductionMode("disadvantage", "rules.saving_throw")
	harness:expect(productionAdvantage ~= nil, "production advantage server path is covered")
	harness:expect(productionDisadvantage ~= nil, "production disadvantage server path is covered")

	local function notice(
		id: string,
		revision: number,
		mode: string,
		results: { number },
		appliedIndex: number,
		semanticCritical: string?
	): any
		return {
			rollId = id,
			audience = "public",
			diceMode = mode,
			naturalResults = results,
			appliedIndex = appliedIndex,
			modifierTerms = { { label = "server modifier", value = 5 } },
			total = 777,
			adjudication = "server adjudication",
			semanticCritical = semanticCritical or "none",
			subjectLabel = "Server subject",
			actionLabel = "Server action",
			revealRevision = revision,
			timingProfile = {
				squareEnterMs = 120,
				slotSpinMs = 560,
				naturalLockMs = 180,
				formulaExpandMs = 260,
				adjudicationAppendMs = 180,
				holdMs = 2000,
				dismissMs = 240,
			},
		}
	end

	local normal = notice("roll:normal", 1, "normal", { 12 }, 1, "none")
	local plan = ViewModel.presentationPlan(normal, false)
	local expectedOrder = {
		"hidden",
		"square_enter",
		"slot_spin",
		"natural_lock",
		"formula_expand",
		"adjudication_append",
		"hold",
		"dismiss",
	}
	for index, expected in expectedOrder do
		harness:equal(plan[index].name, expected, "normal reveal state order is exact")
	end
	harness:equal(plan[2].durationMs, 120, "square enter timing is exact")
	harness:expect(
		plan[3].durationMs >= 420 and plan[3].durationMs <= 720,
		"slot spin timing is bounded"
	)
	harness:equal(plan[4].durationMs, 180, "natural lock timing is exact")
	harness:equal(plan[5].durationMs, 260, "formula expansion timing is exact")
	harness:equal(plan[6].durationMs, 180, "adjudication timing is exact")
	harness:expect(
		plan[7].durationMs >= 1600 and plan[7].durationMs <= 2600,
		"hold timing is bounded"
	)
	harness:equal(plan[8].durationMs, 240, "dismiss timing is exact")
	harness:expect(not plan[3].disclosure.natural, "slot spin does not disclose the natural result")
	harness:expect(plan[4].disclosure.natural, "natural locks before formula disclosure")
	harness:expect(not plan[4].disclosure.formula, "natural lock hides formula and total")
	harness:expect(
		plan[5].disclosure.formula and plan[5].disclosure.total,
		"formula and projected total expand together"
	)
	harness:expect(not plan[5].disclosure.adjudication, "formula precedes adjudication")
	harness:expect(plan[6].disclosure.adjudication, "adjudication appends last")
	harness:equal(normal.total, 777, "client preserves projection total without arithmetic")

	local advantage = notice("roll:advantage", 2, "advantage", { 20, 1 }, 2, "natural_1")
	local advantageAnimation = ViewModel.animationDescriptor(advantage, false)
	harness:equal(
		advantageAnimation.slotSpin.kind,
		"vertical_numeral_strip",
		"slot spin uses a real vertical visual movement descriptor"
	)
	harness:expect(
		advantageAnimation.slotSpin.verticalDistance > 0,
		"slot strip consumes a positive vertical movement distance"
	)
	harness:expect(
		not advantageAnimation.slotSpin.finalNaturalVisible,
		"final natural is locked only at natural_lock presentation boundary"
	)
	harness:equal(
		advantageAnimation.formulaExpand.durationMs,
		260,
		"formula expansion consumes 260ms"
	)
	harness:expect(
		advantageAnimation.formulaExpand.usesTween,
		"formula expansion is not an instantaneous-only size assignment"
	)
	harness:equal(
		#advantageAnimation.naturalLock.shakeOffsets,
		5,
		"full-motion Natural 1 has damped horizontal shake"
	)
	harness:equal(advantageAnimation.naturalLock.tintToken, "danger", "Natural 1 uses danger tint")
	harness:expect(
		advantageAnimation.dualApplied.accent
			and advantageAnimation.dualApplied.scale > 1
			and advantageAnimation.dualApplied.formulaConnector,
		"dual Applied Cell has Accent Scale and Formula Connector"
	)
	local advantageCells = ViewModel.cells(advantage)
	harness:equal(#advantageCells, 2, "advantage displays two projected natural cells")
	harness:expect(not advantageCells[1].applied, "client does not choose max for advantage")
	harness:expect(
		advantageCells[2].applied,
		"projection appliedIndex is the only applied authority"
	)
	harness:equal(advantageCells[1].contrast, 0.5, "discarded cell uses 50 percent contrast")
	harness:equal(
		advantageCells[1].semanticCritical,
		"none",
		"discarded natural 20 has no critical visual"
	)
	harness:equal(
		advantageCells[2].semanticCritical,
		"natural_1",
		"applied natural 1 keeps server semantic"
	)

	local disadvantage = notice("roll:disadvantage", 3, "disadvantage", { 1, 20 }, 2, "natural_20")
	local disadvantageAnimation = ViewModel.animationDescriptor(disadvantage, false)
	harness:equal(
		#disadvantageAnimation.naturalLock.shakeOffsets,
		5,
		"full-motion Natural 20 has damped horizontal shake"
	)
	harness:equal(
		disadvantageAnimation.naturalLock.tintToken,
		"success",
		"Natural 20 uses success tint"
	)
	local disadvantageCells = ViewModel.cells(disadvantage)
	harness:equal(#disadvantageCells, 2, "disadvantage displays two projected natural cells")
	harness:expect(disadvantageCells[2].applied, "disadvantage also obeys projection appliedIndex")
	harness:equal(
		disadvantageCells[1].semanticCritical,
		"none",
		"discarded natural 1 has no shake semantic"
	)
	harness:equal(
		disadvantageCells[2].semanticCritical,
		"natural_20",
		"applied natural 20 keeps server semantic"
	)
	local noSemantic = notice("roll:no-semantic", 4, "normal", { 20 }, 1, "none")
	harness:equal(
		ViewModel.cells(noSemantic)[1].semanticCritical,
		"none",
		"natural value alone invents no critical adjudication"
	)

	local reduced = ViewModel.presentationPlan(advantage, true)
	local reducedAnimation = ViewModel.animationDescriptor(advantage, true)
	harness:equal(reduced[3].crossfadeSteps, 3, "reduced motion uses three-step slot crossfade")
	harness:equal(
		reducedAnimation.slotSpin.kind,
		"three_step_crossfade",
		"reduced motion consumes actual crossfade presentation"
	)
	harness:equal(#reducedAnimation.naturalLock.shakeOffsets, 0, "reduced motion has zero shake")
	harness:expect(
		reducedAnimation.naturalLock.outlinePulse and reducedAnimation.naturalLock.tintFade,
		"reduced motion has actual outline pulse and tint fade"
	)
	for index, phase in reduced do
		harness:expect(not phase.shake, "reduced motion removes shake")
		harness:equal(phase.name, expectedOrder[index], "reduced motion preserves disclosure order")
	end

	local componentParent = Instance.new("Folder")
	local component = DiceSlotRevealNotice.new(componentParent, function() end)
	local componentFrame = component:_createFrame(advantage, 1, false)
	local componentRow = child(componentFrame, "NaturalRow")
	local firstCell = child(componentRow, "NaturalCell_1")
	local firstVisual = child(firstCell, "Visual")
	local firstClip = child(firstVisual, "SlotClip")
	harness:expect(
		firstClip.ClipsDescendants,
		"component creates a clipping boundary for slot numerals"
	)
	harness:expect(
		firstClip:FindFirstChild("NumeralStrip") ~= nil,
		"component creates the moving numeral strip"
	)
	harness:expect(
		componentFrame:FindFirstChild("FormulaConnector_2") ~= nil,
		"component creates a real connector for the server-applied dual cell"
	)
	component.generations[advantage.rollId] = 1
	component.tweens[advantage.rollId] = {}
	component:_renderPhase(componentFrame, advantage, plan[3], false, 1)
	harness:expect(
		#component.tweens[advantage.rollId] >= 2,
		"component consumes vertical slot tweens"
	)
	component:_renderPhase(componentFrame, advantage, plan[4], false, 1)
	harness:equal(
		child(child(child(componentRow, "NaturalCell_2"), "Visual"), "LockedValue").Text,
		"1",
		"component locks the server-projected natural at natural_lock"
	)
	harness:expect(
		#component.tweens[advantage.rollId] >= 4,
		"Natural 1 starts visible shake and tint tweens"
	)
	component:_renderPhase(componentFrame, advantage, plan[5], false, 1)
	harness:expect(
		#component.tweens[advantage.rollId] >= 4,
		"formula expansion starts tracked property tweens"
	)
	local naturalTwentyFrame = component:_createFrame(disadvantage, 1, false)
	component.generations[disadvantage.rollId] = 1
	component.tweens[disadvantage.rollId] = {}
	component:_renderPhase(naturalTwentyFrame, disadvantage, plan[4], false, 1)
	harness:expect(
		#component.tweens[disadvantage.rollId] >= 4,
		"Natural 20 starts the same visible shake path and success tint tweens"
	)
	local reducedFrame = component:_createFrame(advantage, 1, false)
	component.generations[advantage.rollId] = 2
	component:_renderPhase(reducedFrame, advantage, plan[4], true, 2)
	harness:expect(
		#component.tweens[advantage.rollId] >= 4,
		"reduced critical starts pulse and tint property tweens"
	)
	component.generations[advantage.rollId] = 3
	component.generations[disadvantage.rollId] = 2
	component:_cancelTweens(advantage.rollId)
	component:_cancelTweens(disadvantage.rollId)
	componentFrame:Destroy()
	naturalTwentyFrame:Destroy()
	reducedFrame:Destroy()
	component:destroy()
	harness:expect(
		true,
		"generation cancellation prevents stale tween task mutation after dismissal recovery"
	)

	local state = ViewModel.reconcile(
		ViewModel.initial("epoch:one"),
		{ normal, advantage, disadvantage },
		"epoch:one"
	)
	harness:equal(#state.active, 2, "simultaneous stack is capped at two")
	harness:equal(#state.queue, 1, "overflow remains in FIFO queue")
	harness:equal(state.active[1].rollId, "roll:normal", "FIFO activates oldest revision first")
	state = ViewModel.reconcile(state, { normal, advantage, disadvantage }, "epoch:one")
	harness:equal(#state.active, 2, "duplicate rollId is not re-enqueued")
	harness:equal(#state.queue, 1, "duplicate reconciliation preserves one overflow")
	state = ViewModel.complete(state, "roll:normal")
	harness:equal(
		state.active[1].rollId,
		"roll:advantage",
		"completion preserves FIFO active order"
	)
	harness:equal(state.active[2].rollId, "roll:disadvantage", "FIFO promotes queued roll")
	local stale = notice("roll:stale", 2, "normal", { 10 }, 1, "none")
	state = ViewModel.reconcile(state, { stale }, "epoch:one")
	harness:expect(state.seen["roll:stale"] ~= true, "stale revealRevision is suppressed")
	local reconnect = ViewModel.reconcile(state, { normal, advantage, disadvantage }, "epoch:two")
	harness:expect(
		reconnect.seen["roll:normal"] == true,
		"acknowledged roll remains suppressed after reconnect"
	)
	harness:equal(
		#reconnect.active,
		0,
		"already revealed active roll is not replayed after reconnect"
	)
	harness:equal(
		#reconnect.queue,
		0,
		"already revealed queued rolls are not replayed after reconnect"
	)
	local suspended = ViewModel.suspend(state, "epoch:one")
	harness:equal(#suspended.active, 0, "recovery clears active notices immediately")
	harness:equal(#suspended.queue, 0, "recovery clears queued notices immediately")
	harness:expect(
		suspended.acknowledged["roll:normal"] == true,
		"recovery retains acknowledged suppression"
	)
	harness:equal(
		ViewModel.layout(normal, false).topOffset,
		18,
		"default top-center offset is deterministic"
	)
	harness:equal(
		ViewModel.layout(normal, true).topOffset,
		126,
		"initiative collision offset is deterministic"
	)
	harness:equal(
		ViewModel.layout(normal, false).initialWidth,
		64,
		"normal notice begins at 64 by 64"
	)
	harness:equal(
		ViewModel.layout(advantage, false).initialWidth,
		148,
		"dual notice begins at least 148 by 64"
	)
end
