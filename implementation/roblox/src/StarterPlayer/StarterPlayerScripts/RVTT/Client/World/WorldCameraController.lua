--!strict

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Signal = require(ReplicatedStorage.RVTT.Shared.Core.Signal)

local BASE_YAW = math.rad(180)
local DEFAULT_PITCH = math.rad(45)
local MIN_PITCH = math.rad(-85)
local MAX_PITCH = math.rad(85)
local DEFAULT_DISTANCE = 65
local MIN_DISTANCE = 20
local MAX_DISTANCE = 130
local ROTATE_SENSITIVITY = 0.004
local ZOOM_STEP = 5
local VERTICAL_MOVE_STEP = 5
local SMOOTH_SPEED = 14
local CAMERA_MOVE_SPEED = 55
local FIELD_OF_VIEW = 50

local Controller = {}
Controller.__index = Controller

local function clamp(value: number, minimum: number, maximum: number): number
	return math.max(minimum, math.min(maximum, value))
end

local function isPointerOverVisibleUi(): boolean
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if playerGui == nil then
		return false
	end

	local function contains(position: Vector2, ignoreInset: boolean): boolean
		for _, guiObject in playerGui:GetGuiObjectsAtPosition(position.X, position.Y) do
			local screenGui = guiObject:FindFirstAncestorOfClass("ScreenGui")
			if screenGui ~= nil and screenGui.Enabled and screenGui.IgnoreGuiInset == ignoreInset then
				if guiObject:IsA("GuiButton")
					or guiObject:IsA("TextBox")
					or guiObject:IsA("ScrollingFrame")
					or guiObject.BackgroundTransparency < 1
				then
					return true
				end
				if guiObject:IsA("TextLabel") and guiObject.Text ~= "" and guiObject.TextTransparency < 1 then
					return true
				end
				if guiObject:IsA("ImageLabel") and guiObject.Image ~= "" and guiObject.ImageTransparency < 1 then
					return true
				end
			end
		end
		return false
	end

	local pointer = UserInputService:GetMouseLocation()
	if contains(pointer, true) then
		return true
	end
	local inset = GuiService:GetGuiInset()
	return contains(pointer - inset, false)
end

function Controller.new(renderer: any, acceptanceMode: boolean?): any
	return setmetatable({
		renderer = renderer,
		acceptanceMode = acceptanceMode == true,
		camera = nil,
		targetPivot = Vector3.zero,
		currentPivot = Vector3.zero,
		targetDistance = DEFAULT_DISTANCE,
		currentDistance = DEFAULT_DISTANCE,
		targetYawOffset = 0,
		currentYawOffset = 0,
		targetPitch = DEFAULT_PITCH,
		currentPitch = DEFAULT_PITCH,
		middleMouseDown = false,
		lastMousePosition = nil,
		keyState = { W = false, A = false, S = false, D = false },
		keyboardPanSuppressors = {},
		connections = {},
		started = false,
		FrameRequested = Signal.new(),
		InputResolved = Signal.new(),
	}, Controller)
end

function Controller:_cameraPosition(): Vector3
	local finalYaw = BASE_YAW + self.currentYawOffset
	local horizontalDistance = math.cos(self.currentPitch) * self.currentDistance
	local verticalDistance = math.sin(self.currentPitch) * self.currentDistance
	local offset = CFrame.Angles(0, finalYaw, 0):VectorToWorldSpace(
		Vector3.new(0, verticalDistance, -horizontalDistance)
	)
	return self.currentPivot + offset
end

function Controller:_updateCamera()
	local camera = Workspace.CurrentCamera
	if camera == nil then
		return
	end
	self.camera = camera
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = FIELD_OF_VIEW
	local cameraPosition = self:_cameraPosition()
	local lookDirection = (self.currentPivot - cameraPosition).Unit
	local upDirection = Vector3.yAxis
	if math.abs(lookDirection:Dot(upDirection)) > 0.999 then
		local finalYaw = BASE_YAW + self.currentYawOffset
		upDirection = CFrame.Angles(0, finalYaw, 0):VectorToWorldSpace(Vector3.new(0, 0, -1))
	end
	camera.CFrame = CFrame.lookAt(cameraPosition, self.currentPivot, upDirection)
	camera.Focus = CFrame.new(self.currentPivot)
