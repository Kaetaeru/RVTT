--!strict

local Result = require(game:GetService("ReplicatedStorage").RVTT.Shared.Core.Result)

local MigrationRegistry = {}
MigrationRegistry.__index = MigrationRegistry

function MigrationRegistry.new(currentVersion: number)
	return setmetatable({ currentVersion = currentVersion, migrations = {} }, MigrationRegistry)
end

function MigrationRegistry:register(fromVersion: number, migrate)
	assert(self.migrations[fromVersion] == nil, "duplicate migration")
	self.migrations[fromVersion] = migrate
end

function MigrationRegistry:apply(document)
	local version = document.schemaVersion or 0
	while version < self.currentVersion do
		local migration = self.migrations[version]
		if migration == nil then
			return Result.err("MIGRATION_FAILED", "error.persistence.migration_failed", false, { version = version })
		end
		document = migration(document)
		version = document.schemaVersion
	end
	return Result.ok(document)
end

return MigrationRegistry
