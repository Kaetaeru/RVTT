--!strict

export type Handler = (...any) -> boolean
export type Entry = {
	id: string,
	priority: number,
	handlers: { [string]: Handler },
}
export type InputContextStack = {
	entries: { Entry },
	push: (
		self: InputContextStack,
		id: string,
		priority: number,
		handlers: { [string]: Handler }
	) -> (),
	remove: (self: InputContextStack, id: string) -> (),
	dispatch: (self: InputContextStack, action: string, payload: any) -> boolean,
}

local Stack = {}
Stack.__index = Stack

function Stack.new(): InputContextStack
	return setmetatable({ entries = {} }, Stack) :: any
end

function Stack.push(
	self: InputContextStack,
	id: string,
	priority: number,
	handlers: { [string]: Handler }
)
	self:remove(id)
	table.insert(self.entries, { id = id, priority = priority, handlers = handlers })
	table.sort(self.entries, function(left, right)
		return left.priority > right.priority
	end)
end

function Stack.remove(self: InputContextStack, id: string)
	for index, entry in self.entries do
		if entry.id == id then
			table.remove(self.entries, index)
			return
		end
	end
end

function Stack.dispatch(self: InputContextStack, action: string, payload: any): boolean
	for _, entry in self.entries do
		local handler = entry.handlers[action]
		if handler ~= nil and handler(payload) then
			return true
		end
	end
	return false
end

return Stack
