--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DeepCopy = require(ReplicatedStorage.RVTT.Shared.Core.DeepCopy)
local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)
local ValueGuard = require(ReplicatedStorage.RVTT.Shared.Core.ValueGuard)

local PersistenceCoordinator = {}
PersistenceCoordinator.__index = PersistenceCoordinator

local function revisionOf(state): number?
	if type(state) ~= "table" or not ValueGuard.isFiniteNumber(state.revision) then
		return nil
	end
	local revision = state.revision :: number
	if revision < 0 or revision % 1 ~= 0 then
		return nil
	end
	return revision
end

function PersistenceCoordinator.new(store, key: string, diagnostics)
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

function PersistenceCoordinator:load()
	local result = self.store:load(self.key)
	if result.ok and result.value ~= nil then
		local revision = revisionOf(result.value)
		if revision ~= nil then
			self.lastSavedRevision = revision
		end
	end
	return result
end

function PersistenceCoordinator:markDirty(state)
	local revision = revisionOf(state)
	if revision == nil then
		self.diagnostics:increment("persistence.invalid_dirty_state")
		return false
	end
	local dirtyRevision = revisionOf(self.dirty)
	if revision <= self.lastSavedRevision or (dirtyRevision ~= nil and revision <= dirtyRevision) then
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

function PersistenceCoordinator:flush()
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
	else
		self.diagnostics:increment("persistence.flush_failed")
	end
	self.flushing = false
	self.flushCompleted:Fire()
	return result
end

function PersistenceCoordinator:flushUntilClean()
	while self.dirty ~= nil or self.flushing do
		local result = self:flush()
		if not result.ok then
			return result
		end
	end
	return Result.ok(true)
end

return PersistenceCoordinator
