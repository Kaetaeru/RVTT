--!strict

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShellContract = require(ReplicatedStorage.RVTT.Shared.UI.ShellContract)
local Tokens = require(ReplicatedStorage.RVTT.Shared.UI.DesignTokens)

local AppShell = {}
AppShell.__index = AppShell

local surfaceNames = {
	gameplay = "GameplaySurface",
	management = "ManagementSurface",
	session = "SessionSurface",
	dm = "DmSurface",
}

local function layer(parent: Instance, name: string, zIndex: number): Frame
	local value = Instance.new("Frame")
	value.Name = name
	value.Size = UDim2.fromScale(1, 1)
	value.BackgroundTransparency = 1
	value.BorderSizePixel = 0
	value.ZIndex = zIndex
	value.Parent = parent
	return value
end

local function isSelectable(object: GuiObject?): boolean
	return object ~= nil and object.Selectable and object.Visible
end

function AppShell.new(gui: ScreenGui): any
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	local self: any = setmetatable({}, AppShell)
	local root = layer(gui, "AppShell", 0)
	self.Root = root
	self.role = "observer"
	self.mode = "session"
	self.surface = "session"
	self.selectionBySurface = {}
	self.layers = {
		Gameplay = layer(root, surfaceNames.gameplay, Tokens.Layer.Surface),
		Management = layer(root, surfaceNames.management, Tokens.Layer.Surface),
		Session = layer(root, surfaceNames.session, Tokens.Layer.Surface),
		Dm = layer(root, surfaceNames.dm, Tokens.Layer.Surface),
		System = layer(root, "SystemLayer", Tokens.Layer.System),
		Overlay = layer(root, "OverlayLayer", Tokens.Layer.Overlay),
		Prompt = layer(root, "PromptLayer", Tokens.Layer.Prompt),
		Toast = layer(root, "ToastLayer", Tokens.Layer.Toast),
		Tooltip = layer(root, "TooltipLayer", Tokens.Layer.Tooltip),
		Recovery = layer(root, "RecoveryLayer", Tokens.Layer.Recovery),
	}

	local scale = Instance.new("UIScale")
	scale.Name = "RVTT_UI_SCALE"
	scale.Parent = root

	local contextLabel = Instance.new("TextLabel")
	contextLabel.Name = "ModeRoleLabel"
	contextLabel.Size = UDim2.fromOffset(200, 32)
	contextLabel.Position = UDim2.new(1, -348, 0, 20)
	contextLabel.BackgroundTransparency = 1
	contextLabel.TextXAlignment = Enum.TextXAlignment.Right
	contextLabel.TextSize = Tokens.TextSize.Caption
	contextLabel:SetAttribute("RVTTTextToken", "textSecondary")
	contextLabel.Parent = self.layers.System
	self.contextLabel = contextLabel

	self:setSurface("session")
	self:_renderContext()
	return self
end

function AppShell.getLayer(self: any, name: string): Frame
	local value = self.layers[name]
	assert(value ~= nil, "unknown app shell layer: " .. name)
	return value
end

function AppShell._surfaceFrame(self: any, surface: string): Frame
	if surface == "gameplay" then
		return self.layers.Gameplay
	elseif surface == "management" then
		return self.layers.Management
	elseif surface == "dm" then
		return self.layers.Dm
	end
	return self.layers.Session
end

function AppShell._renderContext(self: any)
	self.contextLabel.Text = string.format("%s · %s", self.role, self.mode)
	self.Root:SetAttribute("RVTTRole", self.role)
	self.Root:SetAttribute("RVTTMode", self.mode)
	self.Root:SetAttribute("RVTTSurface", self.surface)
end

function AppShell.setSurface(self: any, requested: string): boolean
	if not ShellContract.isSurfaceAllowed(self.role, requested) then
		return false
	end
	local selected = GuiService.SelectedObject
	local currentFrame = self:_surfaceFrame(self.surface)
	if selected ~= nil and selected:IsDescendantOf(currentFrame) then
		self.selectionBySurface[self.surface] = selected
	end

	self.surface = requested
	for surface, name in surfaceNames do
		local frame = self.Root:FindFirstChild(name)
		if frame ~= nil and frame:IsA("GuiObject") then
			frame.Visible = surface == requested
		end
	end
	local previous = self.selectionBySurface[requested]
	if isSelectable(previous) and previous:IsDescendantOf(self:_surfaceFrame(requested)) then
		GuiService.SelectedObject = previous
	end
	self:_renderContext()
	return true
end

function AppShell.applyProjection(self: any, payload: any, userId: number)
	local context = ShellContract.resolve(payload, userId)
	self.role = context.role
	self.mode = context.mode
	if not self:setSurface(context.surface) then
		self.surface = "session"
		self:setSurface("session")
	end
	self:_renderContext()
end

function AppShell.destroy(self: any)
	self.Root:Destroy()
end

return table.freeze(AppShell)

