--!strict

return function(harness: any)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Server = game:GetService("ServerScriptService").RVTT.Server
	local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)
	local LeaseOwnership = require(Server.Persistence.LeaseOwnership)

	local diagnostics: any = { counters = {} }
	function diagnostics:increment(key: string)
		self.counters[key] = (self.counters[key] or 0) + 1
	end

	local coordinator: any = {
		active = false,
		renewResult = Result.ok({ fencingToken = 1 }),
		verifyResult = Result.ok({ fencingToken = 1 }),
	}
	function coordinator:acquire(): any
		self.active = true
		return Result.ok({ fencingToken = 1, expiresAt = 200 })
	end
	function coordinator:validateLocal(): any
		if self.active then
			return Result.ok({ fencingToken = 1, expiresAt = 200 })
		end
		return Result.err("LEASE_NOT_HELD", "error.persistence.lease_not_held", false)
	end
	function coordinator:verify(): any
		return self.verifyResult
	end
	function coordinator:renew(): any
		return self.renewResult
	end
	function coordinator:writeFence(): any
		return Result.ok({
			ownerId = "server-a",
			token = "lease-a",
			fencingToken = 1,
		})
	end
	function coordinator:release(): any
		self.active = false
		return Result.ok(true)
	end

	local ownership = LeaseOwnership.new(coordinator, diagnostics, {
		renewIntervalSeconds = 10,
		retryIntervalSeconds = 1,
	})
	local acquired = ownership:acquire()
	harness:expect(acquired.ok, "ownership acquires the production lease")
	harness:expect(ownership:isActive(), "successful acquisition activates ownership")
	harness:expect(ownership:guardLocal().ok, "active ownership passes local command guard")

	local fenceResult = ownership:writeFence()
	harness:expect(fenceResult.ok, "active ownership exposes a write fence")
	if fenceResult.ok then
		harness:equal(fenceResult.value.fencingToken, 1, "write fence keeps coordinator token")
	end

	coordinator.renewResult = Result.err("PERSISTENCE_FAILED", "error.persistence.failed", true)
	local transientRenew = ownership:renewOnce()
	harness:expect(not transientRenew.ok, "transient renew failure is surfaced")
	harness:expect(
		ownership:isActive(),
		"transient renew failure preserves ownership until local expiry"
	)
	local guardAfterTransient = ownership:guardLocal()
	harness:expect(guardAfterTransient.ok, "commands remain guarded by the unexpired local lease")

	coordinator.renewResult = Result.err("LEASE_LOST", "error.persistence.lease_lost", false)
	local terminalRenew = ownership:renewOnce()
	harness:expect(not terminalRenew.ok, "terminal renew failure is surfaced")
	harness:expect(not ownership:isActive(), "terminal renew failure deactivates ownership")
	local blocked = ownership:guardLocal()
	harness:expect(
		not blocked.ok and blocked.error.code == "LEASE_LOST",
		"lost ownership blocks subsequent commands"
	)

	local secondCoordinator: any = {
		active = false,
	}
	function secondCoordinator:acquire(): any
		self.active = true
		return Result.ok({ fencingToken = 2, expiresAt = 300 })
	end
	function secondCoordinator:validateLocal(): any
		if self.active then
			return Result.ok({ fencingToken = 2, expiresAt = 300 })
		end
		return Result.err("LEASE_NOT_HELD", "error.persistence.lease_not_held", false)
	end
	function secondCoordinator:release(): any
		self.active = false
		return Result.ok(true)
	end
	function secondCoordinator:verify(): any
		return self:validateLocal()
	end
	function secondCoordinator:renew(): any
		return self:validateLocal()
	end
	function secondCoordinator:writeFence(): any
		return Result.ok({
			ownerId = "server-b",
			token = "lease-b",
			fencingToken = 2,
		})
	end

	local shutdownOwnership = LeaseOwnership.new(secondCoordinator, diagnostics)
	harness:expect(shutdownOwnership:acquire().ok, "shutdown case acquires a lease")
	shutdownOwnership:beginShutdown()
	local renewDuringShutdown = shutdownOwnership:renewOnce()
	harness:expect(
		not renewDuringShutdown.ok and renewDuringShutdown.error.code == "LEASE_SHUTTING_DOWN",
		"shutdown prevents another renewal cycle"
	)
	local released = shutdownOwnership:release()
	harness:expect(released.ok, "shutdown releases the current lease")
	harness:expect(not shutdownOwnership:isActive(), "release clears active ownership")
end
