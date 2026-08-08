--!strict

local Style = require(script.Parent.WorldTokenStyle)

local Renderer = {}
Renderer.__index = Renderer

local function colorFor(preview: any): Color3
	if preview.state == "stale" then
		return Style.PreviewStale
	end
	return if preview.enabled then Style.PreviewValid else Style.PreviewInvalid
end

local function previewText(preview: any): string
	local segments = { preview.label .. " · " .. preview.targetLabel }
	if type(preview.distance) == "number" then
		table.insert(segments, string.format("거리 %.1f studs", preview.distance))
	end
	if type(preview.remaining) == "number" then
		table.insert(segments, string.format("남은 이동 %.1f", preview.remaining))
	end
	if type(preview.excess) == "number" and preview.excess > 0 then
		table.insert(segments, string.format("초과 %.1f", preview.excess))
	end
	if type(preview.disabledReason) == "string" then
		table.insert(segments, preview.disabledReason)
	end
	for _, risk in preview.riskLabels do
		table.insert(segments, risk)
	end
	return table.concat(segments, " · ")
end

local function marker(position: Vector3, color: Color3): Part
	local value = Instance.new("Part")
	value.Name = "PreviewTarget"
	value.Shape = Enum.PartType.Cylinder
	value.Size = Vector3.new(0.08, 3.2, 3.2)
	value.CFrame = CFrame.new(position + Vector3.new(0, 0.05, 0))
		* CFrame.Angles(0, 0, math.rad(90))
	value.Anchored = true
	value.CanCollide = false
	value.CanTouch = false
	value.CanQuery = false
	value.CastShadow = false
	value.Material = Enum.Material.Neon
	value.Color = color
	value.Transparency = 0.22
	return value
end

local function lineBetween(from: Vector3, to: Vector3, color: Color3): Part?
	local distance = (to - from).Magnitude
	if distance <= 0.01 then
		return nil
	end
	local value = Instance.new("Part")
	value.Name = "PreviewPath"
	value.Size = Vector3.new(Style.PreviewLineThickness, Style.PreviewLineThickness, distance)
	value.CFrame = CFrame.lookAt(from:Lerp(to, 0.5), to)
	value.Anchored = true
	value.CanCollide = false
	value.CanTouch = false
	value.CanQuery = false
	value.CastShadow = false
	value.Material = Enum.Material.Neon
	value.Color = color
	value.Transparency = 0.18
	return value
end

local function label(adornee: BasePart, text: string, color: Color3): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Name = "PreviewLabel"
	gui.Adornee = adornee
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Size = UDim2.fromOffset(360, 54)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.4, 0)

	local value = Instance.new("TextLabel")
	value.Size = UDim2.fromScale(1, 1)
	value.BackgroundColor3 = Color3.fromRGB(20, 23, 29)
	value.BackgroundTransparency = 0.16
	value.BorderSizePixel = 0
	value.Font = Enum.Font.GothamMedium
	value.Text = text
	value.TextColor3 = color
	value.TextSize = 13
	value.TextWrapped = true
	value.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = value
	return gui
end

function Renderer.new(worldRenderer: any): any
	local folder = Instance.new("Folder")
	folder.Name = "RVTT_WorldPreview"
	folder.Parent = worldRenderer.folder
	return setmetatable({
		worldRenderer = worldRenderer,
		folder = folder,
		targetHighlight = nil,
	}, Renderer)
end

function Renderer:clear()
	self.folder:ClearAllChildren()
	if self.targetHighlight ~= nil then
		self.targetHighlight:Destroy()
		self.targetHighlight = nil
	end
end

function Renderer:render(preview: any?)
	self:clear()
	if type(preview) ~= "table" then
		return
	end
	local color = colorFor(preview)
	local targetPart = nil
	if type(preview.targetActorId) == "string" then
		local targetModel = self.worldRenderer:getTokenModel(preview.targetActorId)
		if targetModel ~= nil then
			local highlight = Instance.new("Highlight")
			highlight.Name = "RVTTPreviewHighlight"
			highlight.Adornee = targetModel
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.FillColor = color
			highlight.FillTransparency = 0.82
			highlight.OutlineColor = color
			highlight.Parent = targetModel
			self.targetHighlight = highlight
			targetPart = targetModel.PrimaryPart
		end
	end
	if preview.kind == "move" and typeof(preview.position) == "Vector3" then
		local destination = marker(preview.position, color)
		destination.Parent = self.folder
		targetPart = destination
		local actorModel = self.worldRenderer:getTokenModel(preview.actorId)
		if actorModel ~= nil and actorModel.PrimaryPart ~= nil then
			local path = lineBetween(actorModel.PrimaryPart.Position, preview.position, color)
			if path ~= nil then
				path.Parent = self.folder
			end
		end
	end
	if targetPart ~= nil then
		local gui = label(targetPart, previewText(preview), color)
		gui.Parent = self.folder
	end
end

function Renderer:destroy()
	self:clear()
	self.folder:Destroy()
end

return Renderer
