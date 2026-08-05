--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Signal = require(ReplicatedStorage.RVTT.Shared.Core.Signal)

export type Controller = {
	renderer: any,
	enabled: boolean,
	target: Vector3,
	distance: number,
	yaw: number,
	elevation: number,
	dragging: boolean,
	connections: { RBXScriptConnection },
	previousType: Enum.CameraType?,
	previousCFrame: CFrame?,
	Changed: any,
	_apply: (self: Controller, event: string) -> boolean,
	framePosition: (self: Controller, position: Vector3, distance: number?) -> boolean,
	frameSelected: (self: Controller) -> boolean,
	frameAll: (self: Controller) -> boolean,
	panPixels: (self: Controller, delta: Vector2) -> boolean,
	zoomBy: (self: Controller, steps: number) -> boolean,
	start: (self: Controller) -> (),
	destroy: (self: Controller) -> (),
}

local Controller = {}
Controller.__index = Controller

local function camera(): Camera?
	return Workspace.CurrentCamera
end

local function flatUnit(vector: Vector3, fallback: Vector3): Vector3
	local flat = Vector3.new(vector.X, 0, vector.Z)
	return if flat.Magnitude > 0.001 then flat.Unit else fallback
end

function Controller.new(renderer: any, enabled: boolean): Controller
	return setmetatable({
		renderer = renderer,
		enabled = enabled,
		target = Vector3.new(8, 1, 8),
		distance = 36,
		yaw = math.rad(45),
		elevation = math.rad(38),
		dragging = false,
		connections = {},
		previousType = nil,
		previousCFrame = nil,
		Changed = Signal.new(),
	}, Controller) :: any
end

function Controller:_apply(event: string): boolean
	if not self.enabled then
		return false
	end
	local currentCamera = camera()
	if currentCamera == nil then
		return false
	end
	local horizontal = math.cos(self.elevation) * self.distance
	local offset = Vector3.new(
		math.sin(self.yaw) * horizontal,
		math.sin(self.elevation) * self.distance,
		math.cos(self.yaw) * horizontal
	)
	currentCamera.CameraType = Enum.CameraType.Scriptable
	currentCamera.CFrame = CFrame.lookAt(self.target + offset, self.target)
	self.Changed:Fire(event, self.target, self.distance, currentCamera.CFrame)
	return true
end

function Controller.framePosition(
	self: Controller,
	position: Vector3,
	distance: number?
): boolean
	self.target = position + Vector3.new(0, 1.2, 0)
	if distance ~= nil then
		self.distance = math.clamp(distance, 12, 120)
	end
	return self:_apply("frame")
end

function Controller.frameSelected(self: Controller): boolean
	local actorId = self.renderer:getSelectedActorId()
	if actorId == nil then
		return self:frameAll()
	end
	local model = self.renderer:getTokenModel(actorId)
	if model == nil then
		return self:frameAll()
	end
	local boundsCFrame, boundsSize = model:GetBoundingBox()
	local distance = math.clamp(math.max(boundsSize.X, boundsSize.Y, boundsSize.Z) * 4.5, 18, 48)
	return self:framePosition(boundsCFrame.Position, distance)
end

function Controller.frameAll(self: Controller): boolean
	local center, size = self.renderer:getWorldBounds()
	if center == nil or size == nil then
		return self:framePosition(Vector3.new(8, 0, 8), 38)
	end
	local distance = math.clamp(math.max(size.X, size.Y, size.Z) * 2.1 + 14, 22, 110)
	return self:framePosition(center, distance)
end

function Controller.panPixels(self: Controller, delta: Vector2): boolean
	if not self.enabled then
		return false
	end
	local currentCamera = camera()
	if currentCamera == nil then
		return false
	end
	local right = flatUnit(currentCamera.CFrame.RightVector, Vector3.new(1, 0, 0))
	local forward = flatUnit(currentCamera.CFrame.LookVector, Vector3.new(0, 0, -1))
	local scale = self.distance * 0.0027
	self.target += (-right * delta.X + forward * delta.Y) * scale
	return self:_apply("pan")
end

function Controller.zoomBy(self: Controller, steps: number): boolean
	if not self.enabled then
		return false
	end
	self.distance = math.clamp(self.distance * (1 + steps * 0.12), 12, 120)
	return self:_apply("zoom")
end

function Controller.start(self: Controller)
	if not self.enabled or #self.connections > 0 then
		return
	end
	local currentCamera = camera()
	if currentCamera ~= nil then
		self.previousType = currentCamera.CameraType
		self.previousCFrame = currentCamera.CFrame
	end
	self:frameAll()

	table.insert(
		self.connections,
		UserInputService.InputBegan:Connect(function(input, processed)
			if processed then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseButton3 then
				self.dragging = true
			elseif input.KeyCode == Enum.KeyCode.F then
				self:frameSelected()
			end
		end)
	)
	table.insert(
		self.connections,
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton3 then
				self.dragging = false
			end
		end)
	)
	table.insert(
		self.connections,
		UserInputService.InputChanged:Connect(function(input, processed)
			if processed then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseWheel then
				self:zoomBy(-input.Position.Z)
			elseif
				self.dragging
				and input.UserInputType == Enum.UserInputType.MouseMovement
			then
				self:panPixels(Vector2.new(input.Delta.X, input.Delta.Y))
			end
		end)
	)
end

function Controller.destroy(self: Controller)
	for _, connection in self.connections do
		connection:Disconnect()
	end
	table.clear(self.connections)
	self.dragging = false
	local currentCamera = camera()
	if currentCamera ~= nil then
		if self.previousType ~= nil then
			currentCamera.CameraType = self.previousType
		end
		if self.previousCFrame ~= nil then
			currentCamera.CFrame = self.previousCFrame
		end
	end
	self.Changed:Destroy()
end

return Controller
