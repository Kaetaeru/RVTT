--!strict

export type Incident = {
	timestamp: number,
	level: string,
	code: string,
	context: { [string]: unknown },
}

export type Diagnostics = {
	counters: { [string]: number },
	incidents: { Incident },
	increment: (self: Diagnostics, name: string) -> (),
	record: (
		self: Diagnostics,
		level: string,
		code: string,
		context: { [string]: unknown }?
	) -> (),
	snapshot: (self: Diagnostics) -> {
		counters: { [string]: number },
		incidentCount: number,
	},
}

local Diagnostics = {}
Diagnostics.__index = Diagnostics

function Diagnostics.new(): Diagnostics
	return setmetatable({
		counters = {},
		incidents = {},
	}, Diagnostics) :: any
end

function Diagnostics.increment(self: Diagnostics, name: string)
	self.counters[name] = (self.counters[name] or 0) + 1
end

function Diagnostics.record(
	self: Diagnostics,
	level: string,
	code: string,
	context: { [string]: unknown }?
)
	local incident: Incident = {
		timestamp = DateTime.now().UnixTimestampMillis,
		level = level,
		code = code,
		context = context or {},
	}
	table.insert(self.incidents, incident)
	if level == "error" then
		warn("[RVTT]", code, incident.context)
	end
end

function Diagnostics.snapshot(self: Diagnostics)
	return {
		counters = table.clone(self.counters),
		incidentCount = #self.incidents,
	}
end

return Diagnostics
