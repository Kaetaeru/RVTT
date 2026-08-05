--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.RVTT.Shared.Core.Signal)
local Contract = require(ReplicatedStorage.RVTT.Shared.Protocol.ProjectionContract)

export type ProjectionEnvelope = Contract.ProjectionEnvelope

export type Replica = {
	epoch: string?,
	revision: number,
	sequence: number,
	payload: { [string]: unknown },
	Changed: any,
	GapDetected: any,
	apply: (self: Replica, envelope: ProjectionEnvelope, force: boolean?) -> boolean,
}

local Replica = {}
Replica.__index = Replica

function Replica.new(): Replica
	return setmetatable({
		epoch = nil,
		revision = -1,
		sequence = 0,
		payload = {},
		Changed = Signal.new(),
		GapDetected = Signal.new(),
	}, Replica) :: any
end

function Replica.apply(self: Replica, envelope: ProjectionEnvelope, force: boolean?): boolean
	if type(envelope) ~= "table" or type(envelope.authorityEpoch) ~= "string" then
		return false
	end
	local sameEpoch = self.epoch == envelope.authorityEpoch
	if not force and not Contract.isNewer(self.epoch, self.revision, envelope) then
		return false
	end
	if
		sameEpoch
		and not force
		and self.sequence > 0
		and envelope.projectionSequence ~= self.sequence + 1
	then
		self.GapDetected:Fire({
			expected = self.sequence + 1,
			received = envelope.projectionSequence,
			authorityEpoch = envelope.authorityEpoch,
		})
		return false
	end
	if not sameEpoch then
		self.sequence = 0
		self.payload = {}
	end
	self.epoch = envelope.authorityEpoch
	self.revision = envelope.revision
	self.sequence = envelope.projectionSequence
	self.payload = envelope.payload
	self.Changed:Fire(self.payload, envelope)
	return true
end

return Replica
