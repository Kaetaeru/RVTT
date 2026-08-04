--!strict
local Stack={};Stack.__index=Stack
function Stack.new()return setmetatable({entries={}},Stack)end
function Stack:push(id,priority,handlers)table.insert(self.entries,{id=id,priority=priority,handlers=handlers});table.sort(self.entries,function(a,b)return a.priority>b.priority end)end
function Stack:remove(id)for i,e in self.entries do if e.id==id then table.remove(self.entries,i);return end end end
function Stack:dispatch(action,payload)for _,e in self.entries do local h=e.handlers[action];if h~=nil and h(payload)then return true end end;return false end
return Stack
