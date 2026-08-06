--!strict

return function(harness)
	local ScenarioRuntime = require(script.Parent.ScenarioRuntime)
	local scenario = ScenarioRuntime.new(909, "player")

	local document = scenario:execute("journal.create", {
		title = "Slice 09 Journal",
		body = "# Entry\nA stable world note.",
		visibility = "private",
	})
	local documentOutcome =
		scenario:expectOutcome(harness, document, "Slice 09 creates a journal document")
	if documentOutcome == nil then
		return
	end
	local documentId = documentOutcome.id
	harness:equal(documentOutcome.ownerUserId, 909, "journal records the authoritative owner")
	harness:equal(documentOutcome.revision, 1, "new journal starts at revision one")
	harness:equal(documentOutcome.visibility, "private", "journal keeps its visibility")

	local deniedEdit = scenario:executeAs("player", 910, "journal.edit", {
		documentId = documentId,
		title = "Stolen Edit",
	})
	harness:expect(not deniedEdit.ok, "non-owner cannot edit a private journal")
	if not deniedEdit.ok then
		harness:equal(deniedEdit.error.code, "UNAUTHORIZED", "journal ownership denial is explicit")
	end

	local edit = scenario:execute("journal.edit", {
		documentId = documentId,
		title = "Slice 09 Journal Updated",
		body = "# Entry\nUpdated through an authoritative command.",
		links = {
			{ kind = "scene", targetId = "scene:test" },
			{ kind = "coordinate", position = { x = 5, y = 0, z = 7 } },
		},
	})
	local editOutcome = scenario:expectOutcome(harness, edit, "Slice 09 edits the owned journal")
	if editOutcome == nil then
		return
	end
	harness:equal(editOutcome.title, "Slice 09 Journal Updated", "journal title updates")
	harness:equal(editOutcome.revision, 2, "journal edit increments revision")
	harness:equal(#editOutcome.links, 2, "journal stores structured world links")

	local dmEdit = scenario:executeAs("dm", 999, "journal.edit", {
		documentId = documentId,
		body = "# Entry\nReviewed by the DM.",
	})
	local dmEditOutcome =
		scenario:expectOutcome(harness, dmEdit, "Slice 09 allows DM review editing")
	if dmEditOutcome == nil then
		return
	end
	harness:equal(dmEditOutcome.revision, 3, "DM edit increments journal revision")
	harness:equal(
		dmEditOutcome.body,
		"# Entry\nReviewed by the DM.",
		"DM edit commits the reviewed body"
	)

	local invalidPing = scenario:execute("journal.ping", {
		position = { x = math.huge, y = 0, z = 0 },
		label = "Invalid",
	})
	harness:expect(not invalidPing.ok, "invalid ping position is rejected")
	if not invalidPing.ok then
		harness:equal(
			invalidPing.error.code,
			"VALIDATION_FAILED",
			"invalid ping uses validation error"
		)
	end

	local ping = scenario:execute("journal.ping", {
		position = { x = 12, y = 0, z = -4 },
		label = "Investigate",
	})
	local pingOutcome = scenario:expectOutcome(harness, ping, "Slice 09 creates a point ping")
	if pingOutcome == nil then
		return
	end
	harness:equal(pingOutcome.userId, 909, "ping records the authoritative user")
	harness:equal(pingOutcome.position.x, 12, "ping stores the authoritative position")
	harness:equal(pingOutcome.label, "Investigate", "ping stores its bounded label")
	harness:expect(pingOutcome.expiresAt > os.time(), "ping has a future expiration")

	local persisted = scenario:snapshot()
	local restored = ScenarioRuntime.new(909, "player")
	local restore = restored:restore(persisted)
	harness:expect(restore.ok, "Slice 09 journal snapshot restores")
	if restore.ok then
		local restoredJournal = restored:snapshot().domains.journal
		harness:equal(
			restoredJournal.documents[documentId].revision,
			3,
			"restore preserves journal revision"
		)
		harness:equal(
			restoredJournal.documents[documentId].visibility,
			"private",
			"restore preserves visibility"
		)
		harness:expect(
			restoredJournal.pings[pingOutcome.id] ~= nil,
			"restore preserves active ping state"
		)
	end
end
