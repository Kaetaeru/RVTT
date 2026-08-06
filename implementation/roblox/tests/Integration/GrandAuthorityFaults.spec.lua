--!strict

return function(harness: any)
	local ScenarioRuntime = require(script.Parent.ScenarioRuntime)
	local scenario = ScenarioRuntime.new(1601, "dm")
	local initial = scenario:snapshot()

	local join = scenario:execute("session.join", {})
	local joinOutcome =
		scenario:expectOutcome(harness, join, "Grand fault scenario creates an initial revision")
	if joinOutcome == nil then
		return
	end
	local current = scenario:snapshot()
	harness:expect(
		current.revision == initial.revision + 1,
		"successful command advances revision once"
	)

	local staleRevision = scenario:executeAtAuthority(
		"session.ready",
		{ ready = true },
		initial.revision,
		current.authorityEpoch,
		"grand-fault:stale-revision"
	)
	harness:expect(not staleRevision.ok, "stale revision command is rejected")
	if not staleRevision.ok then
		harness:equal(
			staleRevision.error.code,
			"STALE_REVISION",
			"stale revision has a stable error code"
		)
		harness:expect(staleRevision.error.retryable == true, "stale revision is retryable")
		harness:expect(
			staleRevision.error.details ~= nil
				and staleRevision.error.details.revision == current.revision,
			"stale revision reports the current revision"
		)
	end
	harness:equal(
		scenario:snapshot().revision,
		current.revision,
		"stale revision does not mutate authority state"
	)

	local staleEpoch = scenario:executeAtAuthority(
		"session.ready",
		{ ready = true },
		current.revision,
		"epoch:stale-grand",
		"grand-fault:stale-epoch"
	)
	harness:expect(not staleEpoch.ok, "stale authority epoch command is rejected")
	if not staleEpoch.ok then
		harness:equal(staleEpoch.error.code, "STALE_EPOCH", "stale epoch has a stable error code")
		harness:expect(
			staleEpoch.error.retryable == false,
			"stale epoch requires a full authority refresh"
		)
	end
	harness:equal(
		scenario:snapshot().revision,
		current.revision,
		"stale epoch does not mutate authority state"
	)

	local invalidPayload = scenario:execute("session.ready", { ready = "yes" })
	harness:expect(not invalidPayload.ok, "invalid payload shape is rejected")
	if not invalidPayload.ok then
		harness:equal(
			invalidPayload.error.code,
			"VALIDATION_FAILED",
			"invalid payload has a stable error code"
		)
	end

	local duplicateCommandId = "grand-fault:duplicate"
	local first = scenario:executeDuplicate(duplicateCommandId, "session.ready", { ready = true })
	local second = scenario:executeDuplicate(duplicateCommandId, "session.ready", { ready = false })
	harness:expect(first.ok and second.ok, "duplicate command returns its terminal result")
	if first.ok and second.ok then
		harness:equal(
			second.value.revision,
			first.value.revision,
			"duplicate command does not add a revision"
		)
		harness:equal(
			second.value.outcome.ready,
			first.value.outcome.ready,
			"duplicate command ignores conflicting replay payload"
		)
	end

	local beforeCorruptRestore = scenario:snapshot()
	local corruptRestore = scenario:restore({
		schemaVersion = -1,
		revision = 0,
		domains = {},
	})
	harness:expect(not corruptRestore.ok, "corrupt snapshot restore is rejected")
	if not corruptRestore.ok then
		harness:equal(
			corruptRestore.error.code,
			"MIGRATION_FAILED",
			"corrupt restore has a stable migration error"
		)
	end
	harness:equal(
		scenario:snapshot().revision,
		beforeCorruptRestore.revision,
		"failed restore preserves the current runtime"
	)

	local persisted = scenario:snapshot()
	local previousEpoch = persisted.authorityEpoch
	local restore = scenario:restore(persisted)
	harness:expect(restore.ok, "valid snapshot restores after fault cases")
	if not restore.ok then
		return
	end
	local restored = scenario:snapshot()
	harness:equal(restored.revision, persisted.revision, "valid restore preserves revision")
	harness:expect(
		restored.authorityEpoch ~= previousEpoch,
		"valid restore refreshes authority epoch"
	)

	local oldEpochCommand = scenario:executeAtAuthority(
		"session.ready",
		{ ready = false },
		restored.revision,
		previousEpoch,
		"grand-fault:old-epoch-after-restore"
	)
	harness:expect(not oldEpochCommand.ok, "pre-restore epoch is invalid after recovery")
	if not oldEpochCommand.ok then
		harness:equal(
			oldEpochCommand.error.code,
			"STALE_EPOCH",
			"old epoch is rejected after restore"
		)
	end
end
