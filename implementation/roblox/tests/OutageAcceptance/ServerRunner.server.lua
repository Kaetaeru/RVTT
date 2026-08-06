--!strict

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local testMode = ReplicatedStorage:FindFirstChild("RVTT_TestMode")
if testMode == nil or not testMode:IsA("StringValue") or testMode.Value ~= "datastore-outage" then
	return
end

local Version = require(ReplicatedStorage.RVTT.Shared.Core.Version)
local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)
local Server = ServerScriptService.RVTT.Server
local Diagnostics = require(Server.Runtime.Diagnostics)
local MigrationRegistry = require(Server.Persistence.MigrationRegistry)
local PersistenceCoordinator = require(Server.Persistence.PersistenceCoordinator)
local ProfileStore = require(Server.Persistence.ProfileStore)

local STORE_NAME = "RVTT_Outage_Integration_v1"
local key = "outage:" .. HttpService:GenerateGUID(false)
local rawStore = DataStoreService:GetDataStore(STORE_NAME)
local diagnostics = Diagnostics.new()
local migrations = MigrationRegistry.new(Version.SCHEMA)
local migrationModule = ServerStorage.RVTT.Migrations:WaitForChild("001_InitialSchema")
migrations:register(0, require(migrationModule))
local realStore = ProfileStore.new(STORE_NAME, migrations, diagnostics)

local ControlledStore = {}
ControlledStore.__index = ControlledStore

function ControlledStore.new(delegate: any): any
	return setmetatable({
		delegate = delegate,
		outage = false,
		injectedFailures = 0,
	}, ControlledStore)
end

function ControlledStore.setOutage(self: any, enabled: boolean)
	self.outage = enabled
end

function ControlledStore.load(self: any, storeKey: string): any
	if self.outage then
		self.injectedFailures += 1
		return Result.err(
			"PERSISTENCE_FAILED",
			"error.persistence.failed",
			true,
			({ reason = "forced datastore outage before GetAsync" } :: { [string]: unknown })
		)
	end
	return self.delegate:load(storeKey)
end

function ControlledStore.save(self: any, storeKey: string, value: any): any
	if self.outage then
		self.injectedFailures += 1
		return Result.err(
			"PERSISTENCE_FAILED",
			"error.persistence.failed",
			true,
			({ reason = "forced datastore outage before UpdateAsync" } :: { [string]: unknown })
		)
	end
	return self.delegate:save(storeKey, value)
end

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

local cleanupBefore = pcall(function()
	rawStore:RemoveAsync(key)
end)
expect(cleanupBefore, "temporary outage key is clear before the run")

local controlled = ControlledStore.new(realStore)
local coordinator = PersistenceCoordinator.new(controlled, key, diagnostics)
controlled:setOutage(true)
local failedLoad = coordinator:load()
expect(not failedLoad.ok, "forced outage blocks initial load")
if not failedLoad.ok then
	equal(failedLoad.error.code, "PERSISTENCE_FAILED", "load outage returns persistence failure")
	expect(failedLoad.error.retryable, "load outage remains retryable")
end

controlled:setOutage(false)
local recoveredLoad = coordinator:load()
expect(recoveredLoad.ok, "load succeeds after outage recovery")
if recoveredLoad.ok then
	equal(recoveredLoad.value, nil, "recovered load sees an empty temporary key")
end

local document = {
	schemaVersion = Version.SCHEMA,
	authorityEpoch = "outage-epoch",
	revision = 1,
	domains = {},
}
expect(coordinator:markDirty(document, false), "shutdown-only outage snapshot becomes dirty")
controlled:setOutage(true)
local exhausted = coordinator:flushUntilClean({
	maxAttempts = 3,
	initialDelaySeconds = 0,
	maxDelaySeconds = 0,
	deadlineSeconds = 2,
})
expect(not exhausted.ok, "bounded retry returns after a sustained forced outage")
if not exhausted.ok then
	equal(exhausted.error.code, "PERSISTENCE_FAILED", "save outage returns persistence failure")
end
expect(coordinator.dirty ~= nil, "retry exhaustion preserves the dirty snapshot")
equal(coordinator.lastSavedRevision, -1, "failed outage flush does not advance saved revision")

controlled:setOutage(false)
local recoveredSave = coordinator:flushUntilClean({
	maxAttempts = 3,
	initialDelaySeconds = 0,
	maxDelaySeconds = 0,
	deadlineSeconds = 2,
})
expect(recoveredSave.ok, "dirty snapshot saves after outage recovery")
expect(coordinator.dirty == nil, "recovered save clears dirty state")
equal(coordinator.lastSavedRevision, 1, "recovered save advances saved revision")

local persisted = realStore:load(key)
expect(persisted.ok, "actual DataStore reload succeeds after recovery")
if persisted.ok and persisted.value ~= nil then
	equal(persisted.value.revision, 1, "actual DataStore contains the recovered revision")
	equal(
		persisted.value.authorityEpoch,
		"outage-epoch",
		"actual DataStore contains the intended epoch"
	)
else
	expect(false, "actual DataStore contains the recovered document")
	expect(false, "actual DataStore contains the recovered authority epoch")
end

controlled:setOutage(true)
local laterLoadFailure = coordinator:load()
expect(not laterLoadFailure.ok, "forced outage also blocks a later reload")
controlled:setOutage(false)
local laterLoadRecovery = coordinator:load()
expect(laterLoadRecovery.ok, "later reload recovers without mutating the document")
if laterLoadRecovery.ok and laterLoadRecovery.value ~= nil then
	equal(laterLoadRecovery.value.revision, 1, "later recovery retains the committed revision")
else
	expect(false, "later recovery returns the committed document")
end

local cleanupAfter = pcall(function()
	rawStore:RemoveAsync(key)
end)
expect(cleanupAfter, "temporary outage key is removed after the run")

print(
	string.format(
		"[RVTT DataStore Outage] result=%s passed=%d failed=%d injectedFailures=%d recoveredRevision=%d",
		if failed == 0 then "PASS" else "FAIL",
		passed,
		failed,
		controlled.injectedFailures,
		coordinator.lastSavedRevision
	)
)
for _, failure in failures do
	warn("[RVTT DataStore Outage]", failure)
end
assert(failed == 0, "RVTT DataStore outage acceptance failed")
