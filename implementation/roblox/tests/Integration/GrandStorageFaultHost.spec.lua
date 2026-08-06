--!strict

local function state(revision: number, epoch: string, marker: string): any
	return {
		schemaVersion = 1,
		revision = revision,
		authorityEpoch = epoch,
		domains = { fault = { marker = marker } },
	}
end

return function(harness: any)
	local Server = game:GetService("ServerScriptService").RVTT.Server
	local Diagnostics = require(Server.Runtime.Diagnostics)
	local PersistenceCoordinator = require(Server.Persistence.PersistenceCoordinator)
	local FaultStore = require(script.Parent.FaultStore)

	local key = "grand-storage-fault"
	local store = FaultStore.new({
		[key] = state(3, "epoch-a", "initial"),
	})
	local diagnostics = Diagnostics.new()
	local coordinator = PersistenceCoordinator.new(store, key, diagnostics)

	store:queue("load", {
		kind = "fail",
		code = "PERSISTENCE_FAILED",
		retryable = true,
	})
	local failedLoad = coordinator:load()
	harness:expect(not failedLoad.ok, "transient load failure is surfaced")
	if not failedLoad.ok then
		harness:equal(failedLoad.error.code, "PERSISTENCE_FAILED", "load failure code is explicit")
		harness:expect(failedLoad.error.retryable, "transient load failure is retryable")
	end
	harness:equal(coordinator.lastSavedRevision, -1, "failed load does not advance saved revision")

	local loaded = coordinator:load()
	harness:expect(loaded.ok, "load retry succeeds after transient failure")
	harness:equal(coordinator.lastSavedRevision, 3, "successful load records the stored revision")

	harness:expect(
		coordinator:markDirty(state(4, "epoch-a", "before-write")),
		"newer revision becomes dirty"
	)
	store:queue("save", {
		kind = "fail",
		code = "PERSISTENCE_FAILED",
		retryable = true,
	})
	local failedSave = coordinator:flush()
	harness:expect(not failedSave.ok, "pre-commit storage failure is surfaced")
	harness:equal(coordinator.dirty.revision, 4, "pre-commit failure preserves dirty state")
	harness:equal(
		store:document(key).revision,
		3,
		"pre-commit failure does not mutate stored state"
	)

	local retriedSave = coordinator:flush()
	harness:expect(retriedSave.ok, "pre-commit failure succeeds on retry")
	harness:expect(coordinator.dirty == nil, "successful retry clears dirty state")
	harness:equal(coordinator.lastSavedRevision, 4, "successful retry advances saved revision")
	harness:equal(
		store:document(key).domains.fault.marker,
		"before-write",
		"retry commits the intended state"
	)

	harness:expect(
		coordinator:markDirty(state(5, "epoch-a", "ack-lost")),
		"ack-loss revision becomes dirty"
	)
	store:queue("save", {
		kind = "commit_then_fail",
		code = "PERSISTENCE_FAILED",
		retryable = true,
	})
	local lostAck = coordinator:flush()
	harness:expect(not lostAck.ok, "committed write with lost acknowledgement is surfaced")
	harness:equal(
		store:document(key).revision,
		5,
		"ack-loss fault commits the authoritative document"
	)
	harness:equal(coordinator.dirty.revision, 5, "ack-loss fault keeps the snapshot retryable")

	local idempotentRetry = coordinator:flush()
	harness:expect(idempotentRetry.ok, "same revision and epoch retry is idempotent")
	harness:expect(coordinator.dirty == nil, "idempotent retry clears dirty state")
	harness:equal(
		coordinator.lastSavedRevision,
		5,
		"idempotent retry records the committed revision"
	)

	harness:expect(
		coordinator:markDirty(state(6, "epoch-a", "conflicted")),
		"conflict candidate becomes dirty"
	)
	store:queue("save", {
		kind = "conflict",
		code = "PERSISTENCE_CONFLICT",
		retryable = true,
	})
	local injectedConflict = coordinator:flush()
	harness:expect(not injectedConflict.ok, "injected revision conflict is surfaced")
	if not injectedConflict.ok then
		harness:equal(
			injectedConflict.error.code,
			"PERSISTENCE_CONFLICT",
			"conflict code is explicit"
		)
	end
	harness:equal(coordinator.dirty.revision, 6, "conflict preserves the unsaved candidate")
	harness:equal(store:document(key).revision, 5, "conflict does not overwrite the stored winner")

	store:put(key, state(7, "epoch-external", "external-winner"))
	local staleRetry = coordinator:flush()
	harness:expect(not staleRetry.ok, "stale retry loses to a newer external revision")
	if not staleRetry.ok then
		harness:equal(
			staleRetry.error.code,
			"PERSISTENCE_CONFLICT",
			"external winner returns conflict"
		)
	end
	harness:equal(
		store:document(key).domains.fault.marker,
		"external-winner",
		"stale retry preserves external winner"
	)

	harness:expect(
		coordinator:markDirty(state(8, "epoch-a", "reconciled")),
		"reconciled newer state replaces stale dirty state"
	)
	local reconciled = coordinator:flush()
	harness:expect(reconciled.ok, "revision above external winner commits")
	harness:expect(coordinator.dirty == nil, "reconciled save clears dirty state")
	harness:equal(coordinator.lastSavedRevision, 8, "reconciled save advances saved revision")
	harness:equal(
		store:document(key).domains.fault.marker,
		"reconciled",
		"reconciled state becomes authoritative"
	)

	store:queue("load", {
		kind = "value",
		value = { revision = "corrupt" },
	})
	local corruptCoordinator = PersistenceCoordinator.new(store, key, Diagnostics.new())
	local corruptLoad = corruptCoordinator:load()
	harness:expect(corruptLoad.ok, "store-level corrupt value is returned for runtime validation")
	harness:equal(
		corruptCoordinator.lastSavedRevision,
		-1,
		"invalid loaded revision is never marked saved"
	)

	local metrics = store:metricsSnapshot()
	print(
		string.format(
			"[RVTT Fault Host] kind=storage loads=%d saves=%d failures=%d conflicts=%d committed=%d ackLosses=%d finalRevision=%d",
			metrics.loads,
			metrics.saves,
			metrics.failures,
			metrics.conflicts,
			metrics.committedWrites,
			metrics.commitAckLosses,
			store:document(key).revision
		)
	)
end
