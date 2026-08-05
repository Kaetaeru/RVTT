--!strict

local DeepCopy = require(game:GetService("ReplicatedStorage").RVTT.Shared.Core.DeepCopy)

local SnapshotJournal = {}
SnapshotJournal.__index = SnapshotJournal

function SnapshotJournal.new(maxEntries: number)
	return setmetatable(
		{ maxEntries = maxEntries, entries = {}, latestSnapshot = nil },
		SnapshotJournal
	)
end

function SnapshotJournal:record(state, event)
	self.latestSnapshot = DeepCopy(state)
	table.insert(self.entries, { revision = state.revision, event = DeepCopy(event) })
	while #self.entries > self.maxEntries do
		table.remove(self.entries, 1)
	end
end

function SnapshotJournal:restore()
	return DeepCopy(self.latestSnapshot)
end

function SnapshotJournal:eventsAfter(revision: number)
	local result = {}
	for _, entry in self.entries do
		if entry.revision > revision then
			table.insert(result, DeepCopy(entry))
		end
	end
	return result
end

return SnapshotJournal
