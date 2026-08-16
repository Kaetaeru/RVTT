--!strict

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.RVTT.Shared.Core.Signal)
local WorldActionMenuPolicy = require(script.Parent.WorldActionMenuPolicy)

type Action = {
	id: string,
	label: string,
	kind: string,
	commandType: string,
	payload: { [string]: any },
	isDefault: boolean,
	enabled: boolean,
	disabledReason: string?,
	category: string,
	sortOrder: number,
	projectionRevision: number,
}

local Menu = {}
Menu.__index = Menu

local BUTTON_WIDTH = 164
local BUTTON_HEIGHT = 36
local GAP = 8
local PADDING = 12
local TITLE_HEIGHT = 34
local COLUMNS = 1
local REASON_HEIGHT = 24

local function ensureGui(): (ScreenGui, Frame, TextLabel, Frame, TextLabel)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild("RVTTWorldActionMenu")
	if existing ~= nil then
		existing:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "RVTTWorldActionMenu"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 240
	gui.IgnoreGuiInset = true
	gui.Enabled = false
	gui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.BackgroundColor3 = Color3.fromRGB(24, 27, 33)
	panel.BackgroundTransparency = 0.03
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(91, 101, 118)
	stroke.Transparency = 0.25
	stroke.Thickness = 1
	stroke.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Position = UDim2.fromOffset(PADDING, 6)
	title.Size = UDim2.new(1, -PADDING * 2, 0, TITLE_HEIGHT - 8)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "가능한 행동"
	title.TextColor3 = Color3.fromRGB(240, 242, 246)
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local buttons = Instance.new("Frame")
	buttons.Name = "Buttons"
	buttons.Position = UDim2.fromOffset(PADDING, TITLE_HEIGHT)
	buttons.BackgroundTransparency = 1
	buttons.Parent = panel

	local layout = Instance.new("UIGridLayout")
	layout.Name = "Grid"
	layout.CellSize = UDim2.fromOffset(BUTTON_WIDTH, BUTTON_HEIGHT)
	layout.CellPadding = UDim2.fromOffset(GAP, GAP)
	layout.FillDirectionMaxCells = COLUMNS
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = buttons

	local reason = Instance.new("TextLabel")
	reason.Name = "DisabledReason"
	reason.BackgroundTransparency = 1
	reason.Font = Enum.Font.Gotham
	reason.Text = ""
	reason.TextColor3 = Color3.fromRGB(207, 168, 96)
	reason.TextSize = 12
	reason.TextWrapped = true
	reason.TextXAlignment = Enum.TextXAlignment.Left
	reason.Visible = false
	reason.Parent = panel

	return gui, panel, title, buttons, reason
end

function Menu.new(): any
	local gui, panel, title, buttons, reason = ensureGui()
	return setmetatable({
		gui = gui,
		panel = panel,
		title = title,
		buttons = buttons,
		reason = reason,
		actions = {},
		ActionInvoked = Signal.new(),
		Opened = Signal.new(),
		Closed = Signal.new(),
	}, Menu)
end

function Menu:_showReason(action: Action, visible: boolean)
	local reason = if action.enabled then nil else action.disabledReason
	self.reason.Text = reason or ""
	self.reason.Visible = visible and reason ~= nil and reason ~= ""
end

function Menu:_clearButtons()
	for _, child in self.buttons:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

function Menu:_createButton(action: Action, index: number): TextButton
	local button = Instance.new("TextButton")
	button.Name = "Action_" .. action.id
	button.LayoutOrder = index
	button.BackgroundColor3 = if not action.enabled
		then Color3.fromRGB(55, 57, 62)
		elseif action.isDefault then Color3.fromRGB(70, 91, 126)
		else Color3.fromRGB(46, 52, 63)
	button.BorderSizePixel = 0
	button.AutoButtonColor = action.enabled
	-- Pointer hover keeps disabled reasons inspectable without keyboard/gamepad focus.
	button.Active = true
	button.Font = Enum.Font.GothamMedium
	button.Text = action.label
	button.TextColor3 = if action.enabled
		then Color3.fromRGB(240, 242, 246)
		else Color3.fromRGB(151, 155, 164)
	button.TextSize = 13
	button.Selectable = WorldActionMenuPolicy.actionButtonSelectable
	button:SetAttribute("RVTTAvailability", if action.enabled then "enabled" else "disabled")
	button:SetAttribute("RVTTDisabledReason", action.disabledReason)
	button:SetAttribute("RVTTProjectionRevision", action.projectionRevision)
	button.Parent = self.buttons

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	button.Activated:Connect(function()
		if not action.enabled then
			self:_showReason(action, true)
			return
		end
		self.ActionInvoked:Fire(action)
		self:close("invoked")
	end)
	button.MouseEnter:Connect(function()
		self:_showReason(action, true)
	end)
	button.MouseLeave:Connect(function()
		self:_showReason(action, false)
	end)
	return button
end

function Menu:open(actions: { Action }, screenPosition: Vector2, targetLabel: string?)
	self:_clearButtons()
	self.actions = table.clone(actions)
	if #actions == 0 then
		self:close("empty")
		return
	end

	self.title.Text = if targetLabel ~= nil and targetLabel ~= ""
		then "가능한 행동 · " .. targetLabel
		else "가능한 행동"

	local rows = math.ceil(#actions / COLUMNS)
	local width = PADDING * 2 + BUTTON_WIDTH * COLUMNS + GAP * (COLUMNS - 1)
	local buttonsHeight = BUTTON_HEIGHT * rows + GAP * math.max(0, rows - 1)
	local height = TITLE_HEIGHT + PADDING * 2 + buttonsHeight + REASON_HEIGHT
	self.panel.Size = UDim2.fromOffset(width, height)
	self.buttons.Size = UDim2.fromOffset(width - PADDING * 2, buttonsHeight)
	self.reason.Position = UDim2.fromOffset(PADDING, TITLE_HEIGHT + buttonsHeight + PADDING)
	self.reason.Size = UDim2.fromOffset(width - PADDING * 2, REASON_HEIGHT)
	self.reason.Visible = false

	local camera = workspace.CurrentCamera
	local viewport = if camera ~= nil then camera.ViewportSize else Vector2.new(1280, 720)
	local inset = GuiService:GetGuiInset()
	local x = math.clamp(screenPosition.X, 8, math.max(8, viewport.X - width - 8))
	local y = math.clamp(screenPosition.Y - inset.Y, 8, math.max(8, viewport.Y - height - 8))
	self.panel.Position = UDim2.fromOffset(x, y)

	for index, action in actions do
		self:_createButton(action, index)
	end

	self.gui.Enabled = true
	self.Opened:Fire(actions)
end

function Menu:close(reason: string?)
	if not self.gui.Enabled then
		return
	end
	self.gui.Enabled = false
	self.actions = {}
	self.reason.Visible = false
	self.Closed:Fire(reason or "closed")
end

function Menu:isOpen(): boolean
	return self.gui.Enabled
end

function Menu:getVisibleActionIds(): { string }
	local ids = {}
	for _, action in self.actions do
		table.insert(ids, action.id)
	end
	return ids
end

function Menu:invoke(actionId: string): boolean
	for _, action in self.actions do
		if action.id == actionId then
			if not action.enabled then
				self:_showReason(action, true)
				return false
			end
			self.ActionInvoked:Fire(action)
			self:close("invoked")
			return true
		end
	end
	return false
end

function Menu:destroy()
	self:close("destroy")
	self.ActionInvoked:Destroy()
	self.Opened:Destroy()
	self.Closed:Destroy()
	self.gui:Destroy()
end

return Menu
