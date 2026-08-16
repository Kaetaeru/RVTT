--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Tokens = require(ReplicatedStorage.RVTT.Shared.UI.DesignTokens)
local ViewModel = require(ReplicatedStorage.RVTT.Shared.UI.CoreRulesReaderViewModel)

local CoreRulesReaderPanel = {}
CoreRulesReaderPanel.__index = CoreRulesReaderPanel

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
	value.Font = Enum.Font.Gotham
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
	value.Font = Enum.Font.GothamMedium
	value.Text = text
	value.TextSize = Tokens.TextSize.Caption
	value.TextWrapped = true
	value.Selectable = true
	value:SetAttribute("RVTTBackgroundToken", "surfaceSoft")
	value:SetAttribute("RVTTTextToken", "textPrimary")
	value.Parent = parent
	decorate(value, "surfaceSoft")
	return value
end

local function scrolling(
	parent: Instance,
	name: string,
	size: UDim2,
	position: UDim2
): ScrollingFrame
	local value = Instance.new("ScrollingFrame")
	value.Name = name
	value.Size = size
	value.Position = position
	value.AutomaticCanvasSize = Enum.AutomaticSize.Y
	value.CanvasSize = UDim2.new()
	value.ScrollBarThickness = 6
	value.Parent = parent
	decorate(value, "surfaceRaised")
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = value
	return value
end

local function listLayout(parent: Instance): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
	return layout
end

local function clearGenerated(parent: Instance)
	for _, child in parent:GetChildren() do
		if child:GetAttribute("RVTTGenerated") == true then
			child:Destroy()
		end
	end
end

function CoreRulesReaderPanel.new(reader: any): any
	local self: any = setmetatable({}, CoreRulesReaderPanel)
	self.reader = reader
	self.state = ViewModel.initial()
	self.loaded = false

	local root = Instance.new("Frame")
	root.Name = "CoreRulesReader"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Visible = false
	self.Root = root

	local search = Instance.new("TextBox")
	search.Name = "RuleSearch"
	search.Size = UDim2.new(0.42, 0, 0, 38)
	search.Position = UDim2.fromOffset(0, 0)
	search.PlaceholderText = "Core Rules 검색"
	search.Text = ""
	search.ClearTextOnFocus = false
	search.Font = Enum.Font.Gotham
	search.TextSize = Tokens.TextSize.Body
	search.TextXAlignment = Enum.TextXAlignment.Left
	search:SetAttribute("RVTTBackgroundToken", "surfaceRaised")
	search:SetAttribute("RVTTTextToken", "textPrimary")
	search.Parent = root
	decorate(search, "surfaceRaised")
	local searchPadding = Instance.new("UIPadding")
	searchPadding.PaddingLeft = UDim.new(0, 10)
	searchPadding.PaddingRight = UDim.new(0, 10)
	searchPadding.Parent = search
	self.Search = search

	self.SearchButton =
		button(root, "SearchButton", "검색", UDim2.fromOffset(72, 38), UDim2.new(0.42, 8, 0, 0))
	self.ProfileBadge = label(
		root,
		"ProfileBadge",
		"RULE PROFILE —",
		UDim2.fromOffset(160, 38),
		UDim2.new(1, -330, 0, 8)
	)
	self.ProfileBadge.TextXAlignment = Enum.TextXAlignment.Right
	self.ProfileBadge.TextSize = Tokens.TextSize.Caption
	self.CopyLink =
		button(root, "CopyRuleLink", "Rule Link", UDim2.fromOffset(96, 38), UDim2.new(1, -98, 0, 0))

	local tree = scrolling(root, "RuleTree", UDim2.new(0.25, -4, 1, -54), UDim2.fromOffset(0, 54))
	listLayout(tree)
	self.Tree = tree

	local article = Instance.new("Frame")
	article.Name = "VirtualizedArticle"
	article.Size = UDim2.new(0.5, -8, 1, -54)
	article.Position = UDim2.new(0.25, 4, 0, 54)
	article.Parent = root
	decorate(article, "surfaceRaised")
	self.Article = article
	self.ArticleTitle = label(
		article,
		"ArticleTitle",
		"Core Rules",
		UDim2.new(1, -24, 0, 46),
		UDim2.fromOffset(12, 12)
	)
	self.ArticleTitle.Font = Enum.Font.GothamBold
	self.ArticleTitle.TextSize = Tokens.TextSize.Heading

	local articleScroll =
		scrolling(article, "ArticleViewport", UDim2.new(1, -24, 1, -118), UDim2.fromOffset(12, 58))
	articleScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	self.ArticleScroll = articleScroll
	self.ArticleBody = label(articleScroll, "ArticleBody", "", UDim2.new(1, -8, 0, 0), UDim2.new())
	self.ArticleBody.AutomaticSize = Enum.AutomaticSize.Y
	self.ArticleBody.TextSize = Tokens.TextSize.Body
	self.ArticleBody.LineHeight = 1.15
	self.PreviousChunk = button(
		article,
		"PreviousChunk",
		"이전 Chunk",
		UDim2.fromOffset(112, 34),
		UDim2.new(0, 12, 1, -46)
	)
	self.NextChunk = button(
		article,
		"NextChunk",
		"다음 Chunk",
		UDim2.fromOffset(112, 34),
		UDim2.new(0, 132, 1, -46)
	)

	local side =
		scrolling(root, "RuleOutline", UDim2.new(0.25, -4, 1, -54), UDim2.new(0.75, 4, 0, 54))
	listLayout(side)
	self.Side = side

	self.Status =
		label(root, "ReaderStatus", "", UDim2.new(0.5, -24, 0, 30), UDim2.new(0.25, 16, 1, -88))
	self.Status.TextSize = Tokens.TextSize.Caption
	self.Status:SetAttribute("RVTTTextToken", "textSecondary")

	self.LinkBox = Instance.new("TextBox")
	self.LinkBox.Name = "RuleLinkValue"
	self.LinkBox.Size = UDim2.new(0.5, -24, 0, 34)
	self.LinkBox.Position = UDim2.new(0.25, 16, 1, -48)
	self.LinkBox.BackgroundTransparency = 1
	self.LinkBox.ClearTextOnFocus = false
	self.LinkBox.TextEditable = false
	self.LinkBox.Text = ""
	self.LinkBox.TextSize = Tokens.TextSize.Caption
	self.LinkBox.Font = Enum.Font.Code
	self.LinkBox.TextXAlignment = Enum.TextXAlignment.Left
	self.LinkBox:SetAttribute("RVTTTextToken", "textSecondary")
	self.LinkBox.Parent = root

	self.SearchButton.Activated:Connect(function()
		self:_search()
	end)
	self.Search.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			self:_search()
		end
	end)
	self.CopyLink.Activated:Connect(function()
		local uri = self.state.activeUri
		if type(uri) == "string" then
			self.LinkBox.Text = uri
			self.LinkBox:CaptureFocus()
			self.LinkBox.CursorPosition = #uri + 1
			self.LinkBox.SelectionStart = 1
			self.Status.Text =
				"Rule Link를 선택했습니다. Ctrl+C로 복사할 수 있습니다."
		end
	end)
	self.PreviousChunk.Activated:Connect(function()
		self:_loadEdge("previous")
	end)
	self.NextChunk.Activated:Connect(function()
		self:_loadEdge("next")
	end)

	return self
