--!strict

local Stack = {}
Stack.__index = Stack

function Stack.new()
    return setmetatable({ entries = {} }, Stack)
end

function Stack:push(id: string, priority: number, handlers)
    self:remove(id)
    table.insert(self.entries, { id = id, priority = priority, handlers = handlers })
    table.sort(self.entries, function(left, right)
        return left.priority > right.priority
    end)
end

function Stack:remove(id: string)
    for index, entry in self.entries do
        if entry.id == id then
            table.remove(self.entries, index)
            return
        end
    end
end

function Stack:dispatch(action: string, payload): boolean
    for _, entry in self.entries do
        local handler = entry.handlers[action]
        if handler ~= nil and handler(payload) then
            return true
        end
    end
    return false
end

return Stack
