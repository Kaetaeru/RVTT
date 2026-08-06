--!strict

local function countKeys(value: { [any]: any }): number
	local count = 0
	for _ in value do
		count += 1
	end
	return count
end

return function(harness: any)
	local ScenarioRuntime = require(script.Parent.ScenarioRuntime)
	local scenario = ScenarioRuntime.new(1603, "dm")
	local startedAt = os.clock()

	local scene = scenario:execute("authoring.create_scene", {
		name = "Grand Capacity Scene",
	})
	local sceneOutcome = scenario:expectOutcome(harness, scene, "Capacity sample creates a scene source")
	if sceneOutcome == nil then
		return
	end
	local sceneId = sceneOutcome.id

	local objectCount = 32
	for index = 1, objectCount do
		local object = scenario:execute("authoring.upsert_object", {
			sceneId = sceneId,
			object = {
				id = string.format("object:capacity:%03d", index),
				kind = if index % 2 == 0 then "wall" else "floor",
				position = { x = index * 2, y = 0, z = index % 8 },
			},
		})
		if not object.ok then
			harness:expect(false, string.format("capacity scene object %d commits", index))
			return
		end
	end
	local compile = scenario:execute("authoring.compile", { sceneId = sceneId })
	if scenario:expectOutcome(harness, compile, "Capacity sample compiles the large scene source") == nil then
		return
	end

	local itemCount = 32
	for index = 1, itemCount do
		local item = scenario:execute("inventory.create_item", {
			definitionId = string.format("item:capacity:%03d", index),
			quantity = index,
			location = {
				kind = "ground",
				position = { x = index, y = 0, z = -index },
			},
		})
		if not item.ok then
			harness:expect(false, string.format("capacity item %d commits", index))
			return
		end
	end

	local documentCount = 16
	for index = 1, documentCount do
		local document = scenario:executeAs("player", 1603, "journal.create", {
			title = string.format("Capacity Document %03d", index),
			body = string.rep("entry ", 32),
			visibility = if index % 2 == 0 then "campaign" else "private",
		})
		if not document.ok then
			harness:expect(false, string.format("capacity document %d commits", index))
			return
		end
	end

	local snapshot = scenario:snapshot()
	local authoredObjects = snapshot.domains.scene_authoring.sources[sceneId].objects
	local items = snapshot.domains.inventory.items
	local documents = snapshot.domains.journal.documents
	harness:equal(countKeys(authoredObjects), objectCount, "capacity sample preserves every authored object")
	harness:equal(countKeys(items), itemCount, "capacity sample preserves every item")
	harness:equal(countKeys(documents), documentCount, "capacity sample preserves every journal document")

	local restored = ScenarioRuntime.new(1603, "dm")
	local restoreStartedAt = os.clock()
	local restore = restored:restore(snapshot)
	local restoreElapsedMs = (os.clock() - restoreStartedAt) * 1000
	harness:expect(restore.ok, "capacity sample snapshot restores")
	if restore.ok then
		local restoredDomains = restored:snapshot().domains
		harness:equal(
			countKeys(restoredDomains.scene_authoring.sources[sceneId].objects),
			objectCount,
			"capacity restore preserves authored objects"
		)
		harness:equal(countKeys(restoredDomains.inventory.items), itemCount, "capacity restore preserves items")
		harness:equal(
			countKeys(restoredDomains.journal.documents),
			documentCount,
			"capacity restore preserves documents"
		)
	end

	local elapsedMs = (os.clock() - startedAt) * 1000
	print(string.format(
		"[RVTT Capacity Sample] objects=%d items=%d documents=%d revision=%d elapsedMs=%.3f restoreMs=%.3f",
		objectCount,
		itemCount,
		documentCount,
		snapshot.revision,
		elapsedMs,
		restoreElapsedMs
	))
end
