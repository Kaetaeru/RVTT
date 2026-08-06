--!strict

return function(harness)
	local ScenarioRuntime = require(script.Parent.ScenarioRuntime)
	local scenario = ScenarioRuntime.new(606, "dm")
	local heroId = scenario:bootstrapCharacter(harness, "Slice 06 Hero", "scene:slice-06", nil)
	if heroId == nil then
		return
	end

	local item = scenario:execute("inventory.create_item", {
		definitionId = "item:test-sword",
		quantity = 20000,
		location = {
			kind = "ground",
			ownerUserId = 606,
			position = { x = 2, y = 0, z = 3 },
		},
	})
	local itemOutcome = scenario:expectOutcome(harness, item, "Slice 06 creates a ground item")
	if itemOutcome == nil then
		return
	end
	local itemId = itemOutcome.item.id
	harness:equal(
		itemOutcome.item.definitionId,
		"item:test-sword",
		"item keeps its stable definition reference"
	)
	harness:equal(itemOutcome.item.quantity, 9999, "item quantity is clamped to the server maximum")
	harness:equal(itemOutcome.item.revision, 1, "new item starts at revision one")
	harness:equal(itemOutcome.location.kind, "ground", "new item starts on the ground")

	local deniedCreate = scenario:executeAs("player", 606, "inventory.create_item", {
		definitionId = "item:forged",
		location = { kind = "ground" },
	})
	harness:expect(not deniedCreate.ok, "player cannot create an authoritative item")
	if not deniedCreate.ok then
		harness:equal(deniedCreate.error.code, "UNAUTHORIZED", "item creation denial is explicit")
	end

	local deniedPickup = scenario:executeAs("player", 999, "inventory.move_item", {
		itemId = itemId,
		location = { kind = "inventory", characterId = heroId },
	})
	harness:expect(
		not deniedPickup.ok,
		"non-owner cannot pick up another user's reserved ground item"
	)
	if not deniedPickup.ok then
		harness:equal(deniedPickup.error.code, "UNAUTHORIZED", "item ownership denial is explicit")
	end

	local pickup = scenario:executeAs("player", 606, "inventory.move_item", {
		itemId = itemId,
		location = { kind = "inventory", characterId = heroId },
	})
	local pickupOutcome =
		scenario:expectOutcome(harness, pickup, "Slice 06 moves the item into inventory")
	if pickupOutcome == nil then
		return
	end
	harness:equal(pickupOutcome.item.revision, 2, "pickup increments item revision")
	harness:equal(pickupOutcome.location.kind, "inventory", "pickup creates an inventory location")
	harness:equal(
		pickupOutcome.location.characterId,
		heroId,
		"inventory location is bound to the character"
	)
	harness:equal(
		scenario:snapshot().domains.inventory.locations[itemId].kind,
		"inventory",
		"item has one authoritative location after pickup"
	)

	local deniedEquip = scenario:executeAs("player", 999, "inventory.equip", {
		itemId = itemId,
		characterId = heroId,
		slot = "main-hand",
	})
	harness:expect(not deniedEquip.ok, "non-owner cannot equip another character's item")
	if not deniedEquip.ok then
		harness:equal(deniedEquip.error.code, "UNAUTHORIZED", "equip ownership denial is explicit")
	end

	local equip = scenario:executeAs("player", 606, "inventory.equip", {
		itemId = itemId,
		characterId = heroId,
		slot = "main-hand",
	})
	local equipOutcome = scenario:expectOutcome(harness, equip, "Slice 06 equips the owned item")
	if equipOutcome == nil then
		return
	end
	harness:equal(equipOutcome.item.revision, 3, "equip increments item revision")
	harness:equal(equipOutcome.location.kind, "equipped", "equipped item has equipped location")
	harness:equal(equipOutcome.location.slot, "main-hand", "equipped item keeps the selected slot")

	local invalidMove = scenario:execute("inventory.move_item", {
		itemId = itemId,
		location = { kind = "container", containerId = "container:test" },
	})
	harness:expect(not invalidMove.ok, "unsupported item location is rejected")
	if not invalidMove.ok then
		harness:equal(
			invalidMove.error.code,
			"VALIDATION_FAILED",
			"unsupported location uses validation error"
		)
	end
	harness:equal(
		scenario:snapshot().domains.inventory.locations[itemId].kind,
		"equipped",
		"rejected move preserves the previous location"
	)

	local drop = scenario:execute("inventory.move_item", {
		itemId = itemId,
		location = {
			kind = "ground",
			position = { x = 10, y = 0, z = 8 },
		},
	})
	local dropOutcome =
		scenario:expectOutcome(harness, drop, "Slice 06 drops the item back into the world")
	if dropOutcome == nil then
		return
	end
	harness:equal(dropOutcome.item.revision, 4, "drop increments item revision")
	harness:equal(dropOutcome.location.kind, "ground", "drop restores ground presence")
	harness:equal(
		dropOutcome.location.position.x,
		10,
		"drop stores the authoritative world position"
	)

	local persisted = scenario:snapshot()
	local restored = ScenarioRuntime.new(606, "dm")
	local restore = restored:restore(persisted)
	harness:expect(restore.ok, "Slice 06 snapshot restores")
	if restore.ok then
		local restoredInventory = restored:snapshot().domains.inventory
		harness:equal(
			restoredInventory.items[itemId].quantity,
			9999,
			"restore preserves item quantity"
		)
		harness:equal(
			restoredInventory.items[itemId].revision,
			4,
			"restore preserves item revision"
		)
		harness:equal(
			restoredInventory.locations[itemId].kind,
			"ground",
			"restore preserves item location"
		)
	end
end
