--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Identity = require(ReplicatedStorage.RVTT.Shared.Core.Identity)
local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)

local LeaseCoordinator = {}
LeaseCoordinator.__index = LeaseCoordinator

function LeaseCoordinator.new(
	store: any,
	key: string,
	ownerId: string,
	ttlSeconds: number,
	diagnostics: any,
	clock: (() -> number)?
): any
	return setmetatable({
		store = store,
		key = key,
		ownerId = ownerId,
		token = Identity.new("lease"),
		ttlSeconds = ttlSeconds,
		diagnostics = diagnostics,
		clock = clock or os.time,
		record = nil,
	}, LeaseCoordinator)
end

function LeaseCoordinator.acquire(self: any): any
	local result = self.store:acquire(
		self.key,
		self.ownerId,
		self.token,
		self.ttlSeconds,
		self.clock()
	)
	if result.ok then
		self.record = result.value
	else
		self.diagnostics:increment("persistence.lease_acquire_failed")
	end
	return result
end

function LeaseCoordinator.renew(self: any): any
	if self.record == nil then
		return Result.err("LEASE_NOT_HELD", "error.persistence.lease_not_held", false)
	end
	local result = self.store:renew(
		self.key,
		self.ownerId,
		self.token,
		self.ttlSeconds,
		self.clock()
	)
	if result.ok then
		self.record = result.value
	else
		self.record = nil
		self.diagnostics:increment("persistence.lease_renew_failed")
	end
	return result
end

function LeaseCoordinator.verify(self: any): any
	local localRecord = self.record
	if localRecord == nil then
		return Result.err("LEASE_NOT_HELD", "error.persistence.lease_not_held", false)
	end
	local now = self.clock()
	if localRecord.expiresAt <= now then
		self.record = nil
		return Result.err("LEASE_EXPIRED", "error.persistence.lease_expired", false)
	end

	local readResult = self.store:read(self.key)
	if not readResult.ok then
		return readResult
	end
	local current = readResult.value
	if
		current == nil
		or current.ownerId ~= self.ownerId
		or current.token ~= self.token
		or current.fencingToken ~= localRecord.fencingToken
		or current.expiresAt <= now
	then
		self.record = nil
		self.diagnostics:increment("persistence.lease_lost")
		return Result.err("LEASE_LOST", "error.persistence.lease_lost", false)
	end
	self.record = current
	return Result.ok(current)
end

function LeaseCoordinator.release(self: any): any
	if self.record == nil then
		return Result.err("LEASE_NOT_HELD", "error.persistence.lease_not_held", false)
	end
	local result = self.store:release(self.key, self.ownerId, self.token, self.clock())
	if result.ok then
		self.record = nil
	else
		self.diagnostics:increment("persistence.lease_release_failed")
	end
	return result
end

function LeaseCoordinator.fencingToken(self: any): number?
	return if self.record ~= nil then self.record.fencingToken else nil
end

function LeaseCoordinator.expiresAt(self: any): number?
	return if self.record ~= nil then self.record.expiresAt else nil
end

return LeaseCoordinator
