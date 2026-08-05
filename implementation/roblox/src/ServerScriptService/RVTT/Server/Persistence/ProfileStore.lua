--!strict

local DataStoreService = game:GetService("DataStoreService")
local Result = require(game:GetService("ReplicatedStorage").RVTT.Shared.Core.Result)

local ProfileStore = {}
ProfileStore.__index = ProfileStore

function ProfileStore.new(storeName: string, migrationRegistry, diagnostics)
	return setmetatable(
		{
			store = DataStoreService:GetDataStore(storeName),
			migrations = migrationRegistry,
			diagnostics = diagnostics,
		},
		ProfileStore
	)
end

function ProfileStore:load(key: string)
	local ok, value = pcall(function()
		return self.store:GetAsync(key)
	end)
	if not ok then
		self.diagnostics:record("error", "DATASTORE_LOAD_FAILED", { key = key })
		return Result.err("PERSISTENCE_FAILED", "error.persistence.failed", true)
	end
	if value == nil then
		return Result.ok(nil)
	end
	return self.migrations:apply(value)
end

function ProfileStore:save(key: string, value)
	local ok = pcall(function()
		self.store:UpdateAsync(key, function()
			return value
		end)
	end)
	if not ok then
		self.diagnostics:record("error", "DATASTORE_SAVE_FAILED", { key = key })
		return Result.err("PERSISTENCE_FAILED", "error.persistence.failed", true)
	end
	return Result.ok(true)
end

return ProfileStore
