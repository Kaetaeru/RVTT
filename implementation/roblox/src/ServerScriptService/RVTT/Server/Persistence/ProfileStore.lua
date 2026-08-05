--!strict

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)
local ValueGuard = require(ReplicatedStorage.RVTT.Shared.Core.ValueGuard)
local PersistenceDocumentValidator = require(script.Parent.PersistenceDocumentValidator)

local ProfileStore = {}
ProfileStore.__index = ProfileStore

local function revisionOf(value: any): number?
	if type(value) ~= "table" or not ValueGuard.isFiniteNumber(value.revision) then
		return nil
	end
	local revision = value.revision :: number
	if revision < 0 or revision % 1 ~= 0 then
		return nil
	end
	return revision
end

local function failureDetails(reason: string): { [string]: unknown }
	return { reason = reason }
end

function ProfileStore.new(
	storeName: string,
	migrationRegistry: any,
	diagnostics: any,
	dataStoreOverride: any?
): any
	local store = dataStoreOverride
	if store == nil then
		store = DataStoreService:GetDataStore(storeName)
	end
	return setmetatable({
		store = store,
		migrations = migrationRegistry,
		diagnostics = diagnostics,
	}, ProfileStore)
end

function ProfileStore.load(self: any, key: string): any
	local ok, valueOrFailure = pcall(function()
		return self.store:GetAsync(key)
	end)
	if not ok then
		local reason = tostring(valueOrFailure)
		self.diagnostics:record("error", "DATASTORE_LOAD_FAILED", {
			key = key,
			reason = reason,
		})
		return Result.err(
			"PERSISTENCE_FAILED",
			"error.persistence.failed",
			true,
			failureDetails(reason)
		)
	end

	local value = valueOrFailure
	if value == nil then
		return Result.ok(nil)
	end

	local valid, validationFailure = PersistenceDocumentValidator.validate(value)
	if not valid then
		local reason = validationFailure or "stored document is invalid"
		self.diagnostics:record("error", "DATASTORE_DOCUMENT_INVALID", {
			key = key,
			reason = reason,
		})
		return Result.err(
			"PERSISTENCE_INVALID",
			"error.persistence.invalid",
			false,
			failureDetails(reason)
		)
	end
	return self.migrations:apply(value)
end

function ProfileStore.save(self: any, key: string, value: any): any
	local candidateRevision = revisionOf(value)
	if candidateRevision == nil then
		return Result.err("PERSISTENCE_INVALID", "error.persistence.invalid", false)
	end

	local valid, validationFailure = PersistenceDocumentValidator.validate(value)
	if not valid then
		local reason = validationFailure or "candidate document is invalid"
		self.diagnostics:record("error", "DATASTORE_DOCUMENT_INVALID", {
			key = key,
			reason = reason,
			revision = candidateRevision,
		})
		return Result.err(
			"PERSISTENCE_INVALID",
			"error.persistence.invalid",
			false,
			failureDetails(reason)
		)
	end

	local conflict = false
	local ok, updateFailure = pcall(function()
		self.store:UpdateAsync(key, function(current: any): any
			conflict = false
			local currentRevision = revisionOf(current)
			if currentRevision ~= nil then
				local currentEpoch = current.authorityEpoch
				local candidateEpoch = value.authorityEpoch
				if currentRevision > candidateRevision then
					conflict = true
					return nil
				end
				if
					currentRevision == candidateRevision
					and currentEpoch ~= nil
					and candidateEpoch ~= nil
					and currentEpoch ~= candidateEpoch
				then
					conflict = true
					return nil
				end
			end
			return value
		end)
	end)
	if not ok then
		local reason = tostring(updateFailure)
		self.diagnostics:record("error", "DATASTORE_SAVE_FAILED", {
			key = key,
			reason = reason,
			revision = candidateRevision,
		})
		return Result.err(
			"PERSISTENCE_FAILED",
			"error.persistence.failed",
			true,
			failureDetails(reason)
		)
	end
	if conflict then
		self.diagnostics:record("warning", "DATASTORE_REVISION_CONFLICT", {
			key = key,
			revision = candidateRevision,
		})
		return Result.err("PERSISTENCE_CONFLICT", "error.persistence.conflict", true)
	end
	return Result.ok(true)
end

return ProfileStore
