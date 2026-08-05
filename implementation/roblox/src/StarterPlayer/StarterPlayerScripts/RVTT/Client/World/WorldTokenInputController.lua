--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Signal = require(ReplicatedStorage.RVTT.Shared.Core.Signal)
local Contract = require(ReplicatedStorage.RVTT.Shared.World.WorldTokenContract)

export type Controller = {
	renderer: any,
	replica: any,
	command: any,
	connection: RBXScriptConnection?,
	MoveRequested: any,
	_selectActor: (self: Controller, actorId: string) -> boolean,
	_moveSelected: (self: Controller, hit: RaycastResult) -> boolean,
	_handlePrimary: (self: Controller, input: InputObject) -> (),
	start: (self: Controller) -> (),
	destroy: (self: Controller) -> (),
}

local Controller = {}
Controller.__index = Controller

local rvtt = ReplicatedStorage:WaitForChild("RVTT")
local acceptanceMode = rvtt:FindFirstChild("Slice01AcceptanceMode")
local DEBUG_CLICKS = acceptanceMode ~= nil
	and acceptanceMode:IsA("BoolValue")
	and acceptanceMode.Value

local function debugClick(message: string)
	if DEBUG_CLICKS then
		print("[RVTT WorldToken Input] " .. message)
	end
end

local function screenPosition(input: InputObject): Vector2
	if
		input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.MouseButton2
	then
		return UserInputService:GetMouseLocation()
	end
	return Vector2.new(input.Position.X, input.Position.Y)
end

local function raycastFromScreen(position: Vector2): RaycastResult?
	local camera = Workspace.CurrentCamera
	if camera == nil then
		return nil
	end
	local ray = camera:ScreenPointToRay(position.X, position.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local excluded: { Instance } = {}
	local character = Players.LocalPlayer.Character
	if character ~= nil then
		table.insert(excluded, character)
	end
	params.FilterDescendantsInstances = excluded
	params.IgnoreWater = false
	return Workspace:Raycast(ray.Origin, ray.Direction * 2048, params)
end

function Controller.new(renderer: any, replica: any, command: any): Controller
	return setmetatable({
		renderer = renderer,
		replica = replica,
		command = command,
		connection = nil,
		MoveRequested = Signal.new(),
	}, Controller) :: any
end

function Controller:_selectActor(actorId: string): boolean
	local actor = Contract.actor(self.replica.payload, actorId)
	if not Contract.canControl(self.replica.payload, actor, Players.LocalPlayer.UserId) then
		debugClick("selection denied actor=" .. actorId)
		return false
	end
	return self.renderer:setSelected(actorId)
end

function Controller:_moveSelected(hit: RaycastResult): boolean
	local actorId = self.renderer:getSelectedActorId()
	if actorId == nil or not Contract.isMoveSurface(hit.Instance) then
		return false
	end
	local actor = Contract.actor(self.replica.payload, actorId)
	if not Contract.canControl(self.replica.payload, actor, Players.LocalPlayer.UserId) then
		self.renderer:setSelected(nil)
		return false
	end
	local destination = Contract.toDestination(hit.Position)
	local commandId = self.command:submit("movement.commit", {
		actorId = actorId,
		destination = destination,
	})
	self.MoveRequested:Fire(actorId, destination, commandId)
	print(
		string.format(
			"[RVTT WorldToken] move requested actor=%s destination=(%.2f, %.2f, %.2f)",
			actorId,
			destination.x,
			destination.y,
			destination.z
		)
	)
	return true
end

function Controller:_handlePrimary(input: InputObject)
	local position = screenPosition(input)
	local hit = raycastFromScreen(position)
	if hit == nil then
		debugClick(string.format("miss screen=(%.1f, %.1f)", position.X, position.Y))
		return
	end
	local actorId = self.renderer:actorIdFromInstance(hit.Instance)
	if actorId ~= nil then
		debugClick("hit token instance=" .. hit.Instance:GetFullName() .. " actor=" .. actorId)
		if self:_selectActor(actorId) then
			print("[RVTT WorldToken] selected actor=" .. actorId)
		end
		return
	end
	if self:_moveSelected(hit) then
		return
	end
	debugClick("hit non-token instance=" .. hit.Instance:GetFullName())
end

function Controller.start(self: Controller)
	if self.connection ~= nil then
		return
	end
	self.connection = UserInputService.InputBegan:Connect(function(input, processed)
		local primary = input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		if processed then
			if primary then
				local position = screenPosition(input)
				debugClick(
					string.format("ignored processed input screen=(%.1f, %.1f)", position.X, position.Y)
				)
			end
			return
		end
		if primary then
			self:_handlePrimary(input)
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			self.renderer:setSelected(nil)
		end
	end)
end

function Controller.destroy(self: Controller)
	if self.connection ~= nil then
		self.connection:Disconnect()
		self.connection = nil
	end
	self.MoveRequested:Destroy()
end

return Controller
