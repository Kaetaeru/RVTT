--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AccentPalette = require(ReplicatedStorage.RVTT.Shared.UI.AccentPalette)
local AccentPreference = require(ReplicatedStorage.RVTT.Shared.UI.AccentPreference)
local Tokens = require(ReplicatedStorage.RVTT.Shared.UI.DesignTokens)
local ThemeApplicator = require(script.Parent.Parent.ThemeApplicator)

local SettingsPanel = {}
SettingsPanel.__index = SettingsPanel

local function corner(parent: Instance, radius: UDim)
	local value = Instance.new("UICorner")
	value.CornerRadius = radius
	value.Parent = parent
end

local function stroke(parent: Instance, token: string, thickness: number): UIStroke
	local value = Instance.new("UIStroke")
	value.Thickness = thickness
	value.Transparency = 0.18
	value:SetAttribute("RVTTStrokeToken", token)
	value.Parent = parent
	return value
end

local function label(
	parent: Instance,
	name: string,
	text: string,
	size: UDim2,
	position: UDim2,
	textSize: number,
	token: string
): TextLabel
	local value = Instance.new("TextLabel")
	value.Name = name
	value.Size = size
	value.Position = position
	value.BackgroundTransparency = 1
	value.Text = text
	value.TextSize = textSize
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.TextYAlignment = Enum.TextYAlignment.Center
	value:SetAttribute("RVTTTextToken", token)
	value.Parent = parent
	return value
end

function SettingsPanel.new(onSelect: (string) -> (), onClose: () -> ()): any
	local self: any = setmetatable({}, SettingsPanel)
	self.onSelect = onSelect
	self.onClose = onClose
	self.selectedId = AccentPreference.DEFAULT_ID
	self.hovered = {}
	self.buttons = {}
	self.strokes = {}
	self.checks = {}

	local root = Instance.new("Frame")
	root.Name = "SettingsModal"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 0.28
	root.Visible = false
	root.ZIndex = Tokens.Layer.Modal
	root:SetAttribute("RVTTBackgroundToken", "scrim")
	self.Root = root

	local panel = Instance.new("Frame")
	panel.Name = "SettingsPanel"
	panel.Size = UDim2.fromOffset(620, 430)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.BorderSizePixel = 0
	panel.ZIndex = Tokens.Layer.Modal + 1
	panel:SetAttribute("RVTTBackgroundToken", "surface")
	panel.Parent = root
	corner(panel, Tokens.Radius.LG)
	stroke(panel, "accent", 1)

	local constraint = Instance.new("UISizeConstraint")
	constraint.MinSize = Vector2.new(520, 390)
	constraint.MaxSize = Vector2.new(720, 520)
	constraint.Parent = panel

	local topBar = Instance.new("Frame")
	topBar.Name = "AccentBar"
	topBar.Size = UDim2.new(1, 0, 0, 4)
	topBar.BorderSizePixel = 0
	topBar.ZIndex = Tokens.Layer.Modal + 2
	topBar:SetAttribute("RVTTBackgroundToken", "accent")
	topBar.Parent = panel
	corner(topBar, Tokens.Radius.LG)

	local title = label(
		panel,
		"Title",
		"인터페이스 설정",
		UDim2.new(1, -160, 0, 38),
		UDim2.fromOffset(28, 24),
		Tokens.TextSize.Title,
		"textPrimary"
	)
	title.ZIndex = Tokens.Layer.Modal + 2

	local subtitle = label(
		panel,
		"Subtitle",
		"선호 강조색을 선택하세요. 기본값은 황금색입니다.",
		UDim2.new(1, -56, 0, 28),
		UDim2.fromOffset(28, 67),
		Tokens.TextSize.Body,
		"textSecondary"
	)
	subtitle.ZIndex = Tokens.Layer.Modal + 2

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.fromOffset(108, 38)
	closeButton.Position = UDim2.new(1, -136, 0, 26)
	closeButton.AutoButtonColor = false
	closeButton.Text = "닫기  Q"
	closeButton.TextSize = Tokens.TextSize.Body
	closeButton.BorderSizePixel = 0
	closeButton.Selectable = true
	closeButton.SelectionOrder = 1
	closeButton.ZIndex = Tokens.Layer.Modal + 2
	closeButton:SetAttribute("RVTTBackgroundToken", "surfaceRaised")
	closeButton:SetAttribute("RVTTTextToken", "textPrimary")
	closeButton.Parent = panel
	corner(closeButton, Tokens.Radius.SM)
	stroke(closeButton, "stroke", 1)
	closeButton.Activated:Connect(onClose)

	local divider = Instance.new("Frame")
	divider.Name = "Divider"
	divider.Size = UDim2.new(1, -56, 0, 1)
	divider.Position = UDim2.fromOffset(28, 112)
	divider.BorderSizePixel = 0
	divider.ZIndex = Tokens.Layer.Modal + 2
	divider:SetAttribute("RVTTBackgroundToken", "stroke")
	divider.Parent = panel

	local grid = Instance.new("Frame")
	grid.Name = "AccentGrid"
	grid.Size = UDim2.new(1, -56, 0, 224)
	grid.Position = UDim2.fromOffset(28, 136)
	grid.BackgroundTransparency = 1
	grid.ZIndex = Tokens.Layer.Modal + 2
	grid.Parent = panel

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0.5, -7, 0, 68)
	gridLayout.CellPadding = UDim2.fromOffset(14, 10)
	gridLayout.FillDirectionMaxCells = 2
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = grid

	for index, palette in AccentPalette.list() do
		local button = Instance.new("TextButton")
		button.Name = "Accent_" .. palette.id
		button.LayoutOrder = index
		button.AutoButtonColor = false
		button.Text = ""
		button.BorderSizePixel = 0
		button.Selectable = true
		button.SelectionOrder = index + 1
		button.ZIndex = Tokens.Layer.Modal + 2
		button:SetAttribute("RVTTBackgroundToken", "surfaceRaised")
		button.Parent = grid
		corner(button, Tokens.Radius.MD)
		local buttonStroke = stroke(button, "stroke", 1)

		local swatch = Instance.new("Frame")
		swatch.Name = "Swatch"
		swatch.Size = UDim2.fromOffset(34, 34)
		swatch.Position = UDim2.fromOffset(14, 17)
		swatch.BackgroundColor3 = palette.primary
		swatch.BorderSizePixel = 0
		swatch.ZIndex = Tokens.Layer.Modal + 3
		swatch.Parent = button
		corner(swatch, UDim.new(1, 0))
		stroke(swatch, "textPrimary", 1)

		local displayName = label(
			button,
			"DisplayName",
			palette.displayName,
			UDim2.new(1, -88, 0, 25),
			UDim2.fromOffset(62, 11),
			Tokens.TextSize.Label,
			"textPrimary"
		)
		displayName.ZIndex = Tokens.Layer.Modal + 3

		local paletteId = label(
			button,
			"PaletteId",
			palette.id,
			UDim2.new(1, -88, 0, 20),
			UDim2.fromOffset(62, 37),
			Tokens.TextSize.Caption,
			"textMuted"
		)
		paletteId.ZIndex = Tokens.Layer.Modal + 3

		local check = label(
			button,
			"SelectedMark",
			"선택됨",
			UDim2.fromOffset(62, 22),
			UDim2.new(1, -72, 0, 23),
			Tokens.TextSize.Caption,
			"accent"
		)
		check.TextXAlignment = Enum.TextXAlignment.Right
		check.ZIndex = Tokens.Layer.Modal + 3

		self.buttons[palette.id] = button
		self.strokes[palette.id] = buttonStroke
		self.checks[palette.id] = check

		button.MouseEnter:Connect(function()
			self.hovered[palette.id] = true
			self:_refreshButton(palette.id)
		end)
		button.MouseLeave:Connect(function()
			self.hovered[palette.id] = nil
			self:_refreshButton(palette.id)
		end)
		button.Activated:Connect(function()
			self:setSelected(palette.id)
			onSelect(palette.id)
		end)
	end

	local note = label(
		panel,
		"Note",
		"역할·성공·경고·위험 등 의미색은 선택한 강조색과 분리됩니다.",
		UDim2.new(1, -56, 0, 36),
		UDim2.fromOffset(28, 378),
		Tokens.TextSize.Caption,
		"textMuted"
	)
	note.TextWrapped = true
	note.ZIndex = Tokens.Layer.Modal + 2

	self:setSelected(AccentPreference.DEFAULT_ID)
	return self
