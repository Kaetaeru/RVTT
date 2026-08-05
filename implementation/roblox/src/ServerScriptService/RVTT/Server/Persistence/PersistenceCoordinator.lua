--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DeepCopy = require(ReplicatedStorage.RVTT.Shared.Core.DeepCopy)
local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)

local PersistenceCoordinator = {}
PersistenceCoordinator.__index = PersistenceCoordinator

function PersistenceCoordinator.new(store, key: string, diagnostics)
	return setmetatable({
		store = store,
		key = key,
		diagnostics = diagnostics,
		dirty = nil,
		scheduled = false,
		flushing = false,
	}, PersistenceCoordinator)
end

function PersistenceCoordinator:load()
	return self.store:load(self.key)
end

function PersistenceCoordinator:markDirty(state)
	self.dirty = DeepCopy(state)
	if self.scheduled then
		return
	end
	self.scheduled = true
	task.delay(5, function()
		self.scheduled = false
		self:flush()
	end)
end

function PersistenceCoordinator:flush()
	if self.flushing or self.dirty == nil then
		return Result.ok(false)
	end
	self.flushing = true
	local snapshot = self.dirty
	local result = self.store:save(self.key, snapshot)
	if result.ok and self.dirty == snapshot then
		self.dirty = nil
	elseif not result.ok then
		self.diagnostics:increment("persistence.flush_failed")
	end
	self.flushing = false
	return result
end

return PersistenceCoordinator
