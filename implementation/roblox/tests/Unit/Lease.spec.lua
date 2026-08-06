--!strict

return function(harness: any)
	local Server = game:GetService("ServerScriptService").RVTT.Server
	local Diagnostics = require(Server.Runtime.Diagnostics)
	local LeaseCoordinator = require(Server.Persistence.LeaseCoordinator)
	local LeaseStore = require(Server.Persistence.LeaseStore)

	local FakeDataStore = {}
	FakeDataStore.__index = FakeDataStore

	function FakeDataStore.new(): any
		return setmetatable({ value = nil, fail = false }, FakeDataStore)
	end

	function FakeDataStore.UpdateAsync(self: any, _key: string, transform: (any) -> any): any
		if self.fail then
			error("forced datastore failure")
		end
		local nextValue = transform(self.value)
		if nextValue ~= nil then
			self.value = nextValue
		end
		return self.value
	end

	function FakeDataStore.GetAsync(self: any, _key: string): any
		if self.fail then
			error("forced datastore failure")
		end
		return self.value
	end

	local now = 100
	local function clock(): number
		return now
	end

	local dataStore = FakeDataStore.new()
	local store = LeaseStore.new("unused", Diagnostics.new(), dataStore)
	local holder = LeaseCoordinator.new(store, "campaign", "server-a", 10, Diagnostics.new(), clock)
	local contender =
		LeaseCoordinator.new(store, "campaign", "server-b", 10, Diagnostics.new(), clock)

	local acquired = holder:acquire()
	harness:expect(acquired.ok, "first server acquires an empty lease")
	harness:equal(holder:fencingToken(), 1, "first acquisition receives fencing token one")

	local blocked = contender:acquire()
	harness:expect(not blocked.ok, "second server cannot acquire an active lease")
	if not blocked.ok then
		harness:equal(blocked.error.code, "LEASE_HELD", "active owner returns LEASE_HELD")
		harness:expect(blocked.error.retryable, "active lease conflict is retryable")
	end

	now = 104
	local renewed = holder:renew()
	harness:expect(renewed.ok, "current owner renews before expiry")
	harness:equal(holder:fencingToken(), 1, "renewal preserves the fencing token")
	harness:equal(holder:expiresAt(), 114, "renewal advances the expiry")

	local verified = holder:verify()
	harness:expect(verified.ok, "current owner verifies the authoritative lease")

	now = 115
	local takeover = contender:acquire()
	harness:expect(takeover.ok, "contender acquires after expiry")
	harness:equal(contender:fencingToken(), 2, "takeover increments the fencing token")

	local staleRenew = holder:renew()
	harness:expect(not staleRenew.ok, "expired previous owner cannot renew after takeover")
	if not staleRenew.ok then
		harness:equal(staleRenew.error.code, "LEASE_LOST", "stale owner receives LEASE_LOST")
	end
	harness:equal(holder:fencingToken(), nil, "stale owner clears its local lease record")

	local contenderVerified = contender:verify()
	harness:expect(contenderVerified.ok, "new owner verifies the takeover lease")
	local released = contender:release()
	harness:expect(released.ok, "current owner releases the lease")

	local reacquired = holder:acquire()
	harness:expect(reacquired.ok, "previous owner can acquire after release")
	harness:equal(holder:fencingToken(), 3, "release and reacquire increments fencing token")

	dataStore.fail = true
	local failedRead = holder:verify()
	harness:expect(not failedRead.ok, "datastore outage is surfaced during verification")
	if not failedRead.ok then
		harness:equal(
			failedRead.error.code,
			"PERSISTENCE_FAILED",
			"lease datastore outage uses persistence failure code"
		)
		harness:expect(failedRead.error.retryable, "lease datastore outage remains retryable")
	end
end
