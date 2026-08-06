--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DeepCopy = require(ReplicatedStorage.RVTT.Shared.Core.DeepCopy)
local Result = require(ReplicatedStorage.RVTT.Shared.Core.Result)
local ValueGuard = require(ReplicatedStorage.RVTT.Shared.Core.ValueGuard)

export type FaultStep = {
	kind: "fail" | "conflict" | "commit_then_fail" | "value",
	code: string?,
	retryable: boolean?,
	value: any?,
}

local FaultStore = {}
FaultStore.__index = FaultStore

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

local function failure(step: FaultStep, fallbackCode: string): any
	local code = step.code or fallbackCode
	return Result.err(
		code,
		if code == "PERSISTENCE_CONFLICT" then "error.persistence.conflict" else "error.persistence.failed",
		if step.retryable == nil then true else step.retryable,
		{ reason = "fault host injected " .. step.kind }
	)
end

function FaultStore.new(initialDocuments: { [string]: any }?): any
	return setmetatable({
		documents = DeepCopy(initialDocuments or {}),
		scripts = {
			load = {},
			save = {},
		},
		metrics = {
			loads = 0,
			saves = 0,
			failures = 0,
			conflicts = 0,
			committedWrites = 0,
			commitAckLosses = 0,
		},
	}, FaultStore)
end

function FaultStore.queue(self: any, operation: "load" | "save", step: FaultStep)
	table.insert(self.scripts[operation], step)
end

function FaultStore._next(self: any, operation: "load" | "save"): FaultStep?
	if #self.scripts[operation] == 0 then
		return nil
	end
	return table.remove(self.scripts[operation], 1)
end

function FaultStore.load(self: any, key: string): any
	self.metrics.loads += 1
	local step = self:_next("load")
	if step ~= nil then
		if step.kind == "fail" then
			self.metrics.failures += 1
			return failure(step, "PERSISTENCE_FAILED")
		end
		if step.kind == "value" then
			return Result.ok(DeepCopy(step.value))
		end
	end
	return Result.ok(DeepCopy(self.documents[key]))
end

function FaultStore.save(self: any, key: string, value: any): any
	self.metrics.saves += 1
	local step = self:_next("save")
	if step ~= nil then
		if step.kind == "fail" then
			self.metrics.failures += 1
			return failure(step, "PERSISTENCE_FAILED")
		end
		if step.kind == "conflict" then
			self.metrics.failures += 1
			self.metrics.conflicts += 1
			return failure(step, "PERSISTENCE_CONFLICT")
		end
		if step.kind == "commit_then_fail" then
			self.documents[key] = DeepCopy(value)
			self.metrics.committedWrites += 1
			self.metrics.commitAckLosses += 1
			self.metrics.failures += 1
			return failure(step, "PERSISTENCE_FAILED")
		end
	end

	local candidateRevision = revisionOf(value)
	if candidateRevision == nil then
		self.metrics.failures += 1
		return Result.err("PERSISTENCE_INVALID", "error.persistence.invalid", false)
	end
	local current = self.documents[key]
	local currentRevision = revisionOf(current)
	if currentRevision ~= nil then
		if currentRevision > candidateRevision then
			self.metrics.failures += 1
			self.metrics.conflicts += 1
			return Result.err("PERSISTENCE_CONFLICT", "error.persistence.conflict", true)
		end
		if
			currentRevision == candidateRevision
			and current.authorityEpoch ~= nil
			and value.authorityEpoch ~= nil
			and current.authorityEpoch ~= value.authorityEpoch
		then
			self.metrics.failures += 1
			self.metrics.conflicts += 1
			return Result.err("PERSISTENCE_CONFLICT", "error.persistence.conflict", true)
		end
	end

	self.documents[key] = DeepCopy(value)
	self.metrics.committedWrites += 1
	return Result.ok(true)
end

function FaultStore.put(self: any, key: string, value: any)
	self.documents[key] = DeepCopy(value)
end

function FaultStore.document(self: any, key: string): any
	return DeepCopy(self.documents[key])
end

function FaultStore.metricsSnapshot(self: any): any
	return table.clone(self.metrics)
end

return FaultStore
