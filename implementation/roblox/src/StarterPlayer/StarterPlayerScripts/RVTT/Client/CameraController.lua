--!strict
local Workspace=game:GetService("Workspace");local Controller={};Controller.__index=Controller
function Controller.new()return setmetatable({stack={}},Controller)end
function Controller:request(request)table.insert(self.stack,{previous=Workspace.CurrentCamera.CFrame,request=request});if request.cframe then Workspace.CurrentCamera.CFrame=request.cframe end end
function Controller:complete()local entry=table.remove(self.stack);if entry then Workspace.CurrentCamera.CFrame=entry.previous end end
return Controller
