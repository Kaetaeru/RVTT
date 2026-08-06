--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DeepCopy = require(ReplicatedStorage.RVTT.Shared.Core.DeepCopy)

export type FaultMode = "deliver" | "drop" | "duplicate" | "hold"

export type Metrics = {
	sent: number,
	delivered: number,
	dropped: number,
	duplicated: number,
	held: number,
	released: number,
}

type Packet = {
	label: string,
	payload: any,
	deliver: (any) -> (),
}

local FaultTransport = {}
FaultTransport.__index = FaultTransport

local function copyPacket(packet: Packet): Packet
	return {
		label = packet.label,
		payload = DeepCopy(packet.payload),
		deliver = packet.deliver,
	}
end

function FaultTransport.new(): any
	return setmetatable({
		ready = {},
		held = {},
		metrics = {
			sent = 0,
			delivered = 0,
			dropped = 0,
			duplicated = 0,
			held = 0,
			released = 0,
		},
	}, FaultTransport)
end

function FaultTransport.send(
	self: any,
	label: string,
	payload: any,
	deliver: (any) -> (),
	mode: FaultMode?
)
	local selectedMode = mode or "deliver"
	local packet: Packet = {
		label = label,
		payload = DeepCopy(payload),
		deliver = deliver,
	}
	self.metrics.sent += 1

	if selectedMode == "drop" then
		self.metrics.dropped += 1
		return
	end
	if selectedMode == "hold" then
		local heldPackets = self.held[label]
		if heldPackets == nil then
			heldPackets = {}
			self.held[label] = heldPackets
		end
		table.insert(heldPackets, packet)
		self.metrics.held += 1
		return
	end

	table.insert(self.ready, packet)
	if selectedMode == "duplicate" then
		table.insert(self.ready, copyPacket(packet))
		self.metrics.duplicated += 1
	end
end

function FaultTransport.release(self: any, label: string, front: boolean?): number
	local heldPackets = self.held[label]
	if heldPackets == nil then
		return 0
	end
	self.held[label] = nil
	local released = #heldPackets
	if front then
		for index = released, 1, -1 do
			table.insert(self.ready, 1, heldPackets[index])
		end
	else
		for _, packet in heldPackets do
			table.insert(self.ready, packet)
		end
	end
	self.metrics.released += released
	return released
end

function FaultTransport.reverseReady(self: any)
	local reversed = {}
	for index = #self.ready, 1, -1 do
		table.insert(reversed, self.ready[index])
	end
	self.ready = reversed
end

function FaultTransport.flush(self: any): number
	local ready = self.ready
	self.ready = {}
	for _, packet in ready do
		packet.deliver(DeepCopy(packet.payload))
		self.metrics.delivered += 1
	end
	return #ready
end

function FaultTransport.readyCount(self: any): number
	return #self.ready
end

function FaultTransport.heldCount(self: any): number
	local count = 0
	for _, packets in self.held do
		count += #packets
	end
	return count
end

function FaultTransport.metricsSnapshot(self: any): Metrics
	return table.clone(self.metrics)
end

return FaultTransport
