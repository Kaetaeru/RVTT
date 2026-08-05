--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DeepCopy = require(ReplicatedStorage.RVTT.Shared.Core.DeepCopy)
local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)
local ValueGuard = require(ReplicatedStorage.RVTT.Shared.Core.ValueGuard)

local MigrationRegistry = {}
MigrationRegistry.__index = MigrationRegistry

local function isVersion(value: unknown): boolean
	return ValueGuard.isFiniteNumber(value)
		and (value :: number) >= 0
		and (value :: number) % 1 == 0
end

local function failed(reason: string, version: unknown): any
	return Result.err(
		"MIGRATION_FAILED",
		"error.persistence.migration_failed",
		false,
		{ reason = reason, version = version } :: { [string]: unknown }
	)
end

function MigrationRegistry.new(currentVersion: number): any
	assert(isVersion(currentVersion), "currentVersion must be a non-negative integer")
	return setmetatable({ currentVersion = currentVersion, migrations = {} }, MigrationRegistry)
end

function MigrationRegistry.register(self: any, fromVersion: number, migrate: any)
	assert(isVersion(fromVersion), "fromVersion must be a non-negative integer")
	assert(fromVersion < self.currentVersion, "migration must target a newer supported version")
	assert(type(migrate) == "function", "migration function required")
	assert(self.migrations[fromVersion] == nil, "duplicate migration")
	self.migrations[fromVersion] = migrate
end

function MigrationRegistry.apply(self: any, document: any): any
	if type(document) ~= "table" then
		return failed("document_not_table", nil)
	end

	local working: any = DeepCopy(document)
	local version: any = working.schemaVersion or 0
	if not isVersion(version) then
		return failed("invalid_schema_version", version)
	end
	if version > self.currentVersion then
		return failed("future_schema_version", version)
	end

	local steps = 0
	while version < self.currentVersion do
		steps += 1
		if steps > self.currentVersion + 1 then
			return failed("migration_step_limit", version)
		end

		local migration = self.migrations[version]
		if migration == nil then
			return failed("migration_missing", version)
		end

		local ok, migrated = xpcall(function()
			return migration(working)
		end, debug.traceback)
		if not ok or type(migrated) ~= "table" then
			return failed("migration_exception", version)
		end

		local nextVersion = migrated.schemaVersion
		if not isVersion(nextVersion) or nextVersion ~= version + 1 then
			return failed("migration_did_not_advance", version)
		end

		working = migrated
		version = nextVersion
	end

	return Result.ok(working)
end

return MigrationRegistry
