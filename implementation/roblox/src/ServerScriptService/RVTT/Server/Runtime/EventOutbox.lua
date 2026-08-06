--!strict

export type Event = {
	sequence: number,
	eventType: string,
	payload: { [string]: unknown },
}

export type EventOutbox = {
	sequence: number,
	events: { Event },
	subscribers: { [string]: { (Event) -> () } },
	subscribe: (self: EventOutbox, eventType: string, callback: (Event) -> ()) -> (),
	append: (self: EventOutbox, eventType: string, payload: { [string]: unknown }) -> Event,
	after: (self: EventOutbox, sequence: number) -> { Event },
}

local EventOutbox = {}
EventOutbox.__index = EventOutbox

function EventOutbox.new(): EventOutbox
	return setmetatable({
		sequence = 0,
		events = {},
		subscribers = {},
	}, EventOutbox) :: any
end

function EventOutbox.subscribe(self: EventOutbox, eventType: string, callback: (Event) -> ())
	local subscribers = self.subscribers[eventType]
	if subscribers == nil then
		subscribers = {}
		self.subscribers[eventType] = subscribers
	end
	table.insert(subscribers, callback)
end

function EventOutbox.append(
	self: EventOutbox,
	eventType: string,
	payload: { [string]: unknown }
): Event
	self.sequence += 1
	local event: Event = {
		sequence = self.sequence,
		eventType = eventType,
		payload = payload,
	}
	table.insert(self.events, event)
	local subscribers = self.subscribers[eventType]
	if subscribers ~= nil then
		for _, callback in subscribers do
			task.spawn(callback, event)
		end
	end
	return event
end

function EventOutbox.after(self: EventOutbox, sequence: number): { Event }
	local result: { Event } = {}
	for _, event in self.events do
		if event.sequence > sequence then
			table.insert(result, event)
		end
	end
	return result
end

return EventOutbox
