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
	local fenceTwo = {
		ownerId = "server-b",
		token = "lease-b",
		fencingToken = 2,
	}
	local initialDocument = {
		schemaVersion = 1,
		revision = 0,
		authorityEpoch = "epoch:initial",
		domains = {},
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

	local claimed = store:loadFenced("campaign", initialDocument, fenceTwo)
	harness:expect(claimed.ok, "higher fencing token atomically claims the existing document")
	if claimed.ok then
		harness:equal(claimed.value.revision, 6, "fence claim preserves the latest stored revision")
		harness:equal(claimed.value.authorityEpoch, "epoch:a", "fence claim preserves stored state")
		harness:expect(
			claimed.value.persistenceFence == nil,
			"claimed load strips persistence metadata from authority state"
		)
	end
	harness:equal(
		fakeStore.value.persistenceFence.fencingToken,
		2,
		"fence claim updates backing ownership before returning the document"
	)

	local delayedOldOwner = store:save("campaign", {
		schemaVersion = 1,
		revision = 99,
		authorityEpoch = "epoch:a",
		domains = {},
	}, fenceOne)
	harness:expect(
		not delayedOldOwner.ok and delayedOldOwner.error.code == "PERSISTENCE_FENCED",
		"claim blocks a delayed previous owner even with a larger revision"
	)
	harness:equal(fakeStore.value.revision, 6, "rejected stale write does not mutate backing state")

	local unfenced = store:save("campaign", {
		schemaVersion = 1,
		revision = 100,
		authorityEpoch = "epoch:legacy",
		domains = {},
	})
	harness:expect(
		not unfenced.ok and unfenced.error.code == "PERSISTENCE_FENCED",
		"unfenced writer cannot overwrite a claimed document"
	)

	local lowerRevisionSameFence = store:save("campaign", {
		schemaVersion = 1,
		revision = 5,
		authorityEpoch = "epoch:a",
		domains = {},
	}, fenceTwo)
	harness:expect(
		not lowerRevisionSameFence.ok
			and lowerRevisionSameFence.error.code == "PERSISTENCE_CONFLICT",
		"current owner still obeys monotonic revision rules"
	)

	local lowerFenceClaim = store:loadFenced("campaign", initialDocument, fenceOne)
	harness:expect(
		not lowerFenceClaim.ok and lowerFenceClaim.error.code == "PERSISTENCE_FENCED",
		"lower fencing token cannot reclaim the authority document"
	)

	local currentOwnerSave = store:save("campaign", {
		schemaVersion = 1,
		revision = 7,
		authorityEpoch = "epoch:b",
		domains = {},
	}, fenceTwo)
	harness:expect(currentOwnerSave.ok, "claimed owner advances revision under a new epoch")

	fakeStore.value = nil
	local created = store:loadFenced("campaign", initialDocument, fenceOne)
	harness:expect(created.ok, "fenced load creates an initial document when none exists")
	if created.ok then
		harness:equal(
			created.value.revision,
			0,
			"initial fence claim returns the baseline revision"
		)
	end
	harness:equal(
		fakeStore.value.persistenceFence.fencingToken,
		1,
		"initial document is created with the active fencing token"
	)

	fakeStore.value = {
		schemaVersion = 1,
		revision = 5,
		authorityEpoch = "epoch:b",
		domains = {},
		persistenceFence = { fencingToken = "broken" },
	}
	local invalidFence = store:loadFenced("campaign", initialDocument, fenceTwo)
	harness:expect(
		not invalidFence.ok and invalidFence.error.code == "PERSISTENCE_INVALID",
		"invalid stored fencing metadata fails closed during claim"
	)
end
