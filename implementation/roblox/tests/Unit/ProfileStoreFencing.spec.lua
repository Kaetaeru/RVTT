--!strict

return function(harness: any)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Server = game:GetService("ServerScriptService").RVTT.Server
	local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)
	local ProfileStore = require(Server.Persistence.ProfileStore)

	local diagnostics: any = { incidents = {} }
	function diagnostics:record(level: string, code: string, context: any)
		table.insert(self.incidents, { level = level, code = code, context = context })
	end

	local migrations = {}
	function migrations:apply(document: any): any
		return Result.ok(document)
	end

	local fakeStore: any = { value = nil, updateCalls = 0 }
	function fakeStore:GetAsync(_key: string): any
		return self.value
	end
	function fakeStore:UpdateAsync(_key: string, transform: any): any
		self.updateCalls += 1
		local nextValue = transform(self.value)
		if nextValue ~= nil then
			self.value = nextValue
		end
		return self.value
	end

	local store = ProfileStore.new("unused", migrations, diagnostics, fakeStore)
	local fenceOne = {
		ownerId = "server-a",
		token = "lease-a",
		fencingToken = 1,
	}
	local first = store:save("campaign", {
		schemaVersion = 1,
		revision = 5,
		authorityEpoch = "epoch:a",
		domains = {},
	}, fenceOne)
	harness:expect(first.ok, "first fenced document saves")
	harness:equal(
		fakeStore.value.persistenceFence.fencingToken,
		1,
		"backing document records the first fencing token"
	)

	local loaded = store:load("campaign")
	harness:expect(loaded.ok, "fenced document loads")
	if loaded.ok then
		harness:equal(loaded.value.revision, 5, "load preserves the authority revision")
		harness:expect(
			loaded.value.persistenceFence == nil,
			"load strips persistence metadata from authority state"
		)
	end

	local sameOwner = store:save("campaign", {
		schemaVersion = 1,
		revision = 6,
		authorityEpoch = "epoch:a",
		domains = {},
	}, fenceOne)
	harness:expect(sameOwner.ok, "same lease identity advances the revision")

	local sameFenceIntruder = store:save("campaign", {
		schemaVersion = 1,
		revision = 7,
		authorityEpoch = "epoch:intruder",
		domains = {},
	}, {
		ownerId = "server-b",
		token = "lease-b",
		fencingToken = 1,
	})
	harness:expect(
		not sameFenceIntruder.ok and sameFenceIntruder.error.code == "PERSISTENCE_FENCED",
		"same fencing token with another identity is rejected"
	)

	local fenceTwo = {
		ownerId = "server-b",
		token = "lease-b",
		fencingToken = 2,
	}
	local takeover = store:save("campaign", {
		schemaVersion = 1,
		revision = 5,
		authorityEpoch = "epoch:b",
		domains = {},
	}, fenceTwo)
	harness:expect(
		takeover.ok,
		"higher fencing token supersedes a stale higher revision and epoch"
	)
	harness:equal(fakeStore.value.revision, 5, "takeover stores the new owner snapshot")
	harness:equal(
		fakeStore.value.persistenceFence.fencingToken,
		2,
		"takeover stores the higher fencing token"
	)

	local delayedOldOwner = store:save("campaign", {
		schemaVersion = 1,
		revision = 99,
		authorityEpoch = "epoch:a",
		domains = {},
	}, fenceOne)
	harness:expect(
		not delayedOldOwner.ok and delayedOldOwner.error.code == "PERSISTENCE_FENCED",
		"delayed previous owner cannot overwrite with a larger revision"
	)
	harness:equal(fakeStore.value.revision, 5, "rejected stale write does not mutate backing state")

	local unfenced = store:save("campaign", {
		schemaVersion = 1,
		revision = 100,
		authorityEpoch = "epoch:legacy",
		domains = {},
	})
	harness:expect(
		not unfenced.ok and unfenced.error.code == "PERSISTENCE_FENCED",
		"unfenced writer cannot overwrite a fenced document"
	)

	local lowerRevisionSameFence = store:save("campaign", {
		schemaVersion = 1,
		revision = 4,
		authorityEpoch = "epoch:b",
		domains = {},
	}, fenceTwo)
	harness:expect(
		not lowerRevisionSameFence.ok
			and lowerRevisionSameFence.error.code == "PERSISTENCE_CONFLICT",
		"same owner still obeys monotonic revision rules"
	)

	fakeStore.value = {
		schemaVersion = 1,
		revision = 5,
		authorityEpoch = "epoch:b",
		domains = {},
		persistenceFence = { fencingToken = "broken" },
	}
	local invalidFence = store:load("campaign")
	harness:expect(
		not invalidFence.ok and invalidFence.error.code == "PERSISTENCE_INVALID",
		"invalid stored fencing metadata fails closed"
	)
end
