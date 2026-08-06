--!strict

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local testMode = ReplicatedStorage:FindFirstChild("RVTT_TestMode")
local phaseValue = ReplicatedStorage:FindFirstChild("RVTT_RestartPhase")
if
	testMode == nil
	or not testMode:IsA("StringValue")
	or testMode.Value ~= "restart-acceptance"
	or phaseValue == nil
	or not phaseValue:IsA("StringValue")
then
	return
end

local Version = require(ReplicatedStorage.RVTT.Shared.Core.Version)
local Server = ServerScriptService.RVTT.Server
local AuthorityRuntime = require(Server.Runtime.AuthorityRuntime)
local CommandRegistry = require(Server.Runtime.CommandRegistry)
local Diagnostics = require(Server.Runtime.Diagnostics)
local EventOutbox = require(Server.Runtime.EventOutbox)
local TransactionCoordinator = require(Server.Runtime.TransactionCoordinator)
local MigrationRegistry = require(Server.Persistence.MigrationRegistry)
local PersistenceCoordinator = require(Server.Persistence.PersistenceCoordinator)
local ProfileStore = require(Server.Persistence.ProfileStore)
local SnapshotJournal = require(Server.Persistence.SnapshotJournal)
local ServiceGraph = require(Server.Bootstrap.ServiceGraph)

local STORE_NAME = "RVTT_Restart_Acceptance_v1"
local KEY = "campaign:grand-restart"
local TEST_USER_ID = 4202
local TEST_ROLE = "player"

local diagnostics = Diagnostics.new()
local migrations = MigrationRegistry.new(Version.SCHEMA)
local migrationModule = ServerStorage.RVTT.Migrations:WaitForChild("001_InitialSchema")
migrations:register(0, require(migrationModule))
local store = ProfileStore.new(STORE_NAME, migrations, diagnostics)
local rawStore = DataStoreService:GetDataStore(STORE_NAME)

local passed = 0
local failed = 0
local failures: { string } = {}

local function expect(condition: boolean, message: string)
	if condition then
		passed += 1
	else
		failed += 1
		table.insert(failures, message)
	end
end

local function equal(actual: any, expected: any, message: string)
	expect(
		actual == expected,
		message .. " expected=" .. tostring(expected) .. " actual=" .. tostring(actual)
	)
end

local function runtime(): any
	local runtimeDiagnostics = Diagnostics.new()
	local authority = AuthorityRuntime.new(
		CommandRegistry.new(),
		TransactionCoordinator.new(runtimeDiagnostics),
		EventOutbox.new(),
		runtimeDiagnostics,
		SnapshotJournal.new(64)
	)
	for _, domain in ServiceGraph.domainModules() do
		authority:installDomain(domain)
	end
	return authority
end

local function join(authority: any, commandId: string, epoch: string, revision: number): any
	return authority:execute({
		player = { DisplayName = "Restart Acceptance" } :: any,
		playerId = TEST_USER_ID,
		role = TEST_ROLE,
		origin = "remote",
		commandId = commandId,
		correlationId = commandId,
	}, {
		protocolVersion = Version.PROTOCOL,
		commandId = commandId,
		commandType = "session.join",
		correlationId = commandId,
		authorityEpoch = epoch,
		expectedRevision = revision,
		payload = {},
	})
end

local function warnFailures(label: string)
	for _, failure in failures do
		warn(label, failure)
	end
end

if not RunService:IsStudio() then
	warn("[RVTT Restart] acceptance must run in Studio with API access enabled")
	return
end