end

function Controller:_flatAxes(): (Vector3, Vector3)
	local lookVector = (self.currentPivot - self:_cameraPosition()).Unit
	local flatForward = Vector3.new(lookVector.X, 0, lookVector.Z)
	if flatForward.Magnitude < 0.001 then
		flatForward = Vector3.new(0, 0, -1)
	else
		flatForward = flatForward.Unit
	end
	local flatRight = Vector3.new(flatForward.Z, 0, -flatForward.X).Unit
	return flatRight, flatForward
end

function Controller:_updateKeyboard(deltaTime: number)
	if next(self.keyboardPanSuppressors) ~= nil then
		return
	end
	local right, forward = self:_flatAxes()
	local move = Vector3.zero
	if self.keyState.W then
		move += forward
	end
	if self.keyState.S then
		move -= forward
	end
	if self.keyState.A then
		move += right
	end
	if self.keyState.D then
		move -= right
	end
	if move.Magnitude <= 0 then
		return
	end
	move = move.Unit
	self.targetPivot += Vector3.new(move.X, 0, move.Z) * CAMERA_MOVE_SPEED * deltaTime
	self.InputResolved:Fire("pan", "keyboard-wasd", true, true, false)
end

function Controller:_selectedBounds(): (Vector3?, Vector3?)
	local actorId = self.renderer:getSelectedActorId()
	if actorId == nil then
		return nil, nil
	end
	local model = self.renderer:getTokenModel(actorId)
	if model == nil then
		return nil, nil
	end
	local boundsCFrame, boundsSize = model:GetBoundingBox()
	return boundsCFrame.Position, boundsSize
end

function Controller:requestFrame(source: string?, processed: boolean?): boolean
	local center, size = self:_selectedBounds()
	if center == nil then
		self.InputResolved:Fire("frame", source or "api", false, false, processed == true)
		return false
	end
	local previous = self.targetPivot
	self.targetPivot = center
	if size ~= nil then
		self.targetDistance = clamp(math.max(size.X, size.Y, size.Z) * 4, MIN_DISTANCE, MAX_DISTANCE)
	end
	local changed = (previous - center).Magnitude > 0.001
	self.FrameRequested:Fire(source or "api", center)
	self.InputResolved:Fire("frame", source or "api", true, changed, processed == true)
	return true
end

function Controller:setFrameResolver(_: any)
	-- Kept for compatibility. Framing is resolved from the selected renderer token.
end

function Controller:setKeyboardPanSuppressed(ownerKey: string, suppressed: boolean): boolean
	if ownerKey == "" then
		return false
	end
	if suppressed then
		self.keyboardPanSuppressors[ownerKey] = true
		self.keyState.W = false
		self.keyState.A = false
		self.keyState.S = false
		self.keyState.D = false
	else
		self.keyboardPanSuppressors[ownerKey] = nil
	end
	return true
end

function Controller:focusOnPosition(position: Vector3): boolean
	self.targetPivot = position
	return true
end

function Controller:getTargetPivot(): Vector3
	return self.targetPivot
end

function Controller:_onInputBegan(input: InputObject, processed: boolean)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton3 then
		if isPointerOverVisibleUi() then
			self.InputResolved:Fire("orbit", "mouse-middle", false, false, false)
			return
		end
		self.middleMouseDown = true
		self.lastMousePosition = UserInputService:GetMouseLocation()
		return
	end
	if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.F then
		self:requestFrame(if input.KeyCode == Enum.KeyCode.F then "keyboard-f" else "keyboard-space", false)
		return
	end
	if input.KeyCode == Enum.KeyCode.W then
		self.keyState.W = true
	elseif input.KeyCode == Enum.KeyCode.A then
		self.keyState.A = true
	elseif input.KeyCode == Enum.KeyCode.S then
		self.keyState.S = true
	elseif input.KeyCode == Enum.KeyCode.D then
		self.keyState.D = true
	end
