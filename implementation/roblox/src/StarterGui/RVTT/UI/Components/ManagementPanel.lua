--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Tokens = require(ReplicatedStorage.RVTT.Shared.UI.DesignTokens)

local ManagementPanel = {}
ManagementPanel.__index = ManagementPanel

local function decorate(frame: GuiObject, background: string)
	frame.BorderSizePixel = 0
	frame:SetAttribute("RVTTBackgroundToken", background)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = Tokens.Radius.MD
	corner.Parent = frame
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
	value.TextSize = Tokens.TextSize.Body
	value.TextWrapped = true
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.TextYAlignment = Enum.TextYAlignment.Top
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
	value:SetAttribute("RVTTBackgroundToken", "surfaceRaised")
	value:SetAttribute("RVTTTextToken", "textPrimary")
	value.Parent = parent
	decorate(value, "surfaceRaised")
	return value
end

local function textBox(
	parent: Instance,
	name: string,
	size: UDim2,
	position: UDim2,
	multiline: boolean
): TextBox
	local value = Instance.new("TextBox")
	value.Name = name
	value.Size = size
	value.Position = position
	value.ClearTextOnFocus = false
	value.MultiLine = multiline
	value.Text = ""
	value.TextSize = Tokens.TextSize.Body
	value.Font = Enum.Font.Gotham
	value.TextWrapped = multiline
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.TextYAlignment = Enum.TextYAlignment.Top
	value:SetAttribute("RVTTBackgroundToken", "surfaceRaised")
	value:SetAttribute("RVTTTextToken", "textPrimary")
	value.Parent = parent
	decorate(value, "surfaceRaised")
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = value
	return value
end

function ManagementPanel.new(
	onClose: () -> (),
	onMove: (string, number) -> (),
	onCreate: (string, string, number) -> (),
	onEdit: (string, string, string, number) -> ()
): any
	local self: any = setmetatable({}, ManagementPanel)
	self.state = nil
	self.tab = "inventory"
	self.draft = false
	self.pending = false

	local root = Instance.new("Frame")
	root.Name = "ManagementPanel"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 0.08
	root:SetAttribute("RVTTBackgroundToken", "canvas")
	root.Visible = false
	root.Parent = nil
	self.Root = root

	local sheet = Instance.new("Frame")
	sheet.Name = "ManagementSheet"
	sheet.AnchorPoint = Vector2.new(0.5, 0.5)
	sheet.Position = UDim2.fromScale(0.5, 0.5)
	sheet.Size = UDim2.new(1, -96, 1, -112)
	sheet.Parent = root
	decorate(sheet, "surface")

	local title = label(
		sheet,
		"Title",
		"캐릭터 콘솔",
		UDim2.fromOffset(320, 34),
		UDim2.fromOffset(24, 20)
	)
	title.TextSize = Tokens.TextSize.Title
	local close =
		button(sheet, "Close", "닫기  Q", UDim2.fromOffset(100, 38), UDim2.new(1, -124, 0, 18))
	close.Activated:Connect(onClose)

	local inventoryTab = button(
		sheet,
		"InventoryTab",
		"소지품",
		UDim2.fromOffset(120, 38),
		UDim2.fromOffset(24, 68)
	)
	local journalTab =
		button(sheet, "JournalTab", "Journal", UDim2.fromOffset(120, 38), UDim2.fromOffset(152, 68))
	self.InventoryTab = inventoryTab
	self.JournalTab = journalTab

	local list = Instance.new("ScrollingFrame")
	list.Name = "EntryList"
	list.Position = UDim2.fromOffset(24, 122)
	list.Size = UDim2.new(0, 270, 1, -150)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.ScrollBarThickness = 6
	list.Parent = sheet
	decorate(list, "surfaceRaised")
	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingTop = UDim.new(0, 10)
	listPadding.PaddingLeft = UDim.new(0, 10)
	listPadding.PaddingRight = UDim.new(0, 10)
	listPadding.Parent = list
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	self.List = list

	local detail = Instance.new("Frame")
	detail.Name = "Detail"
	detail.Position = UDim2.fromOffset(314, 122)
	detail.Size = UDim2.new(1, -338, 1, -150)
	detail.Parent = sheet
	decorate(detail, "surfaceRaised")
	self.Detail = detail

	local detailTitle =
		label(detail, "DetailTitle", "", UDim2.new(1, -32, 0, 40), UDim2.fromOffset(16, 16))
	detailTitle.TextSize = Tokens.TextSize.Heading
	self.DetailTitle = detailTitle
	self.DetailBody =
		label(detail, "DetailBody", "", UDim2.new(1, -32, 1, -132), UDim2.fromOffset(16, 62))
	self.Action = button(
		detail,
		"Action",
		"선택 캐릭터 소지품으로 이동",
		UDim2.fromOffset(250, 40),
		UDim2.new(0, 16, 1, -56)
	)
	self.Action.Activated:Connect(function()
		if not self.pending and self.state ~= nil and self.state.selectedItemId ~= nil then
			onMove(self.state.selectedItemId, self.state.revision)
		end
	end)

	self.TitleBox =
		textBox(detail, "DocumentTitle", UDim2.new(1, -32, 0, 42), UDim2.fromOffset(16, 16), false)
	self.BodyBox =
		textBox(detail, "DocumentBody", UDim2.new(1, -32, 1, -132), UDim2.fromOffset(16, 68), true)
	self.Save = button(
		detail,
		"SaveDocument",
		"저장",
		UDim2.fromOffset(110, 40),
		UDim2.new(0, 16, 1, -56)
	)
	self.NewDocument = button(
		detail,
		"NewDocument",
		"새 문서",
		UDim2.fromOffset(110, 40),
		UDim2.new(0, 134, 1, -56)
	)
	self.Feedback =
		label(detail, "Feedback", "", UDim2.new(1, -286, 0, 40), UDim2.new(0, 270, 1, -52))
	self.Feedback.TextSize = Tokens.TextSize.Caption
	self.NewDocument.Activated:Connect(function()
		self.draft = true
		self.TitleBox.Text = ""
		self.BodyBox.Text = ""
		self:_renderDetail()
		self.TitleBox:CaptureFocus()
	end)
	self.Save.Activated:Connect(function()
		if self.pending or self.state == nil then
			return
		end
		if self.draft then
			onCreate(self.TitleBox.Text, self.BodyBox.Text, self.state.revision)
		elseif self.state.selectedDocumentId ~= nil then
			onEdit(
				self.state.selectedDocumentId,
				self.TitleBox.Text,
				self.BodyBox.Text,
				self.state.revision
			)
		end
	end)

	inventoryTab.Activated:Connect(function()
		self:setTab("inventory")
	end)
	journalTab.Activated:Connect(function()
		self:setTab("journal")
	end)
	return self
