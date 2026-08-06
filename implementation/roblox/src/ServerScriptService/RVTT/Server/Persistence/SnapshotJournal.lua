--!strict

local DeepCopy = require(game:GetService("ReplicatedStorage").RVTT.Shared.Core.DeepCopy)

export type Entry = {
	revision: number,
	event: any,
}

export type SnapshotJournal = {
	maxEntries: number,
	entries: { Entry },
	latestSnapshot: any?,
	record: (self: SnapshotJournal, state: any, event: any) -> (),
	restore: (self: SnapshotJournal) -> any?,
	eventsAfter: (self: SnapshotJournal, revision: number) -> { Entry },
}

local SnapshotJournal = {}
SnapshotJournal.__index = SnapshotJournal

function SnapshotJournal.new(maxEntries: number): SnapshotJournal
	return setmetatable({
		maxEntries = maxEntries,
		entries = {},
		latestSnapshot = nil,
	}, SnapshotJournal) :: any
end

function SnapshotJournal.record(self: SnapshotJournal, state: any, event: any)
	self.latestSnapshot = DeepCopy(state)
	table.insert(self.entries, {
		revision = state.revision,
		event = DeepCopy(event),
	})
	while #self.entries > self.maxEntries do
		table.remove(self.entries, 1)
	end
end

function SnapshotJournal.restore(self: SnapshotJournal): any?
	return DeepCopy(self.latestSnapshot)
end

function SnapshotJournal.eventsAfter(self: SnapshotJournal, revision: number): { Entry }
	local result: { Entry } = {}
	for _, entry in self.entries do
		if entry.revision > revision then
			table.insert(result, DeepCopy(entry))
		end
	end
	return result
end

return SnapshotJournal