end

function CoreRulesReaderPanel:_setStatus(text: string, token: string?)
	self.Status.Text = text
	self.Status:SetAttribute("RVTTTextToken", token or "textSecondary")
end

function CoreRulesReaderPanel:_renderTree()
	clearGenerated(self.Tree)
	local order = 0
	if self.state.searchQuery ~= "" then
		for _, result in self.state.searchResults do
			order += 1
			local item = button(
				self.Tree,
				"SearchResult_" .. tostring(order),
				result.documentTitle .. "\n" .. result.sectionTitle,
				UDim2.new(1, -4, 0, 58),
				UDim2.new()
			)
			item.LayoutOrder = order
			item.TextXAlignment = Enum.TextXAlignment.Left
			item:SetAttribute("RVTTGenerated", true)
			item.Activated:Connect(function()
				self:_open(result.uri)
			end)
		end
		if order == 0 then
			local empty = label(
				self.Tree,
				"NoSearchResult",
				"검색 결과 없음",
				UDim2.new(1, -4, 0, 44),
				UDim2.new()
			)
			empty.LayoutOrder = 1
			empty:SetAttribute("RVTTGenerated", true)
		end
		return
	end
	local manifest = self.state.manifest
	if type(manifest) ~= "table" then
		return
	end
	for _, module in manifest.modules or {} do
		order += 1
		local header = label(
			self.Tree,
			"Module_" .. module.id,
			tostring(module.title),
			UDim2.new(1, -4, 0, 34),
			UDim2.new()
		)
		header.LayoutOrder = order
		header.Font = Enum.Font.GothamBold
		header.TextSize = Tokens.TextSize.Caption
		header:SetAttribute("RVTTGenerated", true)
		for _, document in module.documents or {} do
			order += 1
			local item = button(
				self.Tree,
				"Document_" .. document.id,
				tostring(document.title),
				UDim2.new(1, -4, 0, 42),
				UDim2.new()
			)
			item.LayoutOrder = order
			item.TextXAlignment = Enum.TextXAlignment.Left
			item:SetAttribute("RVTTGenerated", true)
			item.Activated:Connect(function()
				local section = if type(document.sections) == "table"
					then document.sections[1]
					else nil
				local uri = if type(section) == "table" then section.uri else document.uri
				if type(uri) == "string" then
					self:_open(uri)
				end
			end)
		end
	end
end

