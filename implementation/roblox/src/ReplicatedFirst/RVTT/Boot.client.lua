--!strict

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

ReplicatedFirst:RemoveDefaultLoadingScreen()
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local previous = playerGui:FindFirstChild("RVTT_Loading")
if previous ~= nil then
	previous:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "RVTT_Loading"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false

local label = Instance.new("TextLabel")
label.Name = "Status"
label.Size = UDim2.fromScale(1, 1)
label.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
label.TextColor3 = Color3.fromRGB(238, 239, 242)
label.Text = "RVTT · 동기화 중"
label.TextSize = 22
label.Parent = gui
gui.Parent = playerGui

task.delay(15, function()
	if gui.Parent ~= nil then
		label.Text = "연결이 지연되고 있습니다. 다시 동기화합니다."
	end
end)
