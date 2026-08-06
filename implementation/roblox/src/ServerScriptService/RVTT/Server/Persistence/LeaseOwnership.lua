--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)
local ValueGuard = require(ReplicatedStorage.RVTT.Shared.Core.ValueGuard)

export type Options = {
	renewIntervalSeconds: number?,
	retryIntervalSeconds: number?,
}

local DEFAULT_RENEW_INTERVAL_SECONDS = 10
local DEFAULT_RETRY_INTERVAL_SECONDS = 2

local LeaseOwnership = {}
LeaseOwnership.__index = LeaseOwnership

local function nonNegative(value: number?, fallback: number): number
	if value == nil or not ValueGuard.isFiniteNumber(value) or value < 0 then
		return fallback
	end
	return value
end

function LeaseOwnership.new(coordinator: any, diagnostics: any, options: Options?): any
	local resolved: Options = if options ~= nil then options else {}
	return setmetatable({
		coordinator = coordinator,
		diagnostics = diagnostics,
		active = false,
		closing = false,
		renewalStarted = false,
		lastFailure = nil,
		renewIntervalSeconds = nonNegative(
			resolved.renewIntervalSeconds,
			DEFAULT_RENEW_INTERVAL_SECONDS
		),
		retryIntervalSeconds = nonNegative(
			resolved.retryIntervalSeconds,
			DEFAULT_RETRY_INTERVAL_SECONDS
		),
	}, LeaseOwnership)
end

function LeaseOwnership.acquire(self: any): any
	if self.closing then
		return Result.err("LEASE_SHUTTING_DOWN", "error.persistence.lease_shutting_down", false)
	end
	local result = self.coordinator:acquire()
	self.active = result.ok
	self.lastFailure = if result.ok then nil else result
	if result.ok then
		self.diagnostics:increment("persistence.lease_acquired")
	else
		self.diagnostics:increment("persistence.lease_unavailable")
	end
	return result
end

function LeaseOwnership.guardLocal(self: any): any
	if not self.active then
		if self.lastFailure ~= nil then
			return self.lastFailure
		end
		return Result.err("LEASE_NOT_HELD", "error.persistence.lease_not_held", false)
	end
	local result = self.coordinator:validateLocal()
	if not result.ok then
		self.active = false
		self.lastFailure = result
		self.diagnostics:increment("persistence.lease_guard_failed")
	end
	return result
end

function LeaseOwnership.verifyRemote(self: any): any
	local localResult = self:guardLocal()
	if not localResult.ok then
		return localResult
	end
	local result = self.coordinator:verify()
	if not result.ok then
		if result.error.code ~= "PERSISTENCE_FAILED" then
			self.active = false
			self.lastFailure = result
		end
		self.diagnostics:increment("persistence.lease_verify_failed")
	end
	return result
end

function LeaseOwnership.renewOnce(self: any): any
	if self.closing then
		return Result.err("LEASE_SHUTTING_DOWN", "error.persistence.lease_shutting_down", false)
	end
	local localResult = self:guardLocal()
	if not localResult.ok then
		return localResult
	end

	local result = self.coordinator:renew()
	if result.ok then
		self.lastFailure = nil
		self.diagnostics:increment("persistence.lease_renewed")
		return result
	end

	if result.error.code == "PERSISTENCE_FAILED" then
		local stillValid = self.coordinator:validateLocal()
		if stillValid.ok then
			self.diagnostics:increment("persistence.lease_renew_retryable")
			return result
		end
		self.active = false
		self.lastFailure = stillValid
		return stillValid
	end

	self.active = false
	self.lastFailure = result
	self.diagnostics:increment("persistence.lease_lost")
	return result
end

function LeaseOwnership.startRenewal(self: any)
	if self.renewalStarted or self.closing or not self.active then
		return
	end
	self.renewalStarted = true
	task.spawn(function()
		while self.active and not self.closing do
			task.wait(self.renewIntervalSeconds)
			if not self.active or self.closing then
				break
			end
			local result = self:renewOnce()
			if
				not result.ok
				and result.error.code == "PERSISTENCE_FAILED"
				and self.active
				and self.retryIntervalSeconds > 0
			then
				task.wait(self.retryIntervalSeconds)
			end
		end
	end)
end

function LeaseOwnership.writeFence(self: any): any
	local localResult = self:guardLocal()
	if not localResult.ok then
		return localResult
	end
	return self.coordinator:writeFence()
end

function LeaseOwnership.beginShutdown(self: any)
	self.closing = true
end

function LeaseOwnership.release(self: any): any
	if not self.active then
		if self.lastFailure ~= nil then
			return self.lastFailure
		end
		return Result.err("LEASE_NOT_HELD", "error.persistence.lease_not_held", false)
	end
	local result = self.coordinator:release()
	self.active = false
	self.lastFailure = if result.ok then nil else result
	if result.ok then
		self.diagnostics:increment("persistence.lease_released")
	else
		self.diagnostics:increment("persistence.lease_release_failed")
	end
	return result
end

function LeaseOwnership.isActive(self: any): boolean
	return self.active
end

return LeaseOwnership
