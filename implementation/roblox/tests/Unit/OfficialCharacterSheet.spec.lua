--!strict

return function(harness: any)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Server = game:GetService("ServerScriptService").RVTT.Server
	local UI = ReplicatedStorage.RVTT.Shared.UI
	local Layout = require(UI.CharacterSheetLayout)
	local ViewModel = require(UI.CharacterSheetViewModel)
	local Projection = require(Server.Projection.CharacterSheetProjection)

	local domains: any = {
		session = {
			memberships = {
				["101"] = { role = "player" },
				["202"] = { role = "player" },
				["303"] = { role = "dm" },
				["404"] = { role = "observer" },
			},
			selectedCharacter = {
				["101"] = "character:hero",
				["303"] = "character:hero",
			},
		},
		character = {
			drafts = {},
			characters = {
				["character:hero"] = {
					id = "character:hero",
					ownerUserId = 101,
					name = "테스트 영웅",
					level = 5,
					classId = "class.test",
					subclassId = "subclass.test",
					speciesId = "species.test",
					backgroundId = "background.test",
					abilities = {
						strength = 16,
						dexterity = 14,
						constitution = 12,
						intelligence = 10,
						wisdom = 13,
						charisma = 8,
					},
					saves = {
						strength = {
							label = "근력 내성",
							ability = "strength",
							proficient = true,
						},
					},
					skills = {
						athletics = { label = "운동", ability = "strength", proficient = true },
					},
					inspiration = true,
					hitDice = { sides = 10, remaining = 3 },
					classFeatures = {
						["feature.test"] = {
							label = "Test feature",
							rollAbility = "wisdom",
						},
					},
					attacks = {
						["attack.test"] = {
							label = "테스트 무기",
							ability = "strength",
							proficient = true,
							count = 1,
							sides = 8,
						},
					},
					spellcasting = {
						ability = "wisdom",
						availableSpells = {
							["spell.test"] = { label = "테스트 주문" },
						},
					},
					preparedSpells = {},
					coins = { gp = 10 },
				},
				["character:other"] = {
					id = "character:other",
					ownerUserId = 202,
					name = "다른 플레이어",
					level = 1,
					abilities = {
						strength = 10,
						dexterity = 10,
						constitution = 10,
						intelligence = 10,
						wisdom = 10,
						charisma = 10,
					},
				},
			},
		},
		scene = {
			actors = {
				["actor:hero"] = {
					id = "actor:hero",
					sourceCharacterId = "character:hero",
					ownerUserId = 101,
					controllerUserId = 101,
				},
			},
		},
		rules = {
			actorStates = {
				["actor:hero"] = {
					currentHitPoints = 20,
					maximumHitPoints = 30,
					temporaryHitPoints = 4,
					profileRevision = 1,
				},
			},
			rollRecords = {},
			challenges = {},
			conditions = {},
		},
		inventory = {
			items = {
				["item:test"] = {
					id = "item:test",
					definitionId = "item.test",
					quantity = 2,
					revision = 1,
					equipSlot = "main_hand",
					usable = true,
					attunable = true,
					hotbarCapable = true,
				},
			},
			locations = {
				["item:test"] = { kind = "inventory", characterId = "character:hero" },
			},
		},
	}

	local owner = Projection.build(domains, { userId = 101, role = "player" }, 42, nil)
	harness:expect(owner.canReadFullSheet, "owner receives a full CharacterSheetProjection")
	harness:expect(owner.canControl, "owner receives projected control metadata")
	harness:equal(owner.characterId, "character:hero", "owner sheet targets the selected character")
	harness:equal(owner.revision, 42, "sheet revision equals the authoritative envelope revision")
	harness:equal(owner.vitals.hpCurrent, 20, "vitals come from authoritative rules state")

	local unrelated =
		Projection.build(domains, { userId = 202, role = "player" }, 42, "character:hero")
	harness:expect(not unrelated.canReadFullSheet, "unrelated player cannot read the full sheet")
	harness:equal(unrelated.characterId, nil, "denied projection exposes no character identifier")
	harness:equal(unrelated.identity, nil, "denied projection exposes no private identity")
	local observer = Projection.build(domains, { userId = 404, role = "observer" }, 42, nil)
	harness:expect(not observer.canReadFullSheet, "observer receives a safe unavailable projection")
	local dm = Projection.build(domains, { userId = 303, role = "dm" }, 42, nil)
	harness:expect(
		dm.canReadFullSheet and dm.canControl,
		"authorized DM can read and control the sheet"
	)

	local payload = { characterSheet = owner }
	local feedback = ViewModel.initialFeedback(42, "epoch:test")
	local state = ViewModel.build(payload, 42, feedback, 1600)
	harness:equal(
		state.layoutMode,
		"WideReference",
		"wide/reference viewport uses a two-page spread"
	)
	harness:equal(state.revision, 42, "view model preserves projection revision parity")
	local staleIntent, staleError = ViewModel.actionIntent(state, "roll.ability.strength", 41)
	harness:equal(staleIntent, nil, "stale candidate revision fails closed")
	harness:equal(staleError, "STALE_PROJECTION", "stale intent reports the stable failure")

	local requiredActions = {
		["roll.ability.strength"] = "rules.sheet_roll",
		["roll.saving_throw.strength"] = "rules.sheet_roll",
		["roll.skill.athletics"] = "rules.sheet_roll",
		["roll.initiative"] = "rules.sheet_roll",
		["roll.weapon_attack.attack.test"] = "rules.sheet_roll",
		["roll.weapon_damage.attack.test"] = "rules.sheet_roll",
		["roll.spell_attack"] = "rules.sheet_roll",
		["roll.hit_die"] = "rules.sheet_roll",
		["roll.feature.feature.test"] = "rules.sheet_roll",
		["item.item:test.equip"] = "inventory.equip",
		["item.item:test.use"] = "inventory.use",
		["item.item:test.split"] = "inventory.split",
		["item.item:test.attune"] = "inventory.set_attunement",
		["item.item:test.pin"] = "character.sheet_set_hotbar",
		["spell.spell.test.prepare"] = "character.sheet_set_prepared",
		["inspiration.spend"] = "character.sheet_spend_inspiration",
	}
	for actionId, commandType in requiredActions do
		local intent, errorCode = ViewModel.actionIntent(state, actionId, 42)
		harness:expect(
			intent ~= nil and errorCode == nil,
			tostring(actionId) .. " creates an authoritative intent"
		)
		if intent ~= nil then
			harness:equal(
				intent.commandType,
				commandType,
				tostring(actionId) .. " uses the server command pipeline"
			)
		end
	end
	harness:equal(
		state.abilities[1].score,
		16,
		"view model does not replace projected ability values"
	)
	harness:equal(state.abilities[1].modifier, 3, "ability modifier is projected by the server")

	local sendIntent, sendError = ViewModel.actionIntent(state, "item.item:test.send", 42)
	harness:equal(sendIntent, nil, "disabled send action cannot submit")
	harness:equal(sendError, "ACTION_DISABLED", "disabled action preserves explicit semantics")
	domains.inventory.locations["item:test"] = {
		kind = "equipped",
		characterId = "character:hero",
		slot = "main_hand",
	}
	local equipped = Projection.build(domains, { userId = 101, role = "player" }, 43, nil)
	local equippedState = ViewModel.build({ characterSheet = equipped }, 43, feedback, 900)
	harness:equal(equippedState.layoutMode, "Compact", "compact viewport uses page tabs")
	local unequip = ViewModel.actionIntent(equippedState, "item.item:test.unequip", 43)
	harness:expect(unequip ~= nil, "equipped item exposes authoritative unequip")

	local pending =
		ViewModel.pendingFeedback("roll.ability.strength", "command:sheet", 42, "epoch:test")
	harness:equal(pending.state, "pending_receipt", "submission waits for a receipt")
	local accepted = ViewModel.resolveReceipt(pending, true, nil, 43)
	harness:equal(
		accepted.state,
		"accepted_awaiting_projection",
		"receipt success does not mutate local sheet state"
	)
	harness:equal(
		ViewModel.reconcile(accepted, owner, 42, "epoch:test").state,
		"accepted_awaiting_projection",
		"old projection cannot reconcile an accepted command"
	)
	harness:equal(
		ViewModel.reconcile(accepted, equipped, 43, "epoch:test").state,
		"reconciled",
		"matching authoritative projection completes reconciliation"
	)
	harness:equal(
		ViewModel.resolveReceipt(pending, false, "STALE_REVISION", nil).state,
		"stale_projection",
		"stale receipt is distinct from denial"
	)
	harness:equal(
		ViewModel.reconcile(accepted, unrelated, 43, "epoch:test").state,
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
