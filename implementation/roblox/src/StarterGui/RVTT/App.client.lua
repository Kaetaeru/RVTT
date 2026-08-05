--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if ReplicatedStorage:FindFirstChild("RVTT_TestMode") ~= nil then
	return
end

local player = Players.LocalPlayer
local Tokens = require(ReplicatedStorage.RVTT.Shared.UI.DesignTokens)
local components = script.Parent.UI.Components

local gui = Instance.new("ScreenGui")
gui.Name = "RVTT_App"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = Tokens.Layer.Hud
gui.Parent = player:WaitForChild("PlayerGui")

local banner = require(components.StateBanner)()
banner.Parent = gui
local prompt = require(components.ActionPrompt)()
prompt.Parent = gui

local playerScripts = player:WaitForChild("PlayerScripts")
local clientFolder = playerScripts:WaitForChild("RVTT"):WaitForChild("Client")
local ClientRuntime = require(clientFolder:WaitForChild("ClientRuntime"))
local client = ClientRuntime.await()

client.Replica.Changed:Connect(function(payload, envelope)
	local domains = payload.domains
	local session = if domains ~= nil then domains.session else nil
	local phase = if session ~= nil then session.phase else "loading"
	banner.Text = string.format("RVTT · %s · revision %d", phase, envelope.revision)
end)

client.Input:push("base_hud", 10, {
	Cancel = function()
		return false
	end,
	Confirm = function()
		return false
	end,
})
