--!strict

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Signal = require(ReplicatedStorage.RVTT.Shared.Core.Signal)

local FRAME_ACTION = "RVTTWorldCameraFrame"
local PAN_ACTION = "RVTTWorldCameraPan"
local INPUT_PRIORITY = Enum.ContextActionPriority.High.Value
local MIN_POINTER_DELTA = 0.01

export type Controller = {
	renderer: any,
	enabled: boolean,
	target: Vector3,
	distance: number,
	yaw: number,
	elevation: number,
	dragging: boolean,
	lastPointerPosition: Vector2?,
	connections: { RBXScriptConnection },
	previousType: Enum.CameraType?,
	previousCFrame: CFrame?,
	Changed: any,
	InputResolved: any,
	_apply: (self: Controller, event: string) -> boolean,
	_reportInput: (
		self: Controller,
		action: string,
		source: string,
		processed: boolean,
		before: CFrame?,
		applied: boolean
	) -> (),
	framePosition: (self: Controller, position: Vector3, distance: number?) -> boolean,
	frameSelected: (self: Controller) -> boolean,
	requestFrame: (self: Controller, source: string, processed: boolean?) -> boolean,
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

local function cframeChanged(before: CFrame?, after: CFrame?): boolean
	if before == nil or after == nil then
		return false
	end
	if (after.Position - before.Position).Magnitude > 0.001 then
		return true
	end
	return before.LookVector:Dot(after.LookVector) < 0.99999
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
		lastPointerPosition = nil,
		connections = {},
		previousType = nil,
		previousCFrame = nil,
		Changed = Signal.new(),
		InputResolved = Signal.new(),
	}, Controller) :: any
end

function Controller._apply(self: Controller, event: string): boolean
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

function Controller._reportInput(
	self: Controller,
	action: string,
	source: string,
	processed: boolean,
	before: CFrame?,
	applied: boolean
)
	local currentCamera = camera()
	local changed = currentCamera ~= nil and cframeChanged(before, currentCamera.CFrame)
	self.InputResolved:Fire(action, source, applied, changed, processed)
	print(
		string.format(
			"[RVTT WorldCamera Input] action=%s source=%s applied=%s changed=%s processed=%s",
			action,
			source,
			tostring(applied),
			tostring(changed),
			tostring(processed)
		)
	)
end

function Controller.framePosition(self: Controller, position: Vector3, distance: number?): boolean
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

function Controller.requestFrame(self: Controller, source: string, processed: boolean?): boolean
	local currentCamera = camera()
	local before = if currentCamera ~= nil then currentCamera.CFrame else nil
	local applied = self:frameSelected()
	self:_reportInput("frame", source, processed == true, before, applied)
	return applied
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
	if not self.enabled or delta.Magnitude < MIN_POINTER_DELTA then
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
	if not self.enabled or steps == 0 then
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

	ContextActionService:BindActionAtPriority(
		FRAME_ACTION,
		function(_actionName: string, inputState: Enum.UserInputState): Enum.ContextActionResult
			if inputState ~= Enum.UserInputState.Begin then
				return Enum.ContextActionResult.Sink
			end
			if UserInputService:GetFocusedTextBox() ~= nil then
				return Enum.ContextActionResult.Pass
			end
			self:requestFrame("keyboard-f", false)
			return Enum.ContextActionResult.Sink
		end,
		false,
		INPUT_PRIORITY,
		Enum.KeyCode.F
	)
	ContextActionService:BindActionAtPriority(
		PAN_ACTION,
		function(_actionName: string, inputState: Enum.UserInputState): Enum.ContextActionResult
			if inputState == Enum.UserInputState.Begin then
				self.dragging = true
				self.lastPointerPosition = UserInputService:GetMouseLocation()
				print("[RVTT WorldCamera Input] action=pan-start source=mouse-middle")
			elseif
				inputState == Enum.UserInputState.End
				or inputState == Enum.UserInputState.Cancel
			then
				self.dragging = false
				self.lastPointerPosition = nil
				print("[RVTT WorldCamera Input] action=pan-end source=mouse-middle")
			end
			return Enum.ContextActionResult.Sink
		end,
		false,
		INPUT_PRIORITY,
		Enum.UserInputType.MouseButton3
	)

	table.insert(
		self.connections,
		UserInputService.InputChanged:Connect(function(input, processed)
			if input.UserInputType ~= Enum.UserInputType.MouseWheel then
				return
			end
			local current = camera()
			local before = if current ~= nil then current.CFrame else nil
			local applied = self:zoomBy(-input.Position.Z)
			self:_reportInput("zoom", "mouse-wheel", processed, before, applied)
		end)
	)
	table.insert(
		self.connections,
		RunService.RenderStepped:Connect(function()
			if not self.dragging then
				return
			end
			local pointerPosition = UserInputService:GetMouseLocation()
			local previousPointerPosition = self.lastPointerPosition
			self.lastPointerPosition = pointerPosition
			if previousPointerPosition == nil then
				return
			end
			local delta = pointerPosition - previousPointerPosition
			if delta.Magnitude < MIN_POINTER_DELTA then
				return
			end
			local current = camera()
			local before = if current ~= nil then current.CFrame else nil
			local applied = self:panPixels(delta)
			self:_reportInput("pan", "mouse-middle-screen-delta", false, before, applied)
		end)
	)
	table.insert(
		self.connections,
		UserInputService.WindowFocusReleased:Connect(function()
			self.dragging = false
			self.lastPointerPosition = nil
		end)
	)
end

function Controller.destroy(self: Controller)
	ContextActionService:UnbindAction(FRAME_ACTION)
	ContextActionService:UnbindAction(PAN_ACTION)
	for _, connection in self.connections do
		connection:Disconnect()
	end
	table.clear(self.connections)
	self.dragging = false
	self.lastPointerPosition = nil
	local currentCamera = camera()
	if currentCamera ~= nil then
		if self.previousType ~= nil then
			currentCamera.CameraType = self.previousType
		end
		if self.previousCFrame ~= nil then
			currentCamera.CFrame = self.previousCFrame
		end
	end
	self.InputResolved:Destroy()
	self.Changed:Destroy()
end

return Controller
