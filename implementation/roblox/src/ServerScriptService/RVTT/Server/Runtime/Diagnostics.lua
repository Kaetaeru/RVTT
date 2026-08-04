--!strict

local Diagnostics = {}
Diagnostics.__index = Diagnostics

function Diagnostics.new()
	return setmetatable({ counters = {}, incidents = {} }, Diagnostics)
end

function Diagnostics:increment(name: string)
	self.counters[name] = (self.counters[name] or 0) + 1
end

function Diagnostics:record(level: string, code: string, context: { [string]: unknown }?)
	local incident = {
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

function Diagnostics:snapshot()
	return { counters = table.clone(self.counters), incidentCount = #self.incidents }
end

return Diagnostics
