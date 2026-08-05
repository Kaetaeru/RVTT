--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Signal = require(ReplicatedStorage.RVTT.Shared.Core.Signal)
local Contract = require(ReplicatedStorage.RVTT.Shared.World.WorldTokenContract)
local InteractionMath = require(ReplicatedStorage.RVTT.Shared.World.WorldInteractionMath)
local TokenAssetResolver = require(script.Parent.TokenAssetResolver)
local Style = require(script.Parent.WorldTokenStyle)

type TokenRecord = {
	model: Model,
	actor: any,
	fingerprint: string,
	highlight: Highlight,
	label: TextLabel,
	position: Vector3,
}

type DestinationRecord = {
	marker: Part,
	actorId: string,
	commandId: string,
	position: Vector3,
	status: string,
	revision: number?,
	code: string?,
}

export type ReconcileSummary = {
	created: number,
	updated: number,
	removed: number,
	count: number,
	revision: number?,
}

export type Renderer = {
	folder: Folder,
	resolver: any,
	records: { [string]: TokenRecord },
	selectedActorId: string?,
	destination: DestinationRecord?,
	SelectionChanged: any,
	Reconciled: any,
	DestinationChanged: any,
	_createRecord: (self: Renderer, actor: any, payload: any) -> TokenRecord,
	_destroyRecord: (self: Renderer, actorId: string) -> (),
	reconcile: (self: Renderer, payload: any, revision: number?) -> ReconcileSummary,
	setSelected: (self: Renderer, actorId: string?) -> boolean,
	actorIdFromInstance: (self: Renderer, instance: Instance?) -> string?,
	actorIdFromViewportPoint: (
		self: Renderer,
		camera: Camera,
		viewportPosition: Vector2,
		maximumDistancePixels: number?
	) -> string?,
	getSelectedActorId: (self: Renderer) -> string?,
	getTokenModel: (self: Renderer, actorId: string) -> Model?,
	getWorldBounds: (self: Renderer) -> (Vector3?, Vector3?),
	isSelectedHighlighted: (self: Renderer, actorId: string) -> boolean,
	showDestination: (
		self: Renderer,
		actorId: string,
		position: Vector3,
		commandId: string
	) -> (),
	resolveDestination: (
		self: Renderer,
		commandId: string,
		status: string,
		revision: number?,
		code: string?
	) -> (),
	clearDestination: (self: Renderer, commandId: string?) -> (),
	getDestinationStatus: (self: Renderer) -> string?,
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

local function createDestinationMarker(position: Vector3): Part
	local marker = Instance.new("Part")
	marker.Name = "RVTTDestinationMarker"
	marker.Shape = Enum.PartType.Cylinder
	marker.Size = Vector3.new(0.12, Style.DestinationMarkerDiameter, Style.DestinationMarkerDiameter)
	marker.CFrame = CFrame.new(position + Vector3.new(0, 0.07, 0))
		* CFrame.Angles(0, 0, math.rad(90))
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanTouch = false
	marker.CanQuery = false
	marker.CastShadow = false
	marker.Material = Enum.Material.Neon
	marker.Color = Style.DestinationPending
	marker.Transparency = 0.12
	return marker
end

local function destinationColor(status: string): Color3
	if status == "projected" then
		return Style.DestinationProjected
	end
	if status == "accepted" then
		return Style.DestinationAccepted
	end
	if status == "rejected" then
		return Style.DestinationRejected
	end
	return Style.DestinationPending
end

local function projectedCandidate(
	actorId: string,
	model: Model,
	camera: Camera
): InteractionMath.ScreenCandidate?
	local boundsCFrame, boundsSize = model:GetBoundingBox()
	local minimum = Vector2.new(math.huge, math.huge)
	local maximum = Vector2.new(-math.huge, -math.huge)
	local minimumDepth = math.huge
	local projectedCount = 0

	for _, corner in InteractionMath.boundsCorners(boundsCFrame, boundsSize) do
		local projected = camera:WorldToViewportPoint(corner)
		if projected.Z > 0 then
			projectedCount += 1
			minimum = Vector2.new(
				math.min(minimum.X, projected.X),
				math.min(minimum.Y, projected.Y)
			)
			maximum = Vector2.new(
				math.max(maximum.X, projected.X),
				math.max(maximum.Y, projected.Y)
			)
			minimumDepth = math.min(minimumDepth, projected.Z)
		end
	end

	if projectedCount == 0 then
		return nil
	end

	local padding = Style.ScreenPickPaddingPixels
	return {
		actorId = actorId,
		minimum = minimum - Vector2.new(padding, padding),
		maximum = maximum + Vector2.new(padding, padding),
		depth = minimumDepth,
	}
end

function Renderer.new(parent: Instance?, resolver: any?): Renderer
	local folder = ensureFolder(parent or Workspace)
	return setmetatable({
		folder = folder,
		resolver = resolver or TokenAssetResolver.new(),
		records = {},
		selectedActorId = nil,
		destination = nil,
		SelectionChanged = Signal.new(),
		Reconciled = Signal.new(),
		DestinationChanged = Signal.new(),
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
		position = Vector3.zero,
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

function Renderer.reconcile(self: Renderer, payload: any, revision: number?): ReconcileSummary
	local summary = {
		created = 0,
		updated = 0,
		removed = 0,
		count = 0,
		revision = revision,
	}
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
					summary.created += 1
				elseif (record.position - position).Magnitude > 0.001 then
					summary.updated += 1
				end
				record.actor = actor
				record.position = position
				record.label.Text = Contract.displayName(payload, actor)
				updateActorAttributes(record.model, actor)
				record.model:PivotTo(CFrame.new(position))
				record.highlight.Enabled = self.selectedActorId == actorId

				local destination = self.destination
				if
					destination ~= nil
					and destination.actorId == actorId
					and destination.status ~= "projected"
					and (position - destination.position).Magnitude
						<= Style.DestinationProjectionTolerance
				then
					self:resolveDestination(
						destination.commandId,
						"projected",
						revision,
						nil
					)
				end
			end
		end
	end
	for actorId in self.records do
		if active[actorId] ~= true then
			self:_destroyRecord(actorId)
			summary.removed += 1
		end
	end
	summary.count = self:tokenCount()
	self.Reconciled:Fire(summary)
	return summary
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

function Renderer.actorIdFromViewportPoint(
	self: Renderer,
	camera: Camera,
	viewportPosition: Vector2,
	maximumDistancePixels: number?
): string?
	local candidates = {}
	for actorId, record in self.records do
		local candidate = projectedCandidate(actorId, record.model, camera)
		if candidate ~= nil then
			table.insert(candidates, candidate)
		end
	end
	return InteractionMath.chooseScreenCandidate(
		viewportPosition,
		candidates,
		maximumDistancePixels or Style.ScreenPickFallbackPixels
	)
end

function Renderer.getSelectedActorId(self: Renderer): string?
	return self.selectedActorId
end

function Renderer.getTokenModel(self: Renderer, actorId: string): Model?
	local record = self.records[actorId]
	return if record ~= nil then record.model else nil
end

function Renderer.getWorldBounds(self: Renderer): (Vector3?, Vector3?)
	local minimum = Vector3.new(math.huge, math.huge, math.huge)
	local maximum = Vector3.new(-math.huge, -math.huge, -math.huge)
	local found = false
	for _, record in self.records do
		local boundsCFrame, boundsSize = record.model:GetBoundingBox()
		for _, corner in InteractionMath.boundsCorners(boundsCFrame, boundsSize) do
			found = true
			minimum = Vector3.new(
				math.min(minimum.X, corner.X),
				math.min(minimum.Y, corner.Y),
				math.min(minimum.Z, corner.Z)
			)
			maximum = Vector3.new(
				math.max(maximum.X, corner.X),
				math.max(maximum.Y, corner.Y),
				math.max(maximum.Z, corner.Z)
			)
		end
	end
	if not found then
		return nil, nil
	end
	return (minimum + maximum) * 0.5, maximum - minimum
end

function Renderer.isSelectedHighlighted(self: Renderer, actorId: string): boolean
	local record = self.records[actorId]
	return record ~= nil and self.selectedActorId == actorId and record.highlight.Enabled
end

function Renderer.showDestination(
	self: Renderer,
	actorId: string,
	position: Vector3,
	commandId: string
)
	self:clearDestination(nil)
	local marker = createDestinationMarker(position)
	marker:SetAttribute("RVTTActorId", actorId)
	marker:SetAttribute("RVTTCommandId", commandId)
	marker.Parent = self.folder
	self.destination = {
		marker = marker,
		actorId = actorId,
		commandId = commandId,
		position = position,
		status = "pending",
		revision = nil,
		code = nil,
	}
	self.DestinationChanged:Fire(self.destination)
end

function Renderer.resolveDestination(
	self: Renderer,
	commandId: string,
	status: string,
	revision: number?,
	code: string?
)
	local destination = self.destination
	if destination == nil or destination.commandId ~= commandId then
		return
	end
	destination.status = status
	destination.revision = revision
	destination.code = code
	destination.marker.Color = destinationColor(status)
	destination.marker.Transparency = if status == "rejected" then 0.35 else 0.08
	self.DestinationChanged:Fire(destination)
	if status == "rejected" or status == "projected" then
		task.delay(Style.DestinationMarkerLifetimeSeconds, function()
			self:clearDestination(commandId)
		end)
	end
end

function Renderer.clearDestination(self: Renderer, commandId: string?)
	local destination = self.destination
	if destination == nil then
		return
	end
	if commandId ~= nil and destination.commandId ~= commandId then
		return
	end
	destination.marker:Destroy()
	self.destination = nil
	self.DestinationChanged:Fire(nil)
end

function Renderer.getDestinationStatus(self: Renderer): string?
	local destination = self.destination
	return if destination ~= nil then destination.status else nil
end

function Renderer.tokenCount(self: Renderer): number
	local count = 0
	for _ in self.records do
		count += 1
	end
	return count
end

function Renderer.destroy(self: Renderer)
	self:clearDestination(nil)
	for actorId in self.records do
		self:_destroyRecord(actorId)
	end
	self.SelectionChanged:Destroy()
	self.Reconciled:Destroy()
	self.DestinationChanged:Destroy()
	self.folder:Destroy()
end

return Renderer
