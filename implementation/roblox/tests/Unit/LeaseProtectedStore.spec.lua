--!strict

return function(harness: any)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Server = game:GetService("ServerScriptService").RVTT.Server
	local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)
	local LeaseProtectedStore = require(Server.Persistence.LeaseProtectedStore)

	local diagnostics: any = { counters = {} }
	function diagnostics:increment(key: string)
		self.counters[key] = (self.counters[key] or 0) + 1
	end

	local ownership: any = {
		verifyResult = Result.ok(true),
		fenceResult = Result.ok({
			ownerId = "server-a",
			token = "lease-a",
			fencingToken = 1,
		}),
		verifyCalls = 0,
		fenceCalls = 0,
	}
	function ownership:verifyRemote(): any
		self.verifyCalls += 1
		return self.verifyResult
	end
	function ownership:writeFence(): any
		self.fenceCalls += 1
		return self.fenceResult
	end

	local delegate: any = {
		loadCalls = 0,
		saveCalls = 0,
		lastFence = nil,
		lastInitialDocument = nil,
	}
	function delegate:loadFenced(_key: string, initialDocument: any, fence: any): any
		self.loadCalls += 1
		self.lastInitialDocument = initialDocument
		self.lastFence = fence
		return Result.ok(initialDocument)
	end
	function delegate:save(_key: string, _value: any, fence: any): any
		self.saveCalls += 1
		self.lastFence = fence
		return Result.ok(true)
	end

	local initialDocument = {
		schemaVersion = 1,
		revision = 0,
		authorityEpoch = "epoch:initial",
		domains = {},
	}
	local store = LeaseProtectedStore.new(delegate, ownership, diagnostics, initialDocument)
	local loaded = store:load("campaign")
	harness:expect(loaded.ok, "verified ownership permits fenced load")
	harness:equal(delegate.loadCalls, 1, "permitted load reaches the fenced delegate")
	harness:equal(
		delegate.lastInitialDocument.revision,
		0,
		"fenced load forwards the initial authority document"
	)
	harness:equal(delegate.lastFence.fencingToken, 1, "fenced load forwards the active write fence")

	local saved = store:save("campaign", { revision = 1 })
	harness:expect(saved.ok, "verified ownership permits save")
	harness:equal(delegate.saveCalls, 1, "permitted save reaches the delegate")
	harness:equal(delegate.lastFence.fencingToken, 1, "save forwards the active write fence")

	ownership.verifyResult = Result.err("LEASE_LOST", "error.persistence.lease_lost", false)
	local blockedLoad = store:load("campaign")
	harness:expect(
		not blockedLoad.ok and blockedLoad.error.code == "LEASE_LOST",
		"lost lease blocks load"
	)
	harness:equal(delegate.loadCalls, 1, "blocked load does not reach the delegate")

	local blockedSave = store:save("campaign", { revision = 2 })
	harness:expect(
		not blockedSave.ok and blockedSave.error.code == "LEASE_LOST",
		"lost lease blocks save"
	)
	harness:equal(delegate.saveCalls, 1, "blocked save does not reach the delegate")

	ownership.verifyResult = Result.ok(true)
	ownership.fenceResult = Result.err("LEASE_NOT_HELD", "error.persistence.lease_not_held", false)
	local missingFenceLoad = store:load("campaign")
	harness:expect(
		not missingFenceLoad.ok and missingFenceLoad.error.code == "LEASE_NOT_HELD",
		"missing fence blocks delegate load"
	)
	harness:equal(delegate.loadCalls, 1, "missing load fence never reaches the delegate")

	local missingFenceSave = store:save("campaign", { revision = 3 })
	harness:expect(
		not missingFenceSave.ok and missingFenceSave.error.code == "LEASE_NOT_HELD",
		"missing fence blocks delegate save"
	)
	harness:equal(delegate.saveCalls, 1, "missing save fence never reaches the delegate")
end
