--!strict

local EventOutbox = {}
EventOutbox.__index = EventOutbox

function EventOutbox.new()
	return setmetatable({ sequence = 0, events = {}, subscribers = {} }, EventOutbox)
end

function EventOutbox:subscribe(eventType: string, callback)
	self.subscribers[eventType] = self.subscribers[eventType] or {}
	table.insert(self.subscribers[eventType], callback)
end

function EventOutbox:append(eventType: string, payload: { [string]: unknown })
	self.sequence += 1
	local event = { sequence = self.sequence, eventType = eventType, payload = payload }
	table.insert(self.events, event)
	for _, callback in self.subscribers[eventType] or {} do
		task.spawn(callback, event)
	end
	return event
end

function EventOutbox:after(sequence: number)
	local result = {}
	for _, event in self.events do
		if event.sequence > sequence then
			table.insert(result, event)
		end
	end
	return result
end

return EventOutbox