if phaseValue.Value == "seed" then
	local cleanupOk, cleanupFailure = pcall(function()
		rawStore:RemoveAsync(KEY)
	end)
	expect(cleanupOk, "seed removes any stale restart checkpoint")
	if not cleanupOk then
		table.insert(failures, "seed cleanup error: " .. tostring(cleanupFailure))
	end

	local authority = runtime()
	local beforeJoin = authority:snapshot()
	local joined = join(
		authority,
		"restart:seed:join",
		beforeJoin.authorityEpoch,
		beforeJoin.revision
	)
	expect(joined.ok, "seed creates the restart membership")
	local connected = authority:executeSystem("session.connection", {
		userId = TEST_USER_ID,
		status = "connected",
	})
	expect(connected.ok, "seed records the connected state")

	local snapshot = authority:snapshot()
	local coordinator = PersistenceCoordinator.new(store, KEY, diagnostics)
	expect(
		coordinator:markDirty(snapshot, false),
		"seed marks the snapshot dirty without scheduling an early flush"
	)
	expect(coordinator.dirty ~= nil, "seed snapshot remains dirty until server shutdown")

	print(
		string.format(
			"[RVTT Restart Prompt] phase=seed action=close-studio revision=%d epoch=%s",
			snapshot.revision,
			snapshot.authorityEpoch
		)
	)

	game:BindToClose(function()
		local result = coordinator:flushUntilClean({
			maxAttempts = 5,
			initialDelaySeconds = 0.25,
			maxDelaySeconds = 2,
			deadlineSeconds = 25,
		})
		expect(result.ok, "BindToClose flush persists the dirty restart snapshot")
		expect(coordinator.dirty == nil, "shutdown flush leaves no dirty snapshot")
		local resultName = if failed == 0 then "PASS" else "FAIL"
		print(
			string.format(
				"[RVTT Restart Seed] result=%s passed=%d failed=%d revision=%d epoch=%s",
				resultName,
				passed,
				failed,
				snapshot.revision,
				snapshot.authorityEpoch
			)
		)
		warnFailures("[RVTT Restart Seed]")
		assert(failed == 0, "RVTT restart seed failed")
	end)
	return
end

if phaseValue.Value ~= "verify" then
	warn("[RVTT Restart] unknown phase=" .. phaseValue.Value)
	return
end

local coordinator = PersistenceCoordinator.new(store, KEY, diagnostics)
local loaded = coordinator:load()
expect(loaded.ok, "verify loads the shutdown checkpoint from DataStore")
expect(loaded.ok and loaded.value ~= nil, "verify finds the persisted restart document")

local restoredRevision = -1
local previousEpoch = "missing"
local currentEpoch = "missing"
if loaded.ok and loaded.value ~= nil then
	local document = loaded.value
	restoredRevision = document.revision
	previousEpoch = document.authorityEpoch
	local authority = runtime()
	local freshEpoch = authority:snapshot().authorityEpoch
	local restored = authority:restore(document)
	expect(restored.ok, "fresh server restores the persisted authority document")
	if restored.ok then
		local snapshot = authority:snapshot()
		currentEpoch = snapshot.authorityEpoch
		equal(snapshot.revision, restoredRevision, "restart preserves the stored revision")
		expect(currentEpoch ~= previousEpoch, "restart rotates the authority epoch")
		expect(currentEpoch ~= freshEpoch, "restore creates a dedicated post-restore epoch")
		local session = snapshot.domains.session
		expect(
			type(session.memberships[tostring(TEST_USER_ID)]) == "table",
			"restart restores the logical membership"
		)
		equal(
			session.connections[tostring(TEST_USER_ID)],
			"connected",
			"restart restores the connected checkpoint"
		)

		local stale = join(
			authority,
			"restart:verify:stale",
			previousEpoch,
			snapshot.revision
		)
		expect(
			not stale.ok and stale.error.code == "STALE_EPOCH",
			"fresh server rejects a command from the previous epoch"
		)

		local validSnapshot = authority:snapshot()
		local valid = join(
			authority,
			"restart:verify:current",
			validSnapshot.authorityEpoch,
			validSnapshot.revision
		)
		expect(valid.ok, "fresh server accepts a command using the current epoch")
		expect(
			authority:snapshot().revision == restoredRevision + 1,
			"post-restart command advances revision exactly once"
		)

		expect(
			coordinator:markDirty(authority:snapshot(), false),
			"verify queues the post-restart authority snapshot"
		)
		local saved = coordinator:flushUntilClean({
			maxAttempts = 5,
			initialDelaySeconds = 0.25,
			maxDelaySeconds = 2,
			deadlineSeconds = 25,
		})
		expect(saved.ok, "verify persists the post-restart snapshot with retry policy")
	end
end

local cleanupOk, cleanupFailure = pcall(function()
	rawStore:RemoveAsync(KEY)
end)
expect(cleanupOk, "verify removes the restart acceptance checkpoint")
if not cleanupOk then
	table.insert(failures, "verify cleanup error: " .. tostring(cleanupFailure))
end

local resultName = if failed == 0 then "PASS" else "FAIL"
print(
	string.format(
		"[RVTT Restart Verify] result=%s passed=%d failed=%d restoredRevision=%d previousEpoch=%s currentEpoch=%s",
		resultName,
		passed,
		failed,
		restoredRevision,
		previousEpoch,
		currentEpoch
	)
)
warnFailures("[RVTT Restart Verify]")
assert(failed == 0, "RVTT restart verify failed")
