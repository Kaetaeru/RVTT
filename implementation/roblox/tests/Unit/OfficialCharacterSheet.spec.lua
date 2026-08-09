--!strict

return function(harness: any)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Server = game:GetService("ServerScriptService").RVTT.Server
	local UI = ReplicatedStorage.RVTT.Shared.UI
	local Layout = require(UI.CharacterSheetLayout)
	local ViewModel = require(UI.CharacterSheetViewModel)
	local Projection = require(Server.Projection.CharacterSheetProjection)
	local ScenarioRuntime = require(script.Parent.Parent.Integration.ScenarioRuntime)
	local scenario = ScenarioRuntime.new(101, "dm")

	local function outcome(result: any, label: string): any
		return scenario:expectOutcome(harness, result, label)
	end

	local function mapCount(source: any): number
		local count = 0
		for _ in source do
			count += 1
		end
		return count
	end

	local registered = scenario:execute("content.register_pack", {
		manifest = {
			packId = "pack:sheet-original",
			version = "1.0.0",
			rightsStatus = "original",
			dependencies = {},
			definitions = {
				characterSheets = {
					["class:generic-sheet"] = {
						saves = {
							strength = {
								label = "Strength Save",
								ability = "strength",
								proficient = true,
							},
						},
						skills = {
							athletics = {
								label = "Athletics",
								ability = "strength",
								proficient = true,
							},
						},
						training = { armor = { label = "Generic armor training" } },
						inspiration = true,
						hitDice = { sides = 10, remaining = 1 },
						classFeatures = {
							["feature:generic"] = {
								label = "Generic feature",
								rollAbility = "wisdom",
							},
						},
						attacks = {
							["attack:generic"] = {
								label = "Generic weapon",
								ability = "strength",
								proficient = true,
								count = 1,
								sides = 8,
								damageModifier = 1,
							},
						},
						spellcasting = {
							ability = "wisdom",
							slots = { [1] = { remaining = 2, maximum = 3 } },
							availableSpells = {
								["spell:generic"] = { label = "Generic spell" },
							},
						},
						preparedSpells = {},
						coins = { gp = 10 },
						size = "medium",
						passivePerception = 12,
					},
					["class:generic-attackless"] = {
						saves = {},
						skills = {},
						classFeatures = {},
						preparedSpells = {},
					},
				},
				items = {
					["item:generic-tool"] = {
						label = "Generic tool",
						details = "An original generic item used by the focused regression.",
						equipSlot = "main_hand",
						usable = true,
						attunable = true,
						hotbarCapable = true,
						transferable = true,
					},
					["item:generic-pack"] = {
						label = "Generic pack",
						details = "A second row proves equipment is not first-row-only.",
						transferable = true,
					},
				},
			},
		},
	})
	if outcome(registered, "focused spec registers server-owned generic definitions") == nil then
		return
	end
	if
		outcome(
			scenario:execute("content.activate_pack", { packId = "pack:sheet-original" }),
			"focused spec activates the authoritative content pack"
		) == nil
	then
		return
	end
	if outcome(scenario:execute("session.join", {}), "sheet owner joins the session") == nil then
		return
	end

	local function createCharacter(name: string, classId: string?): string?
		local draft = outcome(
			scenario:execute("character.create_draft", { name = name }),
			"production path creates " .. name
		)
		if draft == nil then
			return nil
		end
		local updated = scenario:execute("character.update_draft", {
			characterId = draft.id,
			patch = {
				classId = classId or "class:generic-sheet",
				ancestryId = "species:generic",
				backgroundId = "background:generic",
				abilities = {
					strength = 16,
					dexterity = 14,
					constitution = 12,
					intelligence = 10,
					wisdom = 13,
					charisma = 8,
				},
			},
		})
		if outcome(updated, "production path selects a server-owned sheet definition") == nil then
			return nil
		end
		if
			outcome(
				scenario:execute("character.activate", { characterId = draft.id }),
				"activation hydrates authoritative sheet state"
			) == nil
		then
			return nil
		end
		return draft.id
	end

	local heroId = createCharacter("Generic Hero")
	local otherId = createCharacter("Generic Recipient")
	local attacklessId = createCharacter("Generic Attackless", "class:generic-attackless")
	if heroId == nil or otherId == nil or attacklessId == nil then
		return
	end
	if
		outcome(
			scenario:execute("session.select_character", { characterId = heroId }),
			"owner selects the sheet character"
		) == nil
	then
		return
	end
	if
		outcome(scenario:execute("session.ready", { ready = true }), "owner becomes ready") == nil
	then
		return
	end
	if
		outcome(
			scenario:execute("session.start", { sceneId = "scene:sheet" }),
			"session starts for the sheet actor"
		) == nil
	then
		return
	end
	if
		outcome(
			scenario:execute("scene.enter", { sceneId = "scene:sheet", actorId = heroId }),
			"production scene path creates the controlled actor"
		) == nil
	then
		return
	end
	if
		outcome(
			scenario:execute("scene.enter", { sceneId = "scene:sheet", actorId = attacklessId }),
			"production scene path creates the trusted attack-less actor"
		) == nil
	then
		return
	end
	if
		outcome(
			scenario:execute("rules.set_actor_state", {
				actorId = heroId,
				currentHitPoints = 20,
				maximumHitPoints = 30,
				temporaryHitPoints = 4,
			}),
			"authoritative rules path creates vitals"
		) == nil
	then
		return
	end

	local itemResult = outcome(
		scenario:execute("inventory.create_item", {
			definitionId = "item:generic-tool",
			quantity = 3,
			location = { kind = "inventory", characterId = heroId },
		}),
		"production inventory path snapshots trusted capabilities"
	)
	local secondItemResult = outcome(
		scenario:execute("inventory.create_item", {
			definitionId = "item:generic-pack",
			location = { kind = "inventory", characterId = heroId },
		}),
		"production inventory path creates a second equipment row"
	)
	local otherItemResult = outcome(
		scenario:execute("inventory.create_item", {
			definitionId = "item:generic-tool",
			location = { kind = "inventory", characterId = otherId },
		}),
		"production inventory path creates another character's capable item"
	)
	if itemResult == nil or secondItemResult == nil or otherItemResult == nil then
		return
	end
	local itemId = itemResult.item.id
	local secondItemId = secondItemResult.item.id
	local otherItemId = otherItemResult.item.id
	local domains = scenario:snapshot().domains
	harness:equal(
		domains.character.characters[heroId].sheetDefinitionId,
		"class:generic-sheet",
		"activation records the authoritative definition used for hydration"
	)
	harness:expect(
		domains.inventory.items[itemId].usable == true,
		"created item receives capability metadata from the active server-owned definition"
	)

	local revision = scenario:snapshot().revision
	local owner = Projection.build(domains, { userId = 101, role = "player" }, revision, heroId)
	harness:expect(owner.canReadFullSheet, "owner receives a full CharacterSheetProjection")
	harness:expect(owner.canControl, "owner receives projected control metadata")
	harness:equal(
		owner.revision,
		revision,
		"sheet revision equals the authoritative envelope revision"
	)
	harness:equal(owner.vitals.hpCurrent, 20, "vitals come from authoritative rules state")
	harness:equal(#owner.equipment, 2, "all production-created equipment rows are projected")
	harness:equal(
		owner.weaponsAndDamageCantrips[1].id,
		"attack:generic",
		"projection uses the ActorProfileResolver canonical attack catalog"
	)
	local attackless =
		Projection.build(domains, { userId = 101, role = "player" }, revision, attacklessId)
	harness:equal(
		#attackless.weaponsAndDamageCantrips,
		0,
		"trusted attack-less production character receives no invented attack row"
	)

	local unrelated = Projection.build(domains, { userId = 202, role = "player" }, revision, heroId)
	harness:expect(not unrelated.canReadFullSheet, "unrelated player cannot read the full sheet")
	harness:equal(unrelated.characterId, nil, "denied projection exposes no character identifier")
	harness:equal(unrelated.identity, nil, "denied projection exposes no private identity")
	local observer = Projection.build(domains, { userId = 404, role = "observer" }, revision, nil)
	harness:expect(not observer.canReadFullSheet, "observer receives a safe unavailable projection")
	local dm = Projection.build(domains, { userId = 303, role = "dm" }, revision, heroId)
	harness:expect(
		dm.canReadFullSheet and dm.canControl,
		"authorized DM can read and control the sheet"
	)

	local feedback = ViewModel.initialFeedback(revision, "epoch:test")
	local state = ViewModel.build({ characterSheet = owner }, revision, feedback, 1600)
	harness:equal(
		state.layoutMode,
		"WideReference",
		"wide/reference viewport uses a two-page spread"
	)
	local staleIntent, staleError =
		ViewModel.actionIntent(state, "roll.ability.strength", revision - 1)
	harness:equal(staleIntent, nil, "stale candidate revision fails closed")
	harness:equal(staleError, "STALE_PROJECTION", "stale intent reports the stable failure")

	local requiredActions = {
		["roll.ability.strength"] = "rules.sheet_roll",
		["roll.saving_throw.strength"] = "rules.sheet_roll",
		["roll.skill.athletics"] = "rules.sheet_roll",
		["roll.initiative"] = "rules.sheet_roll",
		["roll.weapon_attack.attack:generic"] = "rules.sheet_roll",
		["roll.weapon_damage.attack:generic"] = "rules.sheet_roll",
		["roll.spell_attack"] = "rules.sheet_roll",
		["roll.hit_die"] = "rules.sheet_roll",
		["roll.feature.feature:generic"] = "rules.sheet_roll",
		["item." .. itemId .. ".equip"] = "inventory.equip",
		["item." .. itemId .. ".use"] = "inventory.use",
		["item." .. itemId .. ".split"] = "inventory.split",
		["item." .. itemId .. ".attune"] = "inventory.set_attunement",
		["item." .. itemId .. ".pin"] = "character.sheet_set_hotbar",
		["item." .. itemId .. ".send." .. otherId] = "inventory.send",
		["spell.spell:generic.prepare"] = "character.sheet_set_prepared",
		["inspiration.spend"] = "character.sheet_spend_inspiration",
	}
	for actionId, commandType in requiredActions do
		local intent, errorCode = ViewModel.actionIntent(state, actionId, revision)
		harness:expect(
			intent ~= nil and errorCode == nil,
			actionId .. " creates an authoritative intent"
		)
		if intent ~= nil then
			harness:equal(
				intent.commandType,
				commandType,
				actionId .. " uses the server command pipeline"
			)
		end
	end

	local validSkill = outcome(
		scenario:execute("rules.sheet_roll", {
			actorId = heroId,
			rollKind = "skill",
			sourceId = "athletics",
		}),
		"authoritative skill roll resolves through the real command registry"
	)
	if validSkill ~= nil then
		harness:equal(validSkill.data.modifier, 5, "skill modifier is derived from server state")
	end
	local forgedCases: { any } = {
		{
			field = "ability",
			value = "charisma",
			label = "forged ability roll semantics are rejected",
		},
		{
			field = "proficient",
			value = true,
			label = "forged proficient roll semantics are rejected",
		},
		{
			field = "mode",
			value = "advantage",
			label = "forged mode roll semantics are rejected",
		},
	}
	for _, forgedCase in forgedCases do
		local payload = {
			actorId = heroId,
			rollKind = "skill",
			sourceId = "athletics",
		}
		payload[forgedCase.field] = forgedCase.value
		local forged = scenario:execute("rules.sheet_roll", payload)
		harness:expect(not forged.ok, forgedCase.label)
		if not forged.ok then
			harness:equal(
				forged.error.code,
				"VALIDATION_FAILED",
				"forged semantics fail validation"
			)
		end
	end
	local forgedHitDieFields = {
		{ field = "sides", value = 100 },
		{ field = "count", value = 2 },
		{ field = "modifier", value = 99 },
		{ field = "remaining", value = 99 },
	}
	for _, forgedCase in forgedHitDieFields do
		local before = scenario:snapshot()
		local payload = { actorId = heroId, rollKind = "hit_die" }
		payload[forgedCase.field] = forgedCase.value
		local forged = scenario:execute("rules.sheet_roll", payload)
		harness:expect(not forged.ok, "forged hit die " .. forgedCase.field .. " is rejected")
		if not forged.ok then
			harness:equal(
				forged.error.code,
				"VALIDATION_FAILED",
				"hit die semantics fail validation"
			)
		end
		local after = scenario:snapshot()
		harness:equal(after.revision, before.revision, "forged hit die does not advance authority")
		harness:equal(
			after.domains.character.characters[heroId].hitDice.remaining,
			before.domains.character.characters[heroId].hitDice.remaining,
			"forged hit die does not consume a die"
		)
		harness:equal(
			mapCount(after.domains.rules.rollRecords),
			mapCount(before.domains.rules.rollRecords),
			"forged hit die creates no roll record"
		)
	end
	local hitDieBefore = scenario:snapshot()
	local hitDie = outcome(
		scenario:execute("rules.sheet_roll", { actorId = heroId, rollKind = "hit_die" }),
		"valid hit die roll consumes one trusted die"
	)
	if hitDie ~= nil then
		harness:equal(
			hitDie.data.remaining,
			0,
			"hit die result reports the authoritative remainder"
		)
	end
	local hitDieAfter = scenario:snapshot()
	harness:equal(
		hitDieAfter.domains.character.characters[heroId].hitDice.remaining,
		0,
		"successful hit die roll consumes exactly one"
	)
	harness:equal(hitDieAfter.revision, hitDieBefore.revision + 1, "hit die commits once")
	local exhaustedProjection = Projection.build(
		hitDieAfter.domains,
		{ userId = 101, role = "player" },
		hitDieAfter.revision,
		heroId
	)
	harness:equal(
		exhaustedProjection.vitals.hitDieActionId,
		nil,
		"zero remaining removes hit die action"
	)
	local exhaustedIntent = nil
	for _, action in exhaustedProjection.actions do
		if action.id == "roll.hit_die" then
			exhaustedIntent = action
		end
	end
	harness:equal(exhaustedIntent, nil, "zero remaining is not exposed as an executable action")
	local zeroBefore = scenario:snapshot()
	local zeroRoll =
		scenario:execute("rules.sheet_roll", { actorId = heroId, rollKind = "hit_die" })
	harness:expect(not zeroRoll.ok, "direct hit die roll at zero fails closed")
	local zeroAfter = scenario:snapshot()
	harness:equal(
		zeroAfter.revision,
		zeroBefore.revision,
		"failed zero hit die does not advance authority"
	)
	harness:equal(
		mapCount(zeroAfter.domains.rules.rollRecords),
		mapCount(zeroBefore.domains.rules.rollRecords),
		"failed zero hit die creates no roll record"
	)
	harness:equal(
		zeroAfter.domains.character.characters[heroId].hitDice.remaining,
		zeroBefore.domains.character.characters[heroId].hitDice.remaining,
		"failed zero hit die preserves remaining"
	)
	local forgedDamage = scenario:execute("rules.sheet_roll", {
		actorId = heroId,
		rollKind = "weapon_damage",
		sourceId = "attack:generic",
		sides = 100,
	})
	harness:expect(not forgedDamage.ok, "forged damage formula is rejected")
	local missingAttack = scenario:execute("rules.sheet_roll", {
		actorId = heroId,
		rollKind = "weapon_attack",
		sourceId = "attack:missing",
	})
	harness:expect(not missingAttack.ok, "nonexistent authoritative attack is rejected")
	local damage = outcome(
		scenario:execute("rules.sheet_roll", {
			actorId = heroId,
			rollKind = "weapon_damage",
			sourceId = "attack:generic",
		}),
		"weapon damage uses the authoritative attack formula"
	)
	if damage ~= nil then
		harness:equal(
			damage.data.modifier,
			4,
			"damage modifier comes from profile ability and definition"
		)
	end
	local deathSave = scenario:execute("rules.sheet_roll", {
		actorId = heroId,
		rollKind = "death_save",
	})
	harness:expect(not deathSave.ok, "HP above zero rejects death saves")
	local stolen = scenario:executeAs("player", 999, "rules.sheet_roll", {
		actorId = heroId,
		rollKind = "ability",
		sourceId = "strength",
	})
	harness:expect(not stolen.ok, "another user's actor roll is rejected")
	if not stolen.ok then
		harness:equal(stolen.error.code, "UNAUTHORIZED", "actor control denial is explicit")
	end

	local equipBefore = scenario:snapshot()
	local forgedSlot = scenario:execute("inventory.equip", {
		itemId = itemId,
		characterId = heroId,
		slot = "forged_slot",
	})
	harness:expect(not forgedSlot.ok, "forged equip slot fails closed")
	local equipAfterForgery = scenario:snapshot()
	harness:equal(
		equipAfterForgery.revision,
		equipBefore.revision,
		"forged slot does not advance authority"
	)
	harness:equal(
		equipAfterForgery.domains.inventory.items[itemId].revision,
		equipBefore.domains.inventory.items[itemId].revision,
		"forged slot does not mutate item revision"
	)
	local nonEquippableBefore = scenario:snapshot()
	local nonEquippable = scenario:execute("inventory.equip", {
		itemId = secondItemId,
		characterId = heroId,
	})
	harness:expect(not nonEquippable.ok, "non-equippable item fails direct equip")
	local nonEquippableAfter = scenario:snapshot()
	harness:equal(
		nonEquippableAfter.revision,
		nonEquippableBefore.revision,
		"non-equippable failure does not commit"
	)
	harness:equal(
		nonEquippableAfter.domains.inventory.items[secondItemId].revision,
		nonEquippableBefore.domains.inventory.items[secondItemId].revision,
		"non-equippable failure preserves item revision"
	)
	local crossEquipBefore = scenario:snapshot()
	local crossEquip = scenario:execute("inventory.equip", {
		itemId = otherItemId,
		characterId = heroId,
	})
	harness:expect(
		not crossEquip.ok,
		"another character's item cannot be equipped across characters"
	)
	local crossEquipAfter = scenario:snapshot()
	harness:equal(
		crossEquipAfter.revision,
		crossEquipBefore.revision,
		"cross-character equip does not commit"
	)
	harness:equal(
		crossEquipAfter.domains.inventory.locations[otherItemId].characterId,
		otherId,
		"cross-character equip preserves the trusted location"
	)
	local validEquip = outcome(
		scenario:execute("inventory.equip", { itemId = itemId, characterId = heroId }),
		"equippable item uses its trusted slot"
	)
	if validEquip ~= nil then
		harness:equal(
			validEquip.location.slot,
			"main_hand",
			"trusted item snapshot selects the slot"
		)
	end
	if
		outcome(
			scenario:execute("inventory.unequip", { itemId = itemId, characterId = heroId }),
			"trusted equipped item returns to inventory"
		) == nil
	then
		return
	end

	local hotbarBefore = scenario:snapshot()
	local incapablePin = scenario:execute("character.sheet_set_hotbar", {
		characterId = heroId,
		targetKind = "item",
		targetId = secondItemId,
		pinned = true,
	})
	harness:expect(not incapablePin.ok, "non-hotbar-capable item cannot be pinned")
	local incapableAfter = scenario:snapshot()
	harness:equal(incapableAfter.revision, hotbarBefore.revision, "incapable pin does not commit")
	harness:equal(
		incapableAfter.domains.character.characters[heroId].revision,
		hotbarBefore.domains.character.characters[heroId].revision,
		"incapable pin does not mutate character revision"
	)
	local crossPinBefore = scenario:snapshot()
	local crossPin = scenario:execute("character.sheet_set_hotbar", {
		characterId = heroId,
		targetKind = "item",
		targetId = otherItemId,
		pinned = true,
	})
	harness:expect(not crossPin.ok, "another character's capable item cannot be pinned")
	local crossUnpin = scenario:execute("character.sheet_set_hotbar", {
		characterId = heroId,
		targetKind = "item",
		targetId = otherItemId,
		pinned = false,
	})
	harness:expect(not crossUnpin.ok, "unpin cannot bypass the item-character relationship guard")
	local crossPinAfter = scenario:snapshot()
	harness:equal(
		crossPinAfter.revision,
		crossPinBefore.revision,
		"cross-character pin/unpin does not commit"
	)
	harness:equal(
		crossPinAfter.domains.character.characters[heroId].revision,
		crossPinBefore.domains.character.characters[heroId].revision,
		"cross-character pin/unpin preserves character revision"
	)
	local pin = scenario:execute("character.sheet_set_hotbar", {
		characterId = heroId,
		targetKind = "item",
		targetId = itemId,
		pinned = true,
	})
	harness:expect(pin.ok, "own capable item pin succeeds")
	local unpin = scenario:execute("character.sheet_set_hotbar", {
		characterId = heroId,
		targetKind = "item",
		targetId = itemId,
		pinned = false,
	})
	harness:expect(unpin.ok, "own capable item unpin succeeds through the same guard")

	local productionActions: { { commandType: string, payload: any } } = {
		{
			commandType = "inventory.set_attunement",
			payload = { itemId = itemId, characterId = heroId, attuned = true },
		},
		{
			commandType = "inventory.set_attunement",
			payload = { itemId = itemId, characterId = heroId, attuned = false },
		},
		{ commandType = "inventory.split", payload = { itemId = itemId, quantity = 1 } },
		{ commandType = "inventory.use", payload = { itemId = itemId } },
		{
			commandType = "character.sheet_set_prepared",
			payload = { characterId = heroId, spellId = "spell:generic", prepared = true },
		},
		{
			commandType = "inventory.send",
			payload = { itemId = itemId, targetCharacterId = otherId },
		},
	}
	for _, command in productionActions do
		harness:expect(
			scenario:execute(command.commandType, command.payload).ok,
			command.commandType .. " succeeds for production-hydrated state"
		)
	end

	local pendingFirst = ViewModel.pendingFeedback("first", "command:first", revision, "epoch:test")
	local pendingSecond =
		ViewModel.pendingFeedback("second", "command:second", revision, "epoch:test")
	local outOfOrder = ViewModel.resolveMatchingReceipt(
		pendingSecond,
		pendingFirst,
		"command:first",
		true,
		nil,
		revision + 1
	)
	harness:equal(
		outOfOrder.commandId,
		"command:second",
		"out-of-order terminal receipt cannot replace latest feedback"
	)
	local accepted = ViewModel.resolveMatchingReceipt(
		pendingSecond,
		pendingSecond,
		"command:second",
		true,
		nil,
		revision + 1
	)
	harness:equal(
		accepted.state,
		"accepted_awaiting_projection",
		"receipt success does not mutate local sheet state"
	)
	harness:equal(
		ViewModel.reconcile(accepted, owner, revision, "epoch:test").state,
		"accepted_awaiting_projection",
		"old projection cannot reconcile an accepted command"
	)
	harness:equal(
		ViewModel.resolveReceipt(pendingFirst, false, "STALE_REVISION", nil).state,
		"stale_projection",
		"stale receipt is distinct from denial"
	)
	harness:equal(
		ViewModel.reconcile(accepted, unrelated, revision + 1, "epoch:test").state,
		"permission_revoked",
		"permission loss invalidates the sheet safely"
	)

	harness:equal(Layout.PAGE_1.TOP_HEADER, 0.13, "Page 1 header ratio is locked")
	harness:equal(Layout.PAGE_1.MAIN, 0.87, "Page 1 main ratio is locked")
	harness:equal(Layout.PAGE_1.MAIN_LEFT, 0.35, "Page 1 left ratio is locked")
	harness:equal(Layout.PAGE_1.MAIN_RIGHT, 0.65, "Page 1 right ratio is locked")
	harness:equal(Layout.PAGE_1.RIGHT_WEAPONS, 0.24, "Page 1 weapons ratio is locked")
	harness:equal(Layout.PAGE_1.RIGHT_CLASS_FEATURES, 0.43, "Page 1 class feature ratio is locked")
	harness:equal(Layout.PAGE_1.RIGHT_SPECIES_FEATS, 0.33, "Page 1 species/feat ratio is locked")
	harness:equal(Layout.PAGE_2.LEFT, 0.68, "Page 2 left ratio is locked")
	harness:equal(Layout.PAGE_2.RIGHT, 0.32, "Page 2 right ratio is locked")
	harness:equal(Layout.PAGE_2.SPELLCASTING_ABILITY, 0.24, "Page 2 spell ability ratio is locked")
	harness:equal(Layout.PAGE_2.SPELL_SLOTS, 0.76, "Page 2 spell slots ratio is locked")
	harness:equal(
		Layout.PAGE_2.RIGHT_APPEARANCE
			+ Layout.PAGE_2.RIGHT_BACKSTORY
			+ Layout.PAGE_2.RIGHT_LANGUAGES
			+ Layout.PAGE_2.RIGHT_EQUIPMENT
			+ Layout.PAGE_2.RIGHT_COINS,
		1,
		"Page 2 right sections fill the page without reflow"
	)
end
