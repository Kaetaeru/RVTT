--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AccentPalette = require(ReplicatedStorage.RVTT.Shared.UI.AccentPalette)
local PreferencePresentation = require(ReplicatedStorage.RVTT.Shared.UI.PreferencePresentation)
local PreferenceSchema = require(ReplicatedStorage.RVTT.Shared.UI.PreferenceSchema)
local Tokens = require(ReplicatedStorage.RVTT.Shared.UI.DesignTokens)
local ThemeApplicator = require(script.Parent.Parent.ThemeApplicator)

local SettingsPanel = {}
SettingsPanel.__index = SettingsPanel

local function decorate(value: GuiObject, token: string)
	value.BorderSizePixel = 0
	value:SetAttribute("RVTTBackgroundToken", token)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = Tokens.Radius.SM
	corner.Parent = value
end

local function label(
	parent: Instance,
	name: string,
	text: string,
	size: UDim2,
	position: UDim2
): TextLabel
	local value = Instance.new("TextLabel")
	value.Name = name
	value.Size = size
	value.Position = position
	value.BackgroundTransparency = 1
	value.Font = Enum.Font.GothamMedium
	value.Text = text
	value.TextSize = Tokens.TextSize.Caption
	value.TextXAlignment = Enum.TextXAlignment.Left
	value:SetAttribute("RVTTTextToken", "textPrimary")
	value.Parent = parent
	return value
end

local function button(
	parent: Instance,
	name: string,
	text: string,
	size: UDim2,
	position: UDim2
): TextButton
	local value = Instance.new("TextButton")
	value.Name = name
	value.Size = size
	value.Position = position
	value.AutoButtonColor = false
	value.Font = Enum.Font.GothamBold
	value.Text = text
	value.TextSize = Tokens.TextSize.Caption
	value.Selectable = true
	value:SetAttribute("RVTTTextToken", "textPrimary")
	value.Parent = parent
	decorate(value, "surfaceRaised")
	return value
end

