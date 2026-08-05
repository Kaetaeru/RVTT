--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Style = require(script.Parent.WorldTokenStyle)

export type Resolver = {
	resolve: (self: Resolver, actor: any) -> Model,
}

local Resolver = {}
Resolver.__index = Resolver

local function actorColor(actorId: string): Color3
	local hash = 0
	for index = 1, #actorId do
		hash = (hash * 33 + string.byte(actorId, index)) % 360
	end
	return Color3.fromHSV(hash / 360, 0.5, 0.88)
end

local function configurePart(part: BasePart, actorId: string, queryable: boolean)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = queryable
	part.CastShadow = true
	part.Massless = true
	part:SetAttribute("RVTTActorId", actorId)
end

local function removeExecutableDescendants(root: Instance)
	for _, descendant in root:GetDescendants() do
		if
			descendant:IsA("Script")
			or descendant:IsA("LocalScript")
			or descendant:IsA("ModuleScript")
		then
			descendant:Destroy()
		end
	end
end

local function candidateAsset(actor: any): Instance?
	local rvtt = ReplicatedStorage:FindFirstChild("RVTT")
	local assets = if rvtt ~= nil then rvtt:FindFirstChild("TokenAssets") else nil
	if assets == nil then
		return nil
	end
	local names = {
		actor.sourceCharacterId,
		actor.sourceNpcId,
		actor.id,
		"Default",
	}
	for _, name in names do
		if type(name) == "string" then
			local candidate = assets:FindFirstChild(name)
			if candidate ~= nil and (candidate:IsA("Model") or candidate:IsA("BasePart")) then
				return candidate
			end
		end
	end
	return nil
end

local function addFallbackPart(
	model: Model,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	shape: Enum.PartType?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	if shape ~= nil then
		part.Shape = shape
	end
	part.Parent = model
	return part
end

local function createFallbackVisual(model: Model, actorId: string)
	local color = actorColor(actorId)
	local base = addFallbackPart(
		model,
		"MiniatureBase",
		Vector3.new(0.36, 3.2, 3.2),
		CFrame.new(0, 0.18, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Style.FallbackBase,
		Enum.PartType.Cylinder
	)
	configurePart(base, actorId, true)

	local body = addFallbackPart(
		model,
		"MiniatureBody",
		Vector3.new(1.45, 2.5, 1.1),
		CFrame.new(0, 1.58, 0),
		color,
		nil
	)
	configurePart(body, actorId, true)

	local head = addFallbackPart(
		model,
		"MiniatureHead",
		Vector3.new(1.15, 1.15, 1.15),
		CFrame.new(0, 3.38, 0),
		color:Lerp(Color3.new(1, 1, 1), 0.18),
		Enum.PartType.Ball
	)
	configurePart(head, actorId, true)

	local marker = addFallbackPart(
		model,
		"FacingMarker",
		Vector3.new(0.26, 0.26, 0.9),
		CFrame.new(0, 0.42, -1.5),
		color,
		nil
	)
	configurePart(marker, actorId, true)
end

local function normalizeModelVisual(visual: Model)
	local boundsCFrame, boundsSize = visual:GetBoundingBox()
	local minimumY = boundsCFrame.Position.Y - boundsSize.Y * 0.5
	local delta = CFrame.new(-boundsCFrame.Position.X, -minimumY, -boundsCFrame.Position.Z)
	visual:PivotTo(delta * visual:GetPivot())
end

local function addCandidateVisual(wrapper: Model, actor: any, actorId: string): boolean
	local candidate = candidateAsset(actor)
	if candidate == nil then
		return false
	end
	local clone = candidate:Clone()
	removeExecutableDescendants(clone)
	clone.Parent = wrapper
	if clone:IsA("Model") then
		normalizeModelVisual(clone)
	else
		local part = clone :: BasePart
		part.CFrame = CFrame.new(0, part.Size.Y * 0.5, 0)
	end
	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("BasePart") then
			configurePart(descendant, actorId, true)
		end
	end
	if clone:IsA("BasePart") then
		configurePart(clone, actorId, true)
	end
	return true
end

function Resolver.new(): Resolver
	return setmetatable({}, Resolver) :: any
end

function Resolver.resolve(_self: Resolver, actor: any): Model
	local actorId = tostring(actor.id)
	local model = Instance.new("Model")
	model.Name = "Token_" .. actorId
	model:SetAttribute("RVTTActorId", actorId)
	model:SetAttribute("RVTTTokenRoot", true)

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.CFrame = CFrame.new()
	root.Transparency = 1
	root.CastShadow = false
	configurePart(root, actorId, false)
	root.Parent = model
	model.PrimaryPart = root

	if not addCandidateVisual(model, actor, actorId) then
		createFallbackVisual(model, actorId)
	end

	return model
end

return Resolver
