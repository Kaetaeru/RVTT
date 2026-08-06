--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DeepCopy = require(ReplicatedStorage.RVTT.Shared.Core.DeepCopy)
local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)
local ValueGuard = require(ReplicatedStorage.RVTT.Shared.Core.ValueGuard)

local DEFAULT_MAX_ATTEMPTS = 5
local DEFAULT_INITIAL_DELAY_SECONDS = 0.25
local DEFAULT_MAX_DELAY_SECONDS = 2
local DEFAULT_DEADLINE_SECONDS = 25

export type RetryPolicy = {
	maxAttempts: number?,
	initialDelaySeconds: number?,
	maxDelaySeconds: number?,
	deadlineSeconds: number?,
}

local PersistenceCoordinator = {}
PersistenceCoordinator.__index = PersistenceCoordinator

local function revisionOf(state: any): number?
	if type(state) ~= "table" or not ValueGuard.isFiniteNumber(state.revision) then
		return nil
	end
	local revision = state.revision :: number
	if revision < 0 or revision % 1 ~= 0 then
		return nil
	end
	return revision
end

local function failureSummary(result: any): string
	if result.ok then
		return "none"
	end
	local failure = result.error
	local reason = if type(failure.details) == "table" then failure.details.reason else nil
	if type(reason) == "string" then
		return string.format("%s: %s", failure.code, reason)
	end
	return failure.code
end

local function positiveNumber(value: number?, fallback: number): number
	if value == nil or not ValueGuard.isFiniteNumber(value) or value < 0 then
		return fallback
	end
	return value
end

local function positiveInteger(value: number?, fallback: number): number
	local candidate = positiveNumber(value, fallback)
	if candidate < 1 or candidate % 1 ~= 0 then
		return fallback
	end
	return candidate
end

function PersistenceCoordinator.new(store: any, key: string, diagnostics: any): any
	return setmetatable({
		store = store,
		key = key,
		diagnostics = diagnostics,
		dirty = nil,
		lastSavedRevision = -1,
		scheduled = false,
		flushing = false,
		flushCompleted = Instance.new("BindableEvent"),
	}, PersistenceCoordinator)
end

function PersistenceCoordinator.load(self: any): any
	local result = self.store:load(self.key)
	if result.ok then
		if result.value == nil then
			print(string.format("[RVTT Persistence] no saved document key=%s", self.key))
		else
			local revision = revisionOf(result.value)
			if revision ~= nil then
				self.lastSavedRevision = revision
			end
			print(
				string.format(
					"[RVTT Persistence] loaded key=%s revision=%s",
					self.key,
					tostring(revision)
				)
			)
		end
	else
		warn(
			string.format(
				"[RVTT Persistence] load failed key=%s %s",
				self.key,
				failureSummary(result)
			)
		)
	end
	return result
end

function PersistenceCoordinator.markDirty(self: any, state: any): boolean
	local revision = revisionOf(state)
	if revision == nil then
		self.diagnostics:increment("persistence.invalid_dirty_state")
		return false
	end
	local dirtyRevision = revisionOf(self.dirty)
	if
		revision <= self.lastSavedRevision or (dirtyRevision ~= nil and revision <= dirtyRevision)
	then
		return false
	end

	self.dirty = DeepCopy(state)
	if self.scheduled then
		return true
	end
	self.scheduled = true
	task.delay(5, function()
		self.scheduled = false
		self:flush()
	end)
	return true
end

function PersistenceCoordinator.flush(self: any): any
	while self.flushing do
		self.flushCompleted.Event:Wait()
	end
	if self.dirty == nil then
		return Result.ok(false)
	end

	self.flushing = true
	local snapshot = self.dirty
	local snapshotRevision = revisionOf(snapshot)
	local result = self.store:save(self.key, snapshot)
	if result.ok then
		if snapshotRevision ~= nil then
			self.lastSavedRevision = math.max(self.lastSavedRevision, snapshotRevision)
		end
		if self.dirty == snapshot then
			self.dirty = nil
		end
		print(
			string.format(
				"[RVTT Persistence] saved key=%s revision=%s",
				self.key,
				tostring(snapshotRevision)
			)
		)
	else
		self.diagnostics:increment("persistence.flush_failed")
		warn(
			string.format(
				"[RVTT Persistence] save failed key=%s revision=%s %s",
				tostring(self.key),
				tostring(snapshotRevision),
				failureSummary(result)
			)
		)
	end
	self.flushing = false
	self.flushCompleted:Fire()
	return result
end

function PersistenceCoordinator.flushUntilClean(self: any, policy: RetryPolicy?): any
	local retryPolicy = policy or {}
	local maxAttempts = positiveInteger(retryPolicy.maxAttempts, DEFAULT_MAX_ATTEMPTS)
	local initialDelay = positiveNumber(
		retryPolicy.initialDelaySeconds,
		DEFAULT_INITIAL_DELAY_SECONDS
	)
	local maxDelay = positiveNumber(retryPolicy.maxDelaySeconds, DEFAULT_MAX_DELAY_SECONDS)
	local deadline = positiveNumber(retryPolicy.deadlineSeconds, DEFAULT_DEADLINE_SECONDS)
	local startedAt = os.clock()
	local delaySeconds = math.min(initialDelay, maxDelay)
	local attempts = 0

	while self.dirty ~= nil or self.flushing do
		attempts += 1
		local result = self:flush()
		if result.ok then
			continue
		end

		local retryable = result.error.retryable == true
		local elapsed = os.clock() - startedAt
		if not retryable or attempts >= maxAttempts or elapsed >= deadline then
			self.diagnostics:increment("persistence.retry_exhausted")
			warn(
				string.format(
					"[RVTT Persistence Retry] result=EXHAUSTED key=%s attempts=%d elapsed=%.3f code=%s",
					self.key,
					attempts,
					elapsed,
					result.error.code
				)
			)
			return result
		end

		self.diagnostics:increment("persistence.retry_scheduled")
		local remaining = math.max(0, deadline - elapsed)
		local waitSeconds = math.min(delaySeconds, remaining)
		print(
			string.format(
				"[RVTT Persistence Retry] result=RETRYING key=%s attempt=%d wait=%.3f code=%s",
				self.key,
				attempts + 1,
				waitSeconds,
				result.error.code
			)
		)
		if waitSeconds > 0 then
			task.wait(waitSeconds)
		end
		delaySeconds = math.min(maxDelay, math.max(initialDelay, delaySeconds * 2))
	end
	print(
		string.format(
			"[RVTT Persistence Retry] result=PASS key=%s attempts=%d elapsed=%.3f",
			self.key,
			attempts,
			os.clock() - startedAt
		)
	)
	return Result.ok(true)
end

return PersistenceCoordinator
