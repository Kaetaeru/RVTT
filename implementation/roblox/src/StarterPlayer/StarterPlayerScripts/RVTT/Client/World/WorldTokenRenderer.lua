--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Signal = require(ReplicatedStorage.RVTT.Shared.Core.Signal)
local Contract = require(ReplicatedStorage.RVTT.Shared.World.WorldTokenContract)
local TokenAssetResolver = require(script.Parent.TokenAssetResolver)
local Style = require(script.Parent.WorldTokenStyle)

type TokenRecord = {
	model: Model,
	actor: any,
	fingerprint: string,
	highlight: Highlight,
	label: TextLabel,
}

export type Renderer = {
	folder: Folder,
	resolver: any,
	records: { [string]: TokenRecord },
	selectedActorId: string?,
	SelectionChanged: any,
	_createRecord: (self: Renderer, actor: any, payload: any) -> TokenRecord,
	_destroyRecord: (self: Renderer, actorId: string) -> (),
	reconcile: (self: Renderer, payload: any) -> (),
	setSelected: (self: Renderer, actorId: string?) -> boolean,
	actorIdFromInstance: (self: Renderer, instance: Instance?) -> string?,
	getSelectedActorId: (self: Renderer) -> string?,
	getTokenModel: (self: Renderer, actorId: string) -> Model?,
	tokenCount: (self: Renderer) -> number,
	destroy: (self: Renderer) -> (),
}

local Renderer = {}
Renderer.__index = Renderer

local function ensureFolder(parent: Instance): Folder
	local existing = parent:FindFirstChild(Style.FolderName)
	if existing ~= nil and existing:IsA("Folder") then
		return existing
	end
	if existing ~= nil then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = Style.FolderName
	folder.Parent = parent
	return folder
end

local function createHighlight(model: Model): Highlight
	local highlight = Instance.new("Highlight")
	highlight.Name = "RVTTSelectionHighlight"
	highlight.Adornee = model
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = Style.SelectionFill
	highlight.FillTransparency = 0.72
	highlight.OutlineColor = Style.SelectionOutline
	highlight.OutlineTransparency = 0
	highlight.Enabled = false
	highlight.Parent = model
	return highlight
end

local function createLabel(model: Model): TextLabel
	local adornee = model.PrimaryPart
	assert(adornee ~= nil, "world token requires a primary part")
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "RVTTTokenLabel"
	billboard.Adornee = adornee
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Size = UDim2.fromOffset(190, 30)
	billboard.StudsOffsetWorldSpace = Style.LabelOffset
	billboard.Parent = model

	local label = Instance.new("TextLabel")
	label.Name = "Name"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Style.LabelBackground
	label.BackgroundTransparency = 0.25
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamMedium
	label.TextColor3 = Style.LabelText
	label.TextSize = 13
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = label
	return label
end

local function updateActorAttributes(model: Model, actor: any)
	model:SetAttribute("RVTTActorId", actor.id)
	model:SetAttribute(
		"RVTTOwnerUserId",
		if type(actor.ownerUserId) == "number" then actor.ownerUserId else nil
	)
	model:SetAttribute(
		"RVTTControllerUserId",
		if type(actor.controllerUserId) == "number" then actor.controllerUserId else nil
	)
end

function Renderer.new(parent: Instance?, resolver: any?): Renderer
	local folder = ensureFolder(parent or Workspace)
	return setmetatable({
		folder = folder,
		resolver = resolver or TokenAssetResolver.new(),
		records = {},
		selectedActorId = nil,
		SelectionChanged = Signal.new(),
	}, Renderer) :: any
end

function Renderer:_createRecord(actor: any, payload: any): TokenRecord
	local model = self.resolver:resolve(actor)
	model.Parent = self.folder
	updateActorAttributes(model, actor)
	local record = {
		model = model,
		actor = actor,
		fingerprint = Contract.fingerprint(actor),
		highlight = createHighlight(model),
		label = createLabel(model),
	}
	record.label.Text = Contract.displayName(payload, actor)
	return record
end

function Renderer:_destroyRecord(actorId: string)
	local record = self.records[actorId]
	if record == nil then
		return
	end
	record.model:Destroy()
	self.records[actorId] = nil
	if self.selectedActorId == actorId then
		self.selectedActorId = nil
		self.SelectionChanged:Fire(nil)
	end
end

function Renderer.reconcile(self: Renderer, payload: any)
	local active = {}
	for actorId, actor in Contract.actors(payload) do
		if type(actorId) == "string" and type(actor) == "table" then
			local position = Contract.toVector3(actor.position)
			if position ~= nil then
				active[actorId] = true
				local fingerprint = Contract.fingerprint(actor)
				local record = self.records[actorId]
				if record == nil or record.fingerprint ~= fingerprint then
					if record ~= nil then
						self:_destroyRecord(actorId)
					end
					record = self:_createRecord(actor, payload)
					self.records[actorId] = record
				end
				record.actor = actor
				record.label.Text = Contract.displayName(payload, actor)
				updateActorAttributes(record.model, actor)
				record.model:PivotTo(CFrame.new(position))
				record.highlight.Enabled = self.selectedActorId == actorId
			end
		end
	end
	for actorId in self.records do
		if active[actorId] ~= true then
			self:_destroyRecord(actorId)
		end
	end
end

function Renderer.setSelected(self: Renderer, actorId: string?): boolean
	if actorId ~= nil and self.records[actorId] == nil then
		return false
	end
	if self.selectedActorId == actorId then
		return true
	end
	local previous = self.selectedActorId
	self.selectedActorId = actorId
	if previous ~= nil and self.records[previous] ~= nil then
		self.records[previous].highlight.Enabled = false
	end
	if actorId ~= nil then
		self.records[actorId].highlight.Enabled = true
	end
	self.SelectionChanged:Fire(actorId)
	return true
end

function Renderer.actorIdFromInstance(self: Renderer, instance: Instance?): string?
	local current = instance
	while current ~= nil do
		local actorId = current:GetAttribute("RVTTActorId")
		if type(actorId) == "string" and self.records[actorId] ~= nil then
			return actorId
		end
		if current == self.folder then
			break
		end
		current = current.Parent
	end
	return nil
end

function Renderer.getSelectedActorId(self: Renderer): string?
	return self.selectedActorId
end

function Renderer.getTokenModel(self: Renderer, actorId: string): Model?
	local record = self.records[actorId]
	return if record ~= nil then record.model else nil
end

function Renderer.tokenCount(self: Renderer): number
	local count = 0
	for _ in self.records do
		count += 1
	end
	return count
end

function Renderer.destroy(self: Renderer)
	for actorId in self.records do
		self:_destroyRecord(actorId)
	end
	self.SelectionChanged:Destroy()
	self.folder:Destroy()
end

return Renderer
