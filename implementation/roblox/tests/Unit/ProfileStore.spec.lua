--!strict

return function(harness)
	local Server = game:GetService("ServerScriptService").RVTT.Server
	local MigrationRegistry = require(Server.Persistence.MigrationRegistry)
	local ProfileStore = require(Server.Persistence.ProfileStore)

	local diagnostics: any = { incidents = {} }
	function diagnostics:record(level: string, code: string, context: any)
		table.insert(self.incidents, { level = level, code = code, context = context })
	end

	local migrations = MigrationRegistry.new(1)
	migrations:register(0, function(document: any)
		document.schemaVersion = 1
		document.migrated = true
		return document
	end)

	local fakeStore: any = {
		value = nil,
		failGet = false,
		failUpdate = false,
		getCalls = 0,
		updateCalls = 0,
		retryValues = nil,
	}

	function fakeStore:GetAsync(_key: string): any
		self.getCalls += 1
		if self.failGet then
			error("get failed")
		end
		return self.value
	end

	function fakeStore:UpdateAsync(_key: string, transform: any): any
		self.updateCalls += 1
		if self.failUpdate then
			error("update failed")
		end

		local nextValue = nil
		if self.retryValues ~= nil then
			for _, current in self.retryValues do
				nextValue = transform(if current == false then nil else current)
			end
			self.retryValues = nil
		else
			nextValue = transform(self.value)
		end
		if nextValue ~= nil then
			self.value = nextValue
		end
		return self.value
	end

	local store = ProfileStore.new("unused", migrations, diagnostics, fakeStore)

	local empty = store:load("profile")
	harness:expect(empty.ok, "missing profile loads successfully")
	if empty.ok then
		harness:expect(empty.value == nil, "missing profile returns nil")
	end

	fakeStore.value = {
		schemaVersion = 0,
		revision = 1,
		authorityEpoch = "epoch:migration",
	}
	local migrated = store:load("profile")
	harness:expect(migrated.ok, "loaded profile is migrated")
	if migrated.ok then
		harness:equal(migrated.value.schemaVersion, 1, "loaded profile reaches current schema")
		harness:expect(migrated.value.migrated == true, "load applies registered migration")
	end

	fakeStore.value = nil
	local initialSave = store:save("profile", {
		schemaVersion = 1,
		revision = 2,
		authorityEpoch = "epoch:a",
	})
	harness:expect(initialSave.ok, "valid profile saves")
	harness:equal(fakeStore.value.revision, 2, "saved profile reaches backing store")

	local updatesBeforeInvalid = fakeStore.updateCalls
	local invalid = store:save("profile", {
		schemaVersion = 1,
		revision = "broken",
		authorityEpoch = "epoch:a",
	})
	harness:expect(not invalid.ok, "invalid revision is rejected before persistence")
	harness:equal(
		fakeStore.updateCalls,
		updatesBeforeInvalid,
		"invalid revision does not call UpdateAsync"
	)

	fakeStore.value = {
		schemaVersion = 1,
		revision = 4,
		authorityEpoch = "epoch:a",
	}
	local stale = store:save("profile", {
		schemaVersion = 1,
		revision = 3,
		authorityEpoch = "epoch:a",
	})
	harness:expect(
		not stale.ok and stale.error.code == "PERSISTENCE_CONFLICT",
		"older revision is rejected as a conflict"
	)

	local divergent = store:save("profile", {
		schemaVersion = 1,
		revision = 4,
		authorityEpoch = "epoch:b",
	})
	harness:expect(
		not divergent.ok and divergent.error.code == "PERSISTENCE_CONFLICT",
		"equal revision with another epoch is rejected"
	)

	local idempotent = store:save("profile", {
		schemaVersion = 1,
		revision = 4,
		authorityEpoch = "epoch:a",
	})
	harness:expect(idempotent.ok, "equal revision with the same epoch is idempotent")

	fakeStore.retryValues = {
		{
			schemaVersion = 1,
			revision = 5,
			authorityEpoch = "epoch:other",
		},
		false :: any,
	}
	local retryRecovered = store:save("profile", {
		schemaVersion = 1,
		revision = 3,
		authorityEpoch = "epoch:retry",
	})
	harness:expect(retryRecovered.ok, "final UpdateAsync callback result controls conflict status")

	fakeStore.failGet = true
	local getFailure = store:load("profile")
	harness:expect(not getFailure.ok, "GetAsync failure is returned")
	if not getFailure.ok then
		harness:expect(getFailure.error.retryable, "GetAsync failure is retryable")
	end
	fakeStore.failGet = false

	fakeStore.failUpdate = true
	local updateFailure = store:save("profile", {
		schemaVersion = 1,
		revision = 6,
		authorityEpoch = "epoch:a",
	})
	harness:expect(not updateFailure.ok, "UpdateAsync failure is returned")
	if not updateFailure.ok then
		harness:expect(updateFailure.error.retryable, "UpdateAsync failure is retryable")
	end
end
