--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.RVTT.Shared.Core.Signal)
local Contract = require(ReplicatedStorage.RVTT.Shared.Protocol.ProjectionContract)

local MAX_EPOCH_HISTORY = 8

export type ProjectionEnvelope = Contract.ProjectionEnvelope

export type Replica = {
	epoch: string?,
	revision: number,
	sequence: number,
	payload: { [string]: unknown },
	seenEpochs: { [string]: boolean },
	epochOrder: { string },
	Changed: any,
	GapDetected: any,
	apply: (self: Replica, envelope: ProjectionEnvelope, force: boolean?) -> boolean,
}

local Replica = {}
Replica.__index = Replica

local function rememberEpoch(self: Replica, epoch: string)
	if self.seenEpochs[epoch] then
		return
	end
	self.seenEpochs[epoch] = true
	table.insert(self.epochOrder, epoch)
	if #self.epochOrder > MAX_EPOCH_HISTORY then
		local expired = table.remove(self.epochOrder, 1)
		if expired ~= nil then
			self.seenEpochs[expired] = nil
		end
	end
end

function Replica.new(): Replica
	return setmetatable({
		epoch = nil,
		revision = -1,
		sequence = 0,
		payload = {},
		seenEpochs = {},
		epochOrder = {},
		Changed = Signal.new(),
		GapDetected = Signal.new(),
	}, Replica) :: any
end

function Replica.apply(self: Replica, envelope: ProjectionEnvelope, force: boolean?): boolean
	if type(envelope) ~= "table" or type(envelope.authorityEpoch) ~= "string" then
		return false
	end

	local sameEpoch = self.epoch == envelope.authorityEpoch
	if not sameEpoch and self.epoch ~= nil and self.seenEpochs[envelope.authorityEpoch] then
		return false
	end
	if sameEpoch and not force then
		if not Contract.isNewer(self.epoch, self.revision, envelope) then
			return false
		end
		if envelope.projectionSequence <= self.sequence then
			return false
		end
		if self.sequence > 0 and envelope.projectionSequence ~= self.sequence + 1 then
			self.GapDetected:Fire({
				expected = self.sequence + 1,
				received = envelope.projectionSequence,
				authorityEpoch = envelope.authorityEpoch,
			})
			return false
		end
	end

	if not sameEpoch then
		self.sequence = 0
		self.payload = {}
	end
	self.epoch = envelope.authorityEpoch
	self.revision = envelope.revision
	self.sequence = envelope.projectionSequence
	self.payload = envelope.payload
	rememberEpoch(self, envelope.authorityEpoch)
	self.Changed:Fire(self.payload, envelope)
	return true
end

return Replica
