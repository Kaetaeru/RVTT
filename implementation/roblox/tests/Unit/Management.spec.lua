--!strict

return function(harness: any)
	local UI = game:GetService("ReplicatedStorage").RVTT.Shared.UI
	local ViewModel = require(UI.ManagementViewModel)
	local Preferences = require(UI.PreferencePresentation)

	local payload: any = {
		domains = {
			session = {
				phase = "active",
				memberships = { ["101"] = { role = "player" } },
				selectedCharacter = { ["101"] = "hero-character" },
			},
			scene = {
				actors = { hero = { id = "hero", sourceCharacterId = "hero-character" } },
			},
			character = {
				characters = {
					["hero-character"] = {
						id = "hero-character",
						name = "영웅",
						ownerUserId = 101,
					},
					["other-character"] = {
						id = "other-character",
						name = "타인",
						ownerUserId = 202,
					},
				},
			},
			inventory = {
				items = {
					owned = { id = "owned", definitionId = "rope", quantity = 2 },
					ground = { id = "ground", definitionId = "torch", quantity = 1 },
				},
				locations = {
					owned = { kind = "equipped", characterId = "hero-character", slot = "belt" },
					ground = { kind = "ground" },
				},
			},
			journal = {
				documents = {
					mine = {
						id = "mine",
						ownerUserId = 101,
						title = "A 내 기록",
						body = "본문",
						visibility = "private",
					},
					party = {
						id = "party",
						ownerUserId = 202,
						title = "B 공개 기록",
						body = "공개",
						visibility = "party",
					},
				},
			},
		},
	}

	local state = ViewModel.build(payload, 101, "hero", 8, nil)
	harness:equal(
		state.targetCharacterId,
		"hero-character",
		"projected actor selects an owned inventory target"
	)
	harness:equal(#state.items, 2, "inventory contains only projected items")
	harness:equal(#state.documents, 2, "journal contains only projected documents")
	harness:equal(state.selectedDocumentId, "mine", "journal selection is deterministic")

	local move, moveError = ViewModel.moveIntent(state, "owned", 8)
	harness:expect(move ~= nil and moveError == nil, "owned equipped item produces a move intent")
	if move ~= nil then
		harness:equal(
			move.commandType,
			"inventory.move_item",
			"inventory action uses the registered command"
		)
		harness:equal(
			move.payload.location.characterId,
			"hero-character",
			"intent targets the selected owned character"
		)
	end
	local groundMove, groundError = ViewModel.moveIntent(state, "ground", 8)
	harness:equal(groundMove, nil, "visible ground item does not imply player authority")
	harness:equal(groundError, "PERMISSION_DENIED", "authority absence is explicit")
	local staleMove, staleError = ViewModel.moveIntent(state, "owned", 7)
	harness:equal(staleMove, nil, "stale inventory candidate cannot submit")
	harness:equal(staleError, "STALE_PROJECTION", "stale inventory failure is explicit")
	local hiddenMove, hiddenError = ViewModel.moveIntent(state, "hidden-item", 8)
	harness:equal(hiddenMove, nil, "unprojected inventory item creates no action")
	harness:equal(hiddenError, "NOT_PROJECTED", "negative disclosure is explicit internally")

	local editMine = ViewModel.editDocumentIntent(state, "mine", "수정", "본문 2", 8)
	harness:expect(editMine ~= nil, "owner can create a journal edit intent")
	local editParty, editPartyError = ViewModel.editDocumentIntent(state, "party", "침범", "", 8)
	harness:equal(editParty, nil, "projected party document does not imply edit authority")
	harness:equal(editPartyError, "PERMISSION_DENIED", "journal edit denial is explicit")
	local hiddenDocument, hiddenDocumentError =
		ViewModel.editDocumentIntent(state, "secret", "", "", 8)
	harness:equal(hiddenDocument, nil, "unprojected journal document has no hidden placeholder")
	harness:equal(
		hiddenDocumentError,
		"NOT_PROJECTED",
		"hidden document stays outside the view model"
	)
	local create = ViewModel.createDocumentIntent(state, "새 기록", "내용", 8)
	harness:expect(
		create ~= nil and create.payload.visibility == "private",
		"new journal document defaults to private"
	)

	local preserved = ViewModel.build(payload, 101, "hero", 9, {
		itemId = "owned",
		documentId = "party",
	})
	harness:equal(preserved.selectedItemId, "owned", "projection refresh preserves item selection")
	harness:equal(
		preserved.selectedDocumentId,
		"party",
		"projection refresh preserves document selection"
	)

	local conflicts = Preferences.bindingConflicts({
		Confirm = "keyboard-e",
		Interact = "keyboard-e",
		Cancel = "keyboard-q",
	})
	harness:equal(#conflicts, 1, "binding conflict presentation groups duplicate bindings")
	harness:equal(
		conflicts[1].bindingId,
		"keyboard-e",
		"binding conflict names the occupied binding"
	)
	harness:equal(
		Preferences.nextMotion("full"),
		"reduced",
		"motion preference cycles through supported values"
	)
	local adjusted, scale = Preferences.adjust("uiScale", 1.4, 0.1)
	harness:expect(adjusted, "numeric preference adjustment uses the schema")
	harness:equal(scale, 1.4, "numeric preference adjustment remains clamped")
end
