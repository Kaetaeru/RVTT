--!strict

return function(harness)
	local Server = game:GetService("ServerScriptService").RVTT.Server
	local MigrationRegistry = require(Server.Persistence.MigrationRegistry)

	local migrations = MigrationRegistry.new(2)
	migrations:register(0, function(document)
		document.schemaVersion = 1
		document.firstMigration = true
		return document
	end)
	migrations:register(1, function(document)
		document.schemaVersion = 2
		document.secondMigration = true
		return document
	end)

	local original = { schemaVersion = 0 }
	local migrated = migrations:apply(original)
	harness:expect(migrated.ok, "sequential migrations succeed")
	if migrated.ok then
		harness:equal(migrated.value.schemaVersion, 2, "migration reaches current schema")
		harness:expect(migrated.value.firstMigration == true, "first migration applied")
		harness:expect(migrated.value.secondMigration == true, "second migration applied")
	end
	harness:equal(original.schemaVersion, 0, "migration does not mutate source document")

	local stalledRegistry = MigrationRegistry.new(1)
	stalledRegistry:register(0, function(document)
		return document
	end)
	local stalled = stalledRegistry:apply({ schemaVersion = 0 })
	harness:expect(not stalled.ok, "migration must advance exactly one version")

	local future = MigrationRegistry.new(1):apply({ schemaVersion = 2 })
	harness:expect(not future.ok, "future schema is rejected")

	local Registry = require(Server.Runtime.CommandRegistry).new()
	local Diagnostics = require(Server.Runtime.Diagnostics).new()
	local Outbox = require(Server.Runtime.EventOutbox).new()
	local Journal = require(Server.Persistence.SnapshotJournal).new(20)
	local Transactions = require(Server.Runtime.TransactionCoordinator).new(Diagnostics)
	local Runtime = require(Server.Runtime.AuthorityRuntime).new(
		Registry,
		Transactions,
		Outbox,
		Diagnostics,
		Journal
	)
	for _, domain in require(Server.Bootstrap.ServiceGraph).domainModules() do
		Runtime:installDomain(domain)
	end

	local restored = Runtime:restore({
		schemaVersion = 1,
		revision = 5,
		domains = {},
	})
	harness:expect(restored.ok, "valid authority document restores")
	harness:equal(Runtime:snapshot().revision, 5, "restored revision is retained")
	harness:expect(
		Runtime:snapshot().domains.session ~= nil,
		"missing session domain is reconstructed"
	)
	harness:expect(Runtime:snapshot().domains.rules ~= nil, "missing rules domain is reconstructed")

	local invalidRevision = Runtime:restore({
		schemaVersion = 1,
		revision = "broken",
		domains = {},
	})
	harness:expect(not invalidRevision.ok, "invalid revision is rejected")

	local fakeStore = { saved = {} }
	function fakeStore:load(_key)
		return { ok = true, value = { revision = 3 } }
	end
	function fakeStore:save(_key, value)
		table.insert(self.saved, value)
		return { ok = true, value = true }
	end

	local PersistenceCoordinator = require(Server.Persistence.PersistenceCoordinator)
	local coordinator = PersistenceCoordinator.new(fakeStore, "test", Diagnostics)
	local loaded = coordinator:load()
	harness:expect(loaded.ok, "coordinator loads existing revision")
	harness:expect(not coordinator:markDirty({ revision = 3 }), "saved revision is not re-queued")
	harness:expect(coordinator:markDirty({ revision = 5 }), "newer revision becomes dirty")
	harness:expect(
		not coordinator:markDirty({ revision = 4 }),
		"older revision cannot replace dirty state"
	)
	harness:equal(coordinator.dirty.revision, 5, "highest pending revision is retained")
	local flushed = coordinator:flush()
	harness:expect(flushed.ok, "newest pending revision flushes")
	harness:equal(coordinator.lastSavedRevision, 5, "saved revision advances monotonically")
end