function SettingsPanel.new(
	onSet: (string, any) -> (),
	onReset: (string) -> (),
	onResetAll: () -> (),
	onClose: () -> ()
): any
	local self: any = setmetatable({}, SettingsPanel)
	self.preferences = PreferenceSchema.defaults()
	self.accentButtons = {}
	self.valueLabels = {}

	local root = Instance.new("Frame")
	root.Name = "SettingsModal"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 0.28
	root.Visible = false
	root.ZIndex = Tokens.Layer.Modal
	root:SetAttribute("RVTTBackgroundToken", "scrim")
	self.Root = root

	local panel = Instance.new("ScrollingFrame")
	panel.Name = "SettingsPanel"
	panel.Size = UDim2.fromOffset(700, 620)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.CanvasSize = UDim2.fromOffset(0, 760)
	panel.ScrollBarThickness = 7
	panel.ZIndex = Tokens.Layer.Modal + 1
	panel.Parent = root
	decorate(panel, "surface")

	local title = label(
		panel,
		"Title",
		"인터페이스 설정",
		UDim2.fromOffset(360, 36),
		UDim2.fromOffset(28, 22)
	)
	title.TextSize = Tokens.TextSize.Title
	local close =
		button(panel, "Close", "닫기  Q", UDim2.fromOffset(100, 38), UDim2.new(1, -128, 0, 22))
	close.Activated:Connect(onClose)

	label(panel, "AccentLabel", "강조색", UDim2.fromOffset(200, 24), UDim2.fromOffset(28, 76)).TextSize =
		Tokens.TextSize.Label
	local accentGrid = Instance.new("Frame")
	accentGrid.Name = "AccentGrid"
	accentGrid.Position = UDim2.fromOffset(28, 106)
	accentGrid.Size = UDim2.new(1, -56, 0, 120)
	accentGrid.BackgroundTransparency = 1
	accentGrid.Parent = panel
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.25, -8, 0, 52)
	grid.CellPadding = UDim2.fromOffset(10, 8)
	grid.FillDirectionMaxCells = 4
	grid.Parent = accentGrid
	for index, palette in AccentPalette.list() do
		local accent = button(
			accentGrid,
			"Accent_" .. palette.id,
			palette.displayName,
			UDim2.new(),
			UDim2.new()
		)
		accent.LayoutOrder = index
		accent.Activated:Connect(function()
			onSet("accentPaletteId", palette.id)
		end)
		self.accentButtons[palette.id] = accent
	end

	label(
		panel,
		"LayoutLabel",
		"읽기·레이아웃",
		UDim2.fromOffset(240, 24),
		UDim2.fromOffset(28, 246)
	).TextSize =
		Tokens.TextSize.Label
	for index, row in PreferencePresentation.rows() do
		local y = 280 + (index - 1) * 52
		label(
			panel,
			row.key .. "Label",
			row.label,
			UDim2.fromOffset(230, 38),
			UDim2.fromOffset(28, y)
		)
		local minus = button(
			panel,
			row.key .. "Minus",
			"−",
			UDim2.fromOffset(42, 36),
			UDim2.fromOffset(272, y)
		)
		local valueLabel =
			label(panel, row.key .. "Value", "", UDim2.fromOffset(92, 36), UDim2.fromOffset(326, y))
		valueLabel.TextXAlignment = Enum.TextXAlignment.Center
		self.valueLabels[row.key] = valueLabel
		local plus = button(
			panel,
			row.key .. "Plus",
			"+",
			UDim2.fromOffset(42, 36),
			UDim2.fromOffset(430, y)
		)
		local reset = button(
			panel,
			row.key .. "Reset",
			"기본값",
			UDim2.fromOffset(82, 36),
			UDim2.fromOffset(488, y)
		)
		minus.Activated:Connect(function()
			local valid, value =
				PreferencePresentation.adjust(row.key, self.preferences[row.key], -row.step)
			if valid then
				onSet(row.key, value)
			end
		end)
		plus.Activated:Connect(function()
			local valid, value =
				PreferencePresentation.adjust(row.key, self.preferences[row.key], row.step)
			if valid then
				onSet(row.key, value)
			end
		end)
		reset.Activated:Connect(function()
			onReset(row.key)
		end)
	end

	local motionY = 280 + #PreferencePresentation.rows() * 52
	label(panel, "MotionLabel", "모션", UDim2.fromOffset(230, 38), UDim2.fromOffset(28, motionY))
	self.Motion =
		button(panel, "Motion", "", UDim2.fromOffset(196, 36), UDim2.fromOffset(272, motionY))
	self.Motion.Activated:Connect(function()
		onSet("motion", PreferencePresentation.nextMotion(self.preferences.motion))
	end)
	local resetMotion = button(
		panel,
		"ResetMotion",
		"기본값",
		UDim2.fromOffset(82, 36),
		UDim2.fromOffset(488, motionY)
	)
	resetMotion.Activated:Connect(function()
		onReset("motion")
	end)

	self.BindingNote = label(
		panel,
		"BindingNote",
		"",
		UDim2.new(1, -56, 0, 46),
		UDim2.fromOffset(28, motionY + 48)
	)
	self.BindingNote.TextWrapped = true
	self.ResetAll = button(
		panel,
		"ResetAll",
		"모든 설정 초기화",
		UDim2.fromOffset(180, 40),
		UDim2.fromOffset(28, motionY + 104)
	)
	self.ResetAll.Activated:Connect(onResetAll)
	return self
end

function SettingsPanel.setPreferences(self: any, preferences: any)
	self.preferences = if type(preferences) == "table"
		then preferences
		else PreferenceSchema.defaults()
	for id, accent in self.accentButtons do
		accent:SetAttribute(
			"RVTTBackgroundToken",
			if id == self.preferences.accentPaletteId then "accent" else "surfaceRaised"
		)
	end
	for _, row in PreferencePresentation.rows() do
		local value = self.preferences[row.key]
		self.valueLabels[row.key].Text = if row.key == "actionMatrixRows"
			then tostring(value)
			else string.format("%.2f", value)
	end
	self.Motion.Text = tostring(self.preferences.motion)
	local conflicts = PreferencePresentation.bindingConflicts(self.preferences.bindings)
	if #conflicts > 0 then
		self.BindingNote.Text = string.format(
			"키 바인딩 충돌 %d건. 현재 입력 라우터는 재바인딩을 지원하지 않아 이 화면에서는 수정하지 않습니다.",
			#conflicts
		)
		self.BindingNote:SetAttribute("RVTTTextToken", "warning")
	else
		self.BindingNote.Text =
			"현재 입력 라우터는 키 재바인딩을 지원하지 않습니다. 지원되지 않는 편집 UI는 노출하지 않습니다."
		self.BindingNote:SetAttribute("RVTTTextToken", "textMuted")
	end
	ThemeApplicator.apply(self.Root, self.preferences)
end

function SettingsPanel.setVisible(self: any, visible: boolean)
	self.Root.Visible = visible
	if visible then
		ThemeApplicator.apply(self.Root, self.preferences)
	end
end

function SettingsPanel.isVisible(self: any): boolean
	return self.Root.Visible
end

return table.freeze(SettingsPanel)
