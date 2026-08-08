--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if ReplicatedStorage:FindFirstChild("RVTT_TestMode") ~= nil then
	return
end

local player = Players.LocalPlayer
local SharedUI = ReplicatedStorage.RVTT.Shared.UI
local Tokens = require(SharedUI.DesignTokens)
local uiFolder = script.Parent.UI
local AppShell = require(uiFolder.AppShell)
local ThemeApplicator = require(uiFolder.ThemeApplicator)
local SettingsPanel = require(uiFolder.Components.SettingsPanel)
local components = uiFolder.Components

local playerScripts = player:WaitForChild("PlayerScripts")
local clientFolder = playerScripts:WaitForChild("RVTT"):WaitForChild("Client")
local ClientRuntime = require(clientFolder:WaitForChild("ClientRuntime"))
local client = ClientRuntime.await()

local gui = Instance.new("ScreenGui")
gui.Name = "RVTT_App"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 0
gui.Parent = player:WaitForChild("PlayerGui")
local shell = AppShell.new(gui)

local banner = require(components.StateBanner)()
banner.Parent = shell:getLayer("System")

local prompt = require(components.ActionPrompt)()
prompt.Parent = shell:getLayer("Prompt")
local promptText = prompt:FindFirstChildWhichIsA("TextLabel")

local settingsButton = Instance.new("TextButton")
settingsButton.Name = "SettingsButton"
settingsButton.Size = UDim2.fromOffset(116, 40)
settingsButton.Position = UDim2.new(1, -132, 0, 16)
settingsButton.AutoButtonColor = false
settingsButton.Text = "설정"
settingsButton.TextSize = Tokens.TextSize.Body
settingsButton.BorderSizePixel = 0
settingsButton.Selectable = true
settingsButton.SelectionOrder = 1
settingsButton:SetAttribute("RVTTBackgroundToken", "accent")
settingsButton:SetAttribute("RVTTTextToken", "accentOn")
settingsButton.Parent = shell:getLayer("System")

local settingsCorner = Instance.new("UICorner")
settingsCorner.CornerRadius = Tokens.Radius.SM
settingsCorner.Parent = settingsButton
local settingsStroke = Instance.new("UIStroke")
settingsStroke.Thickness = 1
settingsStroke.Transparency = 0.12
settingsStroke:SetAttribute("RVTTStrokeToken", "focus")
settingsStroke.Parent = settingsButton

local currentAccentId = "gold"
local settingsContextActive = false
local settingsPanel: any
local setSettingsVisible: (boolean) -> ()

local function applyPreferences()
	local preferences = client.Preferences:snapshot()
	currentAccentId = ThemeApplicator.apply(shell.Root, preferences)
	if settingsPanel ~= nil then
		settingsPanel:setSelected(currentAccentId)
	end
end

local function updatePrompt(settingsVisible: boolean)
	if promptText == nil then
		return
	end
	promptText.Text = if settingsVisible then "Q 설정 닫기" else "Q 취소    E 확인"
end

setSettingsVisible = function(visible: boolean)
	settingsPanel:setVisible(visible)
	updatePrompt(visible)
	settingsButton:SetAttribute(
		"RVTTBackgroundToken",
		if visible then "accentPressed" else "accent"
	)
	ThemeApplicator.apply(settingsButton, client.Preferences:snapshot())

	if visible and not settingsContextActive then
		settingsContextActive = true
		client.Input:push("settings_modal", 100, {
			Cancel = function()
				setSettingsVisible(false)
				return true
			end,
			Confirm = function()
				return false
			end,
		})
	elseif not visible and settingsContextActive then
		settingsContextActive = false
		client.Input:remove("settings_modal")
	end
end

settingsPanel = SettingsPanel.new(function(id: string)
	client.Preferences:set("accentPaletteId", id)
end, function()
	setSettingsVisible(false)
end)
settingsPanel.Root.Parent = shell:getLayer("Overlay")

client.Preferences.Changed:Connect(function()
	applyPreferences()
end)
applyPreferences()

settingsButton.Activated:Connect(function()
	setSettingsVisible(not settingsPanel:isVisible())
end)
settingsButton.MouseEnter:Connect(function()
	if not settingsPanel:isVisible() then
		settingsButton:SetAttribute("RVTTBackgroundToken", "accentHover")
		ThemeApplicator.apply(settingsButton, client.Preferences:snapshot())
	end
end)
settingsButton.MouseLeave:Connect(function()
	settingsButton:SetAttribute(
		"RVTTBackgroundToken",
		if settingsPanel:isVisible() then "accentPressed" else "accent"
	)
	ThemeApplicator.apply(settingsButton, client.Preferences:snapshot())
end)

local function render(payload: any, envelope: any)
	shell:applyProjection(payload, player.UserId)

	local domains = if type(payload) == "table" then payload.domains else nil
	local session = if type(domains) == "table" then domains.session else nil
	local phase = if type(session) == "table" and type(session.phase) == "string"
		then session.phase
		else "loading"
	local revision = if type(envelope) == "table" and type(envelope.revision) == "number"
		then envelope.revision
		else client.Replica.revision
	banner.Text = string.format(
		"RVTT · %s · %s · %s · revision %d",
		shell.role,
		shell.mode,
		phase,
		revision
	)
end

client.Replica.Changed:Connect(render)
render(client.Replica.payload, { revision = client.Replica.revision })

client.Input:push("base_hud", 10, {
	Cancel = function()
		return false
	end,
	Confirm = function()
		return false
	end,
})

