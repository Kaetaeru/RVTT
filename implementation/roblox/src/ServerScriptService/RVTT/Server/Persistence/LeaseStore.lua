--!strict

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)
local ValueGuard = require(ReplicatedStorage.RVTT.Shared.Core.ValueGuard)

export type LeaseRecord = {
	ownerId: string,
	token: string,
	expiresAt: number,
	fencingToken: number,
}

local LeaseStore = {}
LeaseStore.__index = LeaseStore

local function validText(value: any): boolean
	return type(value) == "string" and #value > 0
end

local function validTime(value: any): boolean
	return ValueGuard.isFiniteNumber(value) and value >= 0
end

local function validFence(value: any): boolean
	return ValueGuard.isFiniteNumber(value) and value >= 1 and value % 1 == 0
end

local function asRecord(value: any): LeaseRecord?
	if type(value) ~= "table" then
		return nil
	end
	if
		not validText(value.ownerId)
		or not validText(value.token)
		or not validTime(value.expiresAt)
		or not validFence(value.fencingToken)
	then
		return nil
	end
	return value :: LeaseRecord
end

local function failureDetails(reason: string): { [string]: unknown }
	return { reason = reason }
end

local function heldDetails(record: LeaseRecord): { [string]: unknown }
	return {
		ownerId = record.ownerId,
		expiresAt = record.expiresAt,
		fencingToken = record.fencingToken,
	}
end

local function validateRequest(
	ownerId: string,
	token: string,
	ttlSeconds: number,
	now: number
): boolean
	return validText(ownerId)
		and validText(token)
		and ValueGuard.isFiniteNumber(ttlSeconds)
		and ttlSeconds > 0
		and validTime(now)
end

function LeaseStore.new(storeName: string, diagnostics: any, dataStoreOverride: any?): any
	local store = dataStoreOverride
	if store == nil then
		store = DataStoreService:GetDataStore(storeName)
	end
	return setmetatable({
		store = store,
		diagnostics = diagnostics,
	}, LeaseStore)
end

function LeaseStore.acquire(
	self: any,
	key: string,
	ownerId: string,
	token: string,
	ttlSeconds: number,
	now: number
): any
	if not validateRequest(ownerId, token, ttlSeconds, now) then
		return Result.err("LEASE_INVALID", "error.persistence.lease_invalid", false)
	end

	local acquired = false
	local held: LeaseRecord? = nil
	local ok, valueOrFailure = pcall(function()
		return self.store:UpdateAsync(key, function(currentValue: any): any
			local current = asRecord(currentValue)
			if current ~= nil and current.expiresAt > now then
				if current.ownerId == ownerId and current.token == token then
					acquired = true
					return {
						ownerId = ownerId,
						token = token,
						expiresAt = now + ttlSeconds,
						fencingToken = current.fencingToken,
					}
				end
				held = current
				return current
			end

			acquired = true
			return {
				ownerId = ownerId,
				token = token,
				expiresAt = now + ttlSeconds,
				fencingToken = if current ~= nil then current.fencingToken + 1 else 1,
			}
		end)
	end)
	if not ok then
		local reason = tostring(valueOrFailure)
		self.diagnostics:record("error", "DATASTORE_LEASE_ACQUIRE_FAILED", {
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
	if not acquired then
		return Result.err(
			"LEASE_HELD",
			"error.persistence.lease_held",
			true,
			if held ~= nil then heldDetails(held) else nil
		)
	end
	local record = asRecord(valueOrFailure)
	if record == nil then
		return Result.err("LEASE_INVALID", "error.persistence.lease_invalid", false)
	end
	return Result.ok(record)
end

function LeaseStore.renew(
	self: any,
	key: string,
	ownerId: string,
	token: string,
	ttlSeconds: number,
	now: number
): any
	if not validateRequest(ownerId, token, ttlSeconds, now) then
		return Result.err("LEASE_INVALID", "error.persistence.lease_invalid", false)
	end

	local renewed = false
	local currentRecord: LeaseRecord? = nil
	local ok, valueOrFailure = pcall(function()
		return self.store:UpdateAsync(key, function(currentValue: any): any
			local current = asRecord(currentValue)
			currentRecord = current
			if
				current == nil
				or current.ownerId ~= ownerId
				or current.token ~= token
				or current.expiresAt <= now
			then
				return currentValue
			end
			renewed = true
			return {
				ownerId = ownerId,
				token = token,
				expiresAt = now + ttlSeconds,
				fencingToken = current.fencingToken,
			}
		end)
	end)
	if not ok then
		local reason = tostring(valueOrFailure)
		self.diagnostics:record("error", "DATASTORE_LEASE_RENEW_FAILED", {
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
	if not renewed then
		return Result.err(
			"LEASE_LOST",
			"error.persistence.lease_lost",
			false,
			if currentRecord ~= nil then heldDetails(currentRecord) else nil
		)
	end
	local record = asRecord(valueOrFailure)
	if record == nil then
		return Result.err("LEASE_INVALID", "error.persistence.lease_invalid", false)
	end
	return Result.ok(record)
end

function LeaseStore.release(
	self: any,
	key: string,
	ownerId: string,
	token: string,
	now: number
): any
	if not validText(ownerId) or not validText(token) or not validTime(now) then
		return Result.err("LEASE_INVALID", "error.persistence.lease_invalid", false)
	end

	local released = false
	local currentRecord: LeaseRecord? = nil
	local ok, valueOrFailure = pcall(function()
		return self.store:UpdateAsync(key, function(currentValue: any): any
			local current = asRecord(currentValue)
			currentRecord = current
			if current == nil or current.ownerId ~= ownerId or current.token ~= token then
				return currentValue
			end
			released = true
			return {
				ownerId = ownerId,
				token = token,
				expiresAt = 0,
				fencingToken = current.fencingToken,
			}
		end)
	end)
	if not ok then
		local reason = tostring(valueOrFailure)
		self.diagnostics:record("error", "DATASTORE_LEASE_RELEASE_FAILED", {
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
	if not released then
		return Result.err(
			"LEASE_LOST",
			"error.persistence.lease_lost",
			false,
			if currentRecord ~= nil then heldDetails(currentRecord) else nil
		)
	end
	return Result.ok(true)
end

function LeaseStore.read(self: any, key: string): any
	local ok, valueOrFailure = pcall(function()
		return self.store:GetAsync(key)
	end)
	if not ok then
		local reason = tostring(valueOrFailure)
		self.diagnostics:record("error", "DATASTORE_LEASE_READ_FAILED", {
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
	if valueOrFailure == nil then
		return Result.ok(nil)
	end
	local record = asRecord(valueOrFailure)
	if record == nil then
		return Result.err("LEASE_INVALID", "error.persistence.lease_invalid", false)
	end
	return Result.ok(record)
end

return LeaseStore