end

function Controller:_onInputEnded(input: InputObject)
	if input.UserInputType == Enum.UserInputType.MouseButton3 then
		self.middleMouseDown = false
		self.lastMousePosition = nil
	elseif input.KeyCode == Enum.KeyCode.W then
		self.keyState.W = false
	elseif input.KeyCode == Enum.KeyCode.A then
		self.keyState.A = false
	elseif input.KeyCode == Enum.KeyCode.S then
		self.keyState.S = false
	elseif input.KeyCode == Enum.KeyCode.D then
		self.keyState.D = false
	end
end

function Controller:_onInputChanged(input: InputObject, processed: boolean)
	if input.UserInputType ~= Enum.UserInputType.MouseWheel then
		return
	end
	if processed or isPointerOverVisibleUi() then
		self.InputResolved:Fire("zoom", "mouse-wheel", false, false, processed)
		return
	end
	local scroll = input.Position.Z
	local controlDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
		or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
	if controlDown then
		self.targetPivot += Vector3.new(0, scroll * VERTICAL_MOVE_STEP, 0)
		self.InputResolved:Fire("vertical", "control-wheel", true, scroll ~= 0, false)
		return
	end
	local previous = self.targetDistance
	self.targetDistance = clamp(self.targetDistance - scroll * ZOOM_STEP, MIN_DISTANCE, MAX_DISTANCE)
	self.InputResolved:Fire("zoom", "mouse-wheel", true, previous ~= self.targetDistance, false)
end

function Controller:_render(deltaTime: number)
	if self.middleMouseDown and self.lastMousePosition ~= nil then
		local mousePosition = UserInputService:GetMouseLocation()
		local delta = mousePosition - self.lastMousePosition
		self.lastMousePosition = mousePosition
		if delta.Magnitude > 0.01 then
			self.targetYawOffset -= delta.X * ROTATE_SENSITIVITY
			self.targetPitch = clamp(
				self.targetPitch + delta.Y * ROTATE_SENSITIVITY,
				MIN_PITCH,
				MAX_PITCH
			)
			self.InputResolved:Fire("orbit", "mouse-middle", true, true, false)
		end
	end

	self:_updateKeyboard(deltaTime)
	local alpha = 1 - math.exp(-SMOOTH_SPEED * deltaTime)
	self.currentPivot = self.currentPivot:Lerp(self.targetPivot, alpha)
	self.currentDistance += (self.targetDistance - self.currentDistance) * alpha
	self.currentYawOffset += (self.targetYawOffset - self.currentYawOffset) * alpha
	self.currentPitch += (self.targetPitch - self.currentPitch) * alpha
	self:_updateCamera()
end

function Controller:start()
	if self.started then
		return
	end
	self.started = true
	self.camera = Workspace.CurrentCamera
	self:_updateCamera()
	table.insert(self.connections, UserInputService.InputBegan:Connect(function(input, processed)
		self:_onInputBegan(input, processed)
	end))
	table.insert(self.connections, UserInputService.InputEnded:Connect(function(input)
		self:_onInputEnded(input)
	end))
	table.insert(self.connections, UserInputService.InputChanged:Connect(function(input, processed)
		self:_onInputChanged(input, processed)
	end))
	table.insert(self.connections, RunService.RenderStepped:Connect(function(deltaTime)
		self:_render(deltaTime)
	end))
end

function Controller:destroy()
	if not self.started then
		return
	end
	self.started = false
	for _, connection in self.connections do
		connection:Disconnect()
	end
	self.connections = {}
	self.FrameRequested:Destroy()
	self.InputResolved:Destroy()
end

return Controller
