--!strict

return function(harness: any)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Server = game:GetService("ServerScriptService").RVTT.Server
	local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)
	local Diagnostics = require(Server.Runtime.Diagnostics)
	local PersistenceCoordinator = require(Server.Persistence.PersistenceCoordinator)

	local function state(revision: number): any
		return {
			schemaVersion = 1,
			revision = revision,
			authorityEpoch = "retry-epoch",
			domains = {},
		}
	end

	local retryStore = {
		attempts = 0,
	}
	function retryStore:load(_key: string): any
		return Result.ok(nil)
	end
	function retryStore:save(_key: string, _value: any): any
		self.attempts += 1
		if self.attempts < 3 then
			return Result.err("PERSISTENCE_FAILED", "error.persistence.failed", true)
		end
		return Result.ok(true)
	end

	local retryCoordinator = PersistenceCoordinator.new(retryStore, "retry", Diagnostics.new())
	harness:expect(
		retryCoordinator:markDirty(state(1), false),
		"retry test marks a shutdown-only snapshot dirty"
	)
	local recovered = retryCoordinator:flushUntilClean({
		maxAttempts = 3,
		initialDelaySeconds = 0,
		maxDelaySeconds = 0,
		deadlineSeconds = 1,
	})
	harness:expect(recovered.ok, "retryable persistence failure recovers within the attempt budget")
	harness:equal(retryStore.attempts, 3, "retry policy performs the bounded number of attempts")
	harness:expect(retryCoordinator.dirty == nil, "successful retry clears dirty state")
	harness:equal(retryCoordinator.lastSavedRevision, 1, "successful retry advances saved revision")

	local terminalStore = {
		attempts = 0,
	}
	function terminalStore:load(_key: string): any
		return Result.ok(nil)
	end
	function terminalStore:save(_key: string, _value: any): any
		self.attempts += 1
		return Result.err("PERSISTENCE_INVALID", "error.persistence.invalid", false)
	end

	local terminalCoordinator =
		PersistenceCoordinator.new(terminalStore, "terminal", Diagnostics.new())
	terminalCoordinator:markDirty(state(2), false)
	local terminal = terminalCoordinator:flushUntilClean({
		maxAttempts = 5,
		initialDelaySeconds = 0,
		maxDelaySeconds = 0,
		deadlineSeconds = 1,
	})
	harness:expect(not terminal.ok, "non-retryable persistence failure is returned")
	harness:equal(terminalStore.attempts, 1, "non-retryable failure stops immediately")
	harness:expect(terminalCoordinator.dirty ~= nil, "terminal failure preserves dirty state")

	local exhaustedStore = {
		attempts = 0,
	}
	function exhaustedStore:load(_key: string): any
		return Result.ok(nil)
	end
	function exhaustedStore:save(_key: string, _value: any): any
		self.attempts += 1
		return Result.err("PERSISTENCE_FAILED", "error.persistence.failed", true)
	end

	local exhaustedCoordinator =
		PersistenceCoordinator.new(exhaustedStore, "exhausted", Diagnostics.new())
	exhaustedCoordinator:markDirty(state(3), false)
	local exhausted = exhaustedCoordinator:flushUntilClean({
		maxAttempts = 2,
		initialDelaySeconds = 0,
		maxDelaySeconds = 0,
		deadlineSeconds = 1,
	})
	harness:expect(not exhausted.ok, "retryable failure is returned after attempts are exhausted")
	harness:equal(exhaustedStore.attempts, 2, "retry exhaustion respects the maximum attempt count")
	harness:expect(exhaustedCoordinator.dirty ~= nil, "retry exhaustion preserves dirty state")
end
