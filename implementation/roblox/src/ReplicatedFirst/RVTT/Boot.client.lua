--!strict
local ReplicatedFirst=game:GetService("ReplicatedFirst");local Players=game:GetService("Players")
ReplicatedFirst:RemoveDefaultLoadingScreen()
local gui=Instance.new("ScreenGui");gui.Name="RVTT_Loading";gui.IgnoreGuiInset=true;gui.ResetOnSpawn=false
local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundColor3=Color3.fromRGB(18,20,24);label.TextColor3=Color3.fromRGB(238,239,242);label.Text="RVTT · 동기화 중";label.TextSize=22;label.Parent=gui
gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
task.delay(15,function()if gui.Parent then label.Text="연결이 지연되고 있습니다. 다시 동기화합니다."end end)
_G.RVTTLoadingGui=gui
