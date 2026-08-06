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
	}
	function delegate:load(key: string): any
		self.loadCalls += 1
		return Result.ok({ key = key })
	end
	function delegate:save(_key: string, _value: any, fence: any): any
		self.saveCalls += 1
		self.lastFence = fence
		return Result.ok(true)
	end

	local store = LeaseProtectedStore.new(delegate, ownership, diagnostics)
	local loaded = store:load("campaign")
	harness:expect(loaded.ok, "verified ownership permits load")
	harness:equal(delegate.loadCalls, 1, "permitted load reaches the delegate")

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
	ownership.fenceResult = Result.err(
		"LEASE_NOT_HELD",
		"error.persistence.lease_not_held",
		false
	)
	local missingFence = store:save("campaign", { revision = 3 })
	harness:expect(
		not missingFence.ok and missingFence.error.code == "LEASE_NOT_HELD",
		"missing fence blocks delegate save"
	)
	harness:equal(delegate.saveCalls, 1, "missing fence never reaches the delegate")
end
