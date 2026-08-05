--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if ReplicatedStorage:FindFirstChild("RVTT_TestMode") ~= nil then
	return
end

local player = Players.LocalPlayer
local SharedUI = ReplicatedStorage.RVTT.Shared.UI
local AccentPreference = require(SharedUI.AccentPreference)
local Tokens = require(SharedUI.DesignTokens)
local uiFolder = script.Parent.UI
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
gui.DisplayOrder = Tokens.Layer.Hud
gui.Parent = player:WaitForChild("PlayerGui")

local banner = require(components.StateBanner)()
banner.Parent = gui

local prompt = require(components.ActionPrompt)()
prompt.Parent = gui
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
settingsButton.Parent = gui

local settingsCorner = Instance.new("UICorner")
settingsCorner.CornerRadius = Tokens.Radius.SM
settingsCorner.Parent = settingsButton
local settingsStroke = Instance.new("UIStroke")
settingsStroke.Thickness = 1
settingsStroke.Transparency = 0.12
settingsStroke:SetAttribute("RVTTStrokeToken", "focus")
settingsStroke.Parent = settingsButton

local currentAccentId = AccentPreference.DEFAULT_ID
local previewGeneration = 0
local settingsContextActive = false
local settingsPanel: any
local setSettingsVisible: (boolean) -> ()

local function projectedAccent(payload: any): string
	if type(payload) ~= "table" or type(payload.domains) ~= "table" then
		return AccentPreference.DEFAULT_ID
	end
	local uiPreferences = payload.domains.ui_preferences
	if type(uiPreferences) ~= "table" or type(uiPreferences.byUser) ~= "table" then
		return AccentPreference.DEFAULT_ID
	end
	local preferences = uiPreferences.byUser[tostring(player.UserId)]
	if type(preferences) ~= "table" then
		return AccentPreference.DEFAULT_ID
	end
	return AccentPreference.normalize(preferences[AccentPreference.KEY])
end

local function applyAccent(value: any)
	currentAccentId = ThemeApplicator.apply(gui, value)
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
	ThemeApplicator.apply(settingsButton, currentAccentId)

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
	previewGeneration += 1
	local generation = previewGeneration
	applyAccent(id)
	client.Command:submit("ui.set_preference", {
		key = AccentPreference.KEY,
		value = id,
	})

	task.delay(3, function()
		if previewGeneration ~= generation then
			return
		end
		local authoritative = projectedAccent(client.Replica.payload)
		if authoritative ~= currentAccentId then
			previewGeneration += 1
			applyAccent(authoritative)
		end
	end)
end, function()
	setSettingsVisible(false)
end)
settingsPanel.Root.Parent = gui

settingsButton.Activated:Connect(function()
	setSettingsVisible(not settingsPanel:isVisible())
end)
settingsButton.MouseEnter:Connect(function()
	if not settingsPanel:isVisible() then
		settingsButton:SetAttribute("RVTTBackgroundToken", "accentHover")
		ThemeApplicator.apply(settingsButton, currentAccentId)
	end
end)
settingsButton.MouseLeave:Connect(function()
	settingsButton:SetAttribute(
		"RVTTBackgroundToken",
		if settingsPanel:isVisible() then "accentPressed" else "accent"
	)
	ThemeApplicator.apply(settingsButton, currentAccentId)
end)

local function render(payload: any, envelope: any)
	previewGeneration += 1
	applyAccent(projectedAccent(payload))

	local domains = if type(payload) == "table" then payload.domains else nil
	local session = if type(domains) == "table" then domains.session else nil
	local phase = if type(session) == "table" and type(session.phase) == "string"
		then session.phase
		else "loading"
	local revision = if type(envelope) == "table" and type(envelope.revision) == "number"
		then envelope.revision
		else client.Replica.revision
	banner.Text = string.format("RVTT · %s · revision %d", phase, revision)
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