function CoreRulesReaderPanel:_renderSide()
	clearGenerated(self.Side)
	local order = 0
	local document = self.state.openDocument
	if type(document) == "table" then
		local outline =
			label(self.Side, "OutlineHeading", "Outline", UDim2.new(1, -4, 0, 34), UDim2.new())
		outline.LayoutOrder = 1
		outline.Font = Enum.Font.GothamBold
		outline:SetAttribute("RVTTGenerated", true)
		order = 1
		for _, section in document.sections or {} do
			order += 1
			local item = button(
				self.Side,
				"Outline_" .. section.anchorId,
				tostring(section.title),
				UDim2.new(1, -4, 0, 40),
				UDim2.new()
			)
			item.LayoutOrder = order
			item.TextXAlignment = Enum.TextXAlignment.Left
			item:SetAttribute("RVTTGenerated", true)
			item.Activated:Connect(function()
				if type(section.uri) == "string" then
					self:_open(section.uri)
				end
			end)
		end
		order += 1
		local source = label(
			self.Side,
			"Source",
			"Source\n" .. tostring(document.sourceLabel or "—"),
			UDim2.new(1, -4, 0, 54),
			UDim2.new()
		)
		source.LayoutOrder = order
		source.TextSize = Tokens.TextSize.Caption
		source:SetAttribute("RVTTTextToken", "textSecondary")
		source:SetAttribute("RVTTGenerated", true)
	end
	local manifest = self.state.manifest
	if type(manifest) == "table" and type(manifest.license) == "table" then
		order += 1
		local license = manifest.license
		local licenseLabel = label(
			self.Side,
			"License",
			"License\n"
				.. tostring(license.licenseId or "—")
				.. "\n"
				.. tostring(license.attributionText or ""),
			UDim2.new(1, -4, 0, 92),
			UDim2.new()
		)
		licenseLabel.LayoutOrder = order
		licenseLabel.TextSize = Tokens.TextSize.Caption
		licenseLabel:SetAttribute("RVTTTextToken", "textSecondary")
		licenseLabel:SetAttribute("RVTTGenerated", true)
	end
end

function CoreRulesReaderPanel:_renderArticle()
	local document = self.state.openDocument
	local section = self.state.openSection
	self.ArticleTitle.Text = if type(document) == "table"
		then tostring(document.title) .. if type(section) == "table"
			then " · " .. tostring(section.title)
			else ""
		else "Core Rules"
	self.ArticleBody.Text = ViewModel.articleText(self.state)
	local previousId = ViewModel.edgeChunkId(self.state, "previous")
	local nextId = ViewModel.edgeChunkId(self.state, "next")
	self.PreviousChunk.Active = previousId ~= nil
	self.NextChunk.Active = nextId ~= nil
	self.PreviousChunk:SetAttribute(
		"RVTTBackgroundToken",
		if previousId ~= nil then "surfaceSoft" else "disabled"
	)
	self.NextChunk:SetAttribute(
		"RVTTBackgroundToken",
		if nextId ~= nil then "surfaceSoft" else "disabled"
	)
	self.LinkBox.Text = if type(self.state.activeUri) == "string" then self.state.activeUri else ""
end

function CoreRulesReaderPanel:_render()
	local manifest = self.state.manifest
	self.ProfileBadge.Text = ViewModel.profileBadge(manifest)
	self:_renderTree()
	self:_renderSide()
	self:_renderArticle()
	if self.state.status == "error" then
		self:_setStatus(ViewModel.errorLabel(self.state.errorCode), "warning")
	elseif self.state.status == "loading" then
		self:_setStatus("규칙 데이터를 불러오는 중…", "pending")
	elseif self.state.searchQuery ~= "" and #self.state.searchResults == 0 then
		self:_setStatus("검색 결과 없음")
	else
		self:_setStatus("")
	end
end

function CoreRulesReaderPanel:_open(uri: string)
	self.state.status = "loading"
	self:_render()
	self.reader:open(uri, function(result)
		ViewModel.applyOpen(self.state, result)
		self:_render()
	end)
end

function CoreRulesReaderPanel:_search()
	local query = self.Search.Text
	if string.match(query, "^%s*$") ~= nil then
		self.state.searchQuery = ""
		self.state.searchResults = {}
		self:_render()
		return
	end
	self.state.status = "loading"
	self:_render()
	self.reader:search(query, function(result)
		ViewModel.applySearch(self.state, query, result)
		self:_render()
	end)
end

function CoreRulesReaderPanel:_loadEdge(direction: string)
	local chunkId = ViewModel.edgeChunkId(self.state, direction)
	if chunkId == nil then
		return
	end
	self.state.status = "loading"
	self:_render()
	self.reader:chunk(chunkId, function(result)
		ViewModel.appendChunk(self.state, result, direction)
		self:_render()
	end)
end

function CoreRulesReaderPanel:refresh()
	self.loaded = true
	self.state = ViewModel.initial()
	self.state.status = "loading"
	self:_render()
	self.reader:manifest(function(result)
		ViewModel.applyManifest(self.state, result)
		self:_render()
		if result.ok == true then
			local uri = ViewModel.firstUri(self.state.manifest)
			if uri ~= nil then
				self:_open(uri)
			end
		end
	end)
end

function CoreRulesReaderPanel:invalidate()
	self.loaded = false
	self.state = ViewModel.initial()
	self:_render()
end

function CoreRulesReaderPanel:setVisible(visible: boolean)
	self.Root.Visible = visible
	if visible and not self.loaded then
		self:refresh()
	end
end

return table.freeze(CoreRulesReaderPanel)