end

function SettingsPanel._refreshButton(self: any, id: string)
	local button = self.buttons[id]
	local buttonStroke = self.strokes[id]
	local check = self.checks[id]
	if button == nil or buttonStroke == nil or check == nil then
		return
	end

	if id == self.selectedId then
		button:SetAttribute("RVTTBackgroundToken", "accentSoft")
		buttonStroke:SetAttribute("RVTTStrokeToken", "accent")
		buttonStroke.Thickness = 2
		check.Visible = true
	elseif self.hovered[id] == true then
		button:SetAttribute("RVTTBackgroundToken", "surfaceSoft")
		buttonStroke:SetAttribute("RVTTStrokeToken", "accentHover")
		buttonStroke.Thickness = 1
		check.Visible = false
	else
		button:SetAttribute("RVTTBackgroundToken", "surfaceRaised")
		buttonStroke:SetAttribute("RVTTStrokeToken", "stroke")
		buttonStroke.Thickness = 1
		check.Visible = false
	end

	ThemeApplicator.apply(button, self.selectedId)
end

function SettingsPanel.setSelected(self: any, value: any)
	self.selectedId = AccentPreference.normalize(value)
	for id in self.buttons do
		self:_refreshButton(id)
	end
	ThemeApplicator.apply(self.Root, self.selectedId)
end

function SettingsPanel.setVisible(self: any, visible: boolean)
	self.Root.Visible = visible
	if visible then
		ThemeApplicator.apply(self.Root, self.selectedId)
	end
end

function SettingsPanel.isVisible(self: any): boolean
	return self.Root.Visible
end

return table.freeze(SettingsPanel)
