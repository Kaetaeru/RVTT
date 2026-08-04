--!strict
local Queue={};Queue.__index=Queue
function Queue.new(preferences)return setmetatable({items={},running=false,preferences=preferences},Queue)end
function Queue:enqueue(intent)table.insert(self.items,intent);if not self.running then task.spawn(function()self:_drain()end)end end
function Queue:_drain()self.running=true;while #self.items>0 do local intent=table.remove(self.items,1);if not(self.preferences.reducedMotion and intent.importance=="ambient")then if intent.play then local ok,err=xpcall(intent.play,debug.traceback);if not ok then warn("[RVTT Presentation]",err)end end end;task.wait()end;self.running=false end
return Queue
