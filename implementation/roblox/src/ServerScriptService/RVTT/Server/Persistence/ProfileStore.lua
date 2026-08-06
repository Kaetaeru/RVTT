--!strict

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DeepCopy = require(ReplicatedStorage.RVTT.Shared.Core.DeepCopy)
local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)
local ValueGuard = require(ReplicatedStorage.RVTT.Shared.Core.ValueGuard)
local PersistenceDocumentValidator = require(script.Parent.PersistenceDocumentValidator)

export type FenceGuard = {
	ownerId: string,
	token: string,
	fencingToken: number,
}

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

local function validText(value: any): boolean
	return type(value) == "string" and #value > 0
end

local function asFence(value: any): FenceGuard?
	if type(value) ~= "table" then
		return nil
	end
	if
		not validText(value.ownerId)
		or not validText(value.token)
		or not ValueGuard.isFiniteNumber(value.fencingToken)
		or value.fencingToken < 1
		or value.fencingToken % 1 ~= 0
	then
		return nil
	end
	return value :: FenceGuard
end

local function storedFence(value: any): (FenceGuard?, boolean)
	if type(value) ~= "table" or value.persistenceFence == nil then
		return nil, false
	end
	local fence = asFence(value.persistenceFence)
	return fence, fence == nil
end

local function failureDetails(reason: string): { [string]: unknown }
	return { reason = reason }
end

local function fenceDetails(candidate: FenceGuard?, current: FenceGuard?): { [string]: unknown }
	return {
		candidateFencingToken = if candidate ~= nil then candidate.fencingToken else nil,
		currentFencingToken = if current ~= nil then current.fencingToken else nil,
		currentOwnerId = if current ~= nil then current.ownerId else nil,
	}
end

local function isFenced(candidate: FenceGuard?, current: FenceGuard?): boolean
	if current == nil then
		return false
	end
	if candidate == nil then
		return true
	end
	if current.fencingToken > candidate.fencingToken then
		return true
	end
	return current.fencingToken == candidate.fencingToken
		and (current.ownerId ~= candidate.ownerId or current.token ~= candidate.token)
end

local function decodeStoredDocument(self: any, key: string, value: any): any
	if value == nil then
		return Result.ok(nil)
	end

	local _, invalidFence = storedFence(value)
	if invalidFence then
		local reason = "stored persistence fence is invalid"
		self.diagnostics:record("error", "DATASTORE_FENCE_INVALID", {
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

	local document = DeepCopy(value)
	document.persistenceFence = nil
	local valid, validationFailure = PersistenceDocumentValidator.validate(document)
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
	return self.migrations:apply(document)
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
	return decodeStoredDocument(self, key, valueOrFailure)
end

function ProfileStore.loadFenced(
	self: any,
	key: string,
	initialValue: any,
	fenceGuard: FenceGuard
): any
	local candidateFence = asFence(fenceGuard)
	if candidateFence == nil then
		return Result.err("PERSISTENCE_INVALID", "error.persistence.invalid", false)
	end
	if revisionOf(initialValue) == nil then
		return Result.err("PERSISTENCE_INVALID", "error.persistence.invalid", false)
	end
	local initialValid, initialFailure = PersistenceDocumentValidator.validate(initialValue)
	if not initialValid then
		return Result.err(
			"PERSISTENCE_INVALID",
			"error.persistence.invalid",
			false,
			failureDetails(initialFailure or "initial document is invalid")
		)
	end

	local fenced = false
	local invalidCurrentFence = false
	local currentFenceForDetails: FenceGuard? = nil
	local ok, valueOrFailure = pcall(function()
		return self.store:UpdateAsync(key, function(current: any): any
			fenced = false
			invalidCurrentFence = false
			currentFenceForDetails = nil

			local currentFence, currentFenceInvalid = storedFence(current)
			currentFenceForDetails = currentFence
			if currentFenceInvalid then
				invalidCurrentFence = true
				return nil
			end
			if isFenced(candidateFence, currentFence) then
				fenced = true
				return nil
			end

			local claimed = DeepCopy(if current ~= nil then current else initialValue)
			claimed.persistenceFence = DeepCopy(candidateFence)
			return claimed
		end)
	end)
	if not ok then
		local reason = tostring(valueOrFailure)
		self.diagnostics:record("error", "DATASTORE_FENCE_CLAIM_FAILED", {
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
	if invalidCurrentFence then
		local reason = "stored persistence fence is invalid"
		self.diagnostics:record("error", "DATASTORE_FENCE_INVALID", {
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
	if fenced then
		self.diagnostics:record("warning", "DATASTORE_FENCE_CLAIM_REJECTED", {
			key = key,
			candidateFencingToken = candidateFence.fencingToken,
			currentFencingToken = if currentFenceForDetails ~= nil
				then currentFenceForDetails.fencingToken
				else nil,
		})
		return Result.err(
			"PERSISTENCE_FENCED",
			"error.persistence.fenced",
			false,
			fenceDetails(candidateFence, currentFenceForDetails)
		)
	end
	return decodeStoredDocument(self, key, valueOrFailure)
end

function ProfileStore.save(self: any, key: string, value: any, fenceGuard: FenceGuard?): any
	local candidateRevision = revisionOf(value)
	if candidateRevision == nil then
		return Result.err("PERSISTENCE_INVALID", "error.persistence.invalid", false)
	end

	local candidateFence: FenceGuard? = nil
	if fenceGuard ~= nil then
		candidateFence = asFence(fenceGuard)
		if candidateFence == nil then
			return Result.err("PERSISTENCE_INVALID", "error.persistence.invalid", false)
		end
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

	local storedCandidate = DeepCopy(value)
	if candidateFence ~= nil then
		storedCandidate.persistenceFence = DeepCopy(candidateFence)
	end

	local conflict = false
	local fenced = false
	local invalidCurrentFence = false
	local currentFenceForDetails: FenceGuard? = nil
	local ok, updateFailure = pcall(function()
		self.store:UpdateAsync(key, function(current: any): any
			conflict = false
			fenced = false
			invalidCurrentFence = false
			currentFenceForDetails = nil

			local currentFence, currentFenceInvalid = storedFence(current)
			currentFenceForDetails = currentFence
			if currentFenceInvalid then
				invalidCurrentFence = true
				return nil
			end
			if isFenced(candidateFence, currentFence) then
				fenced = true
				return nil
			end

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
			return storedCandidate
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
	if invalidCurrentFence then
		local reason = "stored persistence fence is invalid"
		self.diagnostics:record("error", "DATASTORE_FENCE_INVALID", {
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
	if fenced then
		self.diagnostics:record("warning", "DATASTORE_FENCED_WRITE_REJECTED", {
			key = key,
			revision = candidateRevision,
			candidateFencingToken = if candidateFence ~= nil
				then candidateFence.fencingToken
				else nil,
			currentFencingToken = if currentFenceForDetails ~= nil
				then currentFenceForDetails.fencingToken
				else nil,
		})
		return Result.err(
			"PERSISTENCE_FENCED",
			"error.persistence.fenced",
			false,
			fenceDetails(candidateFence, currentFenceForDetails)
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