end

function ManagementPanel._clearList(self: any)
	for _, child in self.List:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

function ManagementPanel._selectedDocument(self: any): any?
	if self.state == nil then
		return nil
	end
	for _, document in self.state.documents do
		if document.id == self.state.selectedDocumentId then
			return document
		end
	end
	return nil
end

function ManagementPanel._renderDetail(self: any)
	local inventory = self.tab == "inventory"
	self.DetailTitle.Visible = inventory
	self.DetailBody.Visible = inventory
	self.Action.Visible = inventory
	self.TitleBox.Visible = not inventory
	self.BodyBox.Visible = not inventory
	self.Save.Visible = not inventory
	self.NewDocument.Visible = not inventory
	self.Feedback.Visible = true
	if self.state == nil then
		return
	end
	if inventory then
		local selected = nil
		for _, item in self.state.items do
			if item.id == self.state.selectedItemId then
				selected = item
			end
		end
		self.DetailTitle.Text = if selected then selected.label else "소지품 없음"
		self.DetailBody.Text = if selected
			then string.format(
				"수량: %s\n위치: %s\n\n%s",
				tostring(selected.quantity or 1),
				selected.location,
				selected.disabledReason
					or "서버 검증 후 선택 캐릭터의 소지품으로 이동합니다."
			)
			else "현재 투영에서 볼 수 있는 아이템이 없습니다."
		self.Action.Visible = selected ~= nil
		self.Action.Active = not self.pending and selected ~= nil and selected.canMoveToSelected
		self.Action:SetAttribute(
			"RVTTBackgroundToken",
			if self.Action.Active then "accent" else "disabled"
		)
	else
		local document = self:_selectedDocument()
		if
			not self.draft
			and document ~= nil
			and not self.TitleBox:IsFocused()
			and not self.BodyBox:IsFocused()
		then
			self.TitleBox.Text = document.title
			self.BodyBox.Text = document.body
		end
		self.TitleBox.TextEditable = self.draft or (document ~= nil and document.canEdit)
		self.BodyBox.TextEditable = self.TitleBox.TextEditable
		self.Save.Active = not self.pending and self.TitleBox.TextEditable
		self.Save:SetAttribute(
			"RVTTBackgroundToken",
			if self.Save.Active then "accent" else "disabled"
		)
		self.Save.Text = if self.draft then "생성" else "저장"
	end
end

function ManagementPanel._renderList(self: any)
	self:_clearList()
	if self.state == nil then
		return
	end
	local entries = if self.tab == "inventory" then self.state.items else self.state.documents
	for index, entry in entries do
		local selected = if self.tab == "inventory"
			then entry.id == self.state.selectedItemId
			else entry.id == self.state.selectedDocumentId
		local entryButton = button(
			self.List,
			"Entry_" .. entry.id,
			if self.tab == "inventory" then entry.label else entry.title,
			UDim2.new(1, -20, 0, 46),
			UDim2.new()
		)
		entryButton.LayoutOrder = index
		entryButton.TextXAlignment = Enum.TextXAlignment.Left
		entryButton:SetAttribute(
			"RVTTBackgroundToken",
			if selected then "accentSoft" else "surfaceSoft"
		)
		entryButton.Activated:Connect(function()
			self.draft = false
			if self.tab == "inventory" then
				self.state.selectedItemId = entry.id
			else
				self.state.selectedDocumentId = entry.id
			end
			self:_renderList()
			self:_renderDetail()
		end)
	end
end

function ManagementPanel.setTab(self: any, tab: string)
	if tab ~= "inventory" and tab ~= "journal" then
		return
	end
	self.tab = tab
	self.draft = false
	self.InventoryTab:SetAttribute(
		"RVTTBackgroundToken",
		if tab == "inventory" then "accent" else "surfaceRaised"
	)
	self.JournalTab:SetAttribute(
		"RVTTBackgroundToken",
		if tab == "journal" then "accent" else "surfaceRaised"
	)
	self:_renderList()
	self:_renderDetail()
end

function ManagementPanel.render(self: any, state: any)
	self.state = state
	self:_renderList()
	self:_renderDetail()
end

function ManagementPanel.setFeedback(self: any, text: string, token: string?)
	self.Feedback.Text = text
	self.Feedback:SetAttribute("RVTTTextToken", token or "textSecondary")
end

function ManagementPanel.setPending(self: any, pending: boolean)
	self.pending = pending
	self:_renderDetail()
end

function ManagementPanel.setVisible(self: any, visible: boolean, tab: string?)
	self.Root.Visible = visible
	if visible and tab ~= nil then
		self:setTab(tab)
	end
end

return table.freeze(ManagementPanel)
