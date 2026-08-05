--!strict

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

if not RunService:IsStudio() then
	warn("[RVTT Live DataStore] skipped outside Studio")
	return
end

local Version = require(ReplicatedStorage.RVTT.Shared.Core.Version)
local Server = ServerScriptService.RVTT.Server
local Diagnostics = require(Server.Runtime.Diagnostics)
local MigrationRegistry = require(Server.Persistence.MigrationRegistry)
local ProfileStore = require(Server.Persistence.ProfileStore)

local STORE_NAME = "RVTT_Authority_Integration_v1"
local key = "live:" .. HttpService:GenerateGUID(false)
local rawStore = DataStoreService:GetDataStore(STORE_NAME)
local diagnostics = Diagnostics.new()
local migrations = MigrationRegistry.new(Version.SCHEMA)
local migrationModule = ServerStorage.RVTT.Migrations:WaitForChild("001_InitialSchema")
migrations:register(0, require(migrationModule))
local store = ProfileStore.new(STORE_NAME, migrations, diagnostics)

local passed = 0
local failed = 0
local failures = {}

local function expect(condition: boolean, message: string)
	if condition then
		passed += 1
	else
		failed += 1
		table.insert(failures, message)
	end
end

local function document(revision: number, authorityEpoch: string): any
	return {
		schemaVersion = Version.SCHEMA,
		authorityEpoch = authorityEpoch,
		revision = revision,
		domains = {},
	}
end

local ran, trace = xpcall(function()
	local initial = store:save(key, document(1, "epoch:live"))
	expect(initial.ok, "initial UpdateAsync save succeeds")

	local loaded = store:load(key)
	expect(loaded.ok, "GetAsync load succeeds")
	if loaded.ok and loaded.value ~= nil then
		expect(loaded.value.revision == 1, "loaded revision matches saved revision")
		expect(loaded.value.authorityEpoch == "epoch:live", "loaded epoch matches saved epoch")
	else
		expect(false, "saved document is present")
	end

	local stale = store:save(key, document(0, "epoch:live"))
	expect(
		not stale.ok and stale.error.code == "PERSISTENCE_CONFLICT",
		"older revision is rejected"
	)

	local divergent = store:save(key, document(1, "epoch:other"))
	expect(
		not divergent.ok and divergent.error.code == "PERSISTENCE_CONFLICT",
		"equal revision with another epoch is rejected"
	)

	local newer = store:save(key, document(2, "epoch:live"))
	expect(newer.ok, "newer revision saves")

	local reloaded = store:load(key)
	expect(reloaded.ok, "newer revision reload succeeds")
	if reloaded.ok and reloaded.value ~= nil then
		expect(reloaded.value.revision == 2, "newer revision persists")
	else
		expect(false, "newer document is present")
	end
end, debug.traceback)

if not ran then
	expect(false, "unexpected exception: " .. tostring(trace))
end

local cleanupOk, cleanupError = pcall(function()
	rawStore:RemoveAsync(key)
end)
expect(cleanupOk, "temporary DataStore key is removed")
if not cleanupOk then
	table.insert(failures, "cleanup error: " .. tostring(cleanupError))
end

print(string.format("[RVTT Live DataStore] passed=%d failed=%d", passed, failed))
for _, failure in failures do
	warn("[RVTT Live DataStore]", failure)
end
assert(failed == 0, "RVTT live DataStore tests failed")
