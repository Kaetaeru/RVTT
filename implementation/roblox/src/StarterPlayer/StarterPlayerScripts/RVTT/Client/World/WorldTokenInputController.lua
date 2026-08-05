--!strict

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Signal = require(ReplicatedStorage.RVTT.Shared.Core.Signal)
local Contract = require(ReplicatedStorage.RVTT.Shared.World.WorldTokenContract)
local InteractionMath = require(ReplicatedStorage.RVTT.Shared.World.WorldInteractionMath)

type PendingMove = {
	actorId: string,
	destination: { x: number, y: number, z: number },
	baseRevision: number,
}

export type Controller = {
	renderer: any,
	replica: any,
	command: any,
	inputConnection: RBXScriptConnection?,
	receiptConnection: RBXScriptConnection?,
	pendingMoves: { [string]: PendingMove },
	PickResolved: any,
	MoveRequested: any,
	MoveResolved: any,
	_selectActor: (self: Controller, actorId: string, method: string, hitName: string) -> boolean,
	_moveSelected: (self: Controller, hit: RaycastResult) -> boolean,
	_handlePrimary: (self: Controller, input: InputObject) -> (),
	_handleReceipt: (self: Controller, message: any) -> (),
	start: (self: Controller) -> (),
	destroy: (self: Controller) -> (),
}

local Controller = {}
Controller.__index = Controller

local rvtt = ReplicatedStorage:WaitForChild("RVTT")
local acceptanceMode = rvtt:FindFirstChild("Slice01AcceptanceMode")
local DEBUG_INTERACTIONS = acceptanceMode ~= nil
	and acceptanceMode:IsA("BoolValue")
	and acceptanceMode.Value

local function diagnostic(event: string, fields: string)
	if DEBUG_INTERACTIONS then
		print(string.format("[RVTT WorldToken Input] event=%s %s", event, fields))
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

local function viewportPosition(screen: Vector2): Vector2
	local topLeftInset = GuiService:GetGuiInset()
	return InteractionMath.screenToViewport(screen, topLeftInset)
end

local function raycastFromViewport(position: Vector2): RaycastResult?
	local camera = Workspace.CurrentCamera
	if camera == nil then
		return nil
	end
	local ray = camera:ViewportPointToRay(position.X, position.Y)
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

local function instanceName(instance: Instance?): string
	return if instance ~= nil then instance:GetFullName() else "none"
end

local function terminalRevision(result: any): number?
	if type(result) ~= "table" or type(result.value) ~= "table" then
		return nil
	end
	return if type(result.value.revision) == "number" then result.value.revision else nil
end

local function terminalCode(result: any): string?
	if type(result) ~= "table" or type(result.error) ~= "table" then
		return nil
	end
	return if type(result.error.code) == "string" then result.error.code else nil
end

function Controller.new(renderer: any, replica: any, command: any): Controller
	return setmetatable({
		renderer = renderer,
		replica = replica,
		command = command,
		inputConnection = nil,
		receiptConnection = nil,
		pendingMoves = {},
		PickResolved = Signal.new(),
		MoveRequested = Signal.new(),
		MoveResolved = Signal.new(),
	}, Controller) :: any
end

function Controller:_selectActor(actorId: string, method: string, hitName: string): boolean
	local actor = Contract.actor(self.replica.payload, actorId)
	if not Contract.canControl(self.replica.payload, actor, Players.LocalPlayer.UserId) then
		diagnostic(
			"pick",
			string.format(
				"result=denied method=%s actor=%s hit=%s",
				method,
				actorId,
				hitName
			)
		)
		self.PickResolved:Fire(actorId, method, false, hitName)
		return false
	end
	local selected = self.renderer:setSelected(actorId)
	diagnostic(
		"pick",
		string.format(
			"result=%s method=%s actor=%s hit=%s",
			if selected then "selected" else "missing",
			method,
			actorId,
			hitName
		)
	)
	self.PickResolved:Fire(actorId, method, selected, hitName)
	if selected then
		print(string.format("[RVTT WorldToken] event=selected actor=%s method=%s", actorId, method))
	end
	return selected
end

function Controller:_moveSelected(hit: RaycastResult): boolean
	local actorId = self.renderer:getSelectedActorId()
	if actorId == nil or not Contract.isMoveSurface(hit.Instance) then
		return false
	end
	local actor = Contract.actor(self.replica.payload, actorId)
	if not Contract.canControl(self.replica.payload, actor, Players.LocalPlayer.UserId) then
		self.renderer:setSelected(nil)
		diagnostic("move", "result=denied actor=" .. actorId)
		return false
	end
	local destinationVector = hit.Position
	local destination = Contract.toDestination(destinationVector)
	local baseRevision = self.replica.revision
	local commandId = self.command:submit("movement.commit", {
		actorId = actorId,
		destination = destination,
	})
	self.pendingMoves[commandId] = {
		actorId = actorId,
		destination = destination,
		baseRevision = baseRevision,
	}
	self.renderer:showDestination(actorId, destinationVector, commandId)
	self.MoveRequested:Fire(actorId, destination, commandId, baseRevision)
	print(
		string.format(
			"[RVTT WorldToken Command] event=submitted commandId=%s actor=%s baseRevision=%d destination=(%.2f,%.2f,%.2f)",
			commandId,
			actorId,
			baseRevision,
			destination.x,
			destination.y,
			destination.z
		)
	)
	return true
end

function Controller:_handlePrimary(input: InputObject)
	local screen = screenPosition(input)
	local viewport = viewportPosition(screen)
	local camera = Workspace.CurrentCamera
	local hit = raycastFromViewport(viewport)
	local rayActorId = if hit ~= nil then self.renderer:actorIdFromInstance(hit.Instance) else nil
	local screenActorId = if camera ~= nil
		then self.renderer:actorIdFromViewportPoint(camera, viewport, nil)
		else nil
	local actorId, method = InteractionMath.resolvePick(rayActorId, screenActorId)
	local hitName = instanceName(if hit ~= nil then hit.Instance else nil)

	if actorId ~= nil then
		self:_selectActor(actorId, method, hitName)
		return
	end
	if hit ~= nil and self:_moveSelected(hit) then
		diagnostic(
			"move",
			string.format(
				"result=submitted screen=(%.1f,%.1f) viewport=(%.1f,%.1f) hit=%s",
				screen.X,
				screen.Y,
				viewport.X,
				viewport.Y,
				hitName
			)
		)
		return
	end
	diagnostic(
		"pick",
		string.format(
			"result=none screen=(%.1f,%.1f) viewport=(%.1f,%.1f) hit=%s tokens=%d",
			screen.X,
			screen.Y,
			viewport.X,
			viewport.Y,
			hitName,
			self.renderer:tokenCount()
		)
	)
end

function Controller:_handleReceipt(message: any)
	if
		type(message) ~= "table"
		or message.phase ~= "terminal"
		or type(message.commandId) ~= "string"
	then
		return
	end
	local commandId = message.commandId
	local pending = self.pendingMoves[commandId]
	if pending == nil then
		return
	end
	self.pendingMoves[commandId] = nil
	local result = message.result
	local ok = type(result) == "table" and result.ok == true
	local revision = terminalRevision(result)
	local code = terminalCode(result)
	self.renderer:resolveDestination(
		commandId,
		if ok then "accepted" else "rejected",
		revision,
		code
	)
	self.MoveResolved:Fire(
		pending.actorId,
		pending.destination,
		commandId,
		ok,
		code,
		revision,
		pending.baseRevision
	)
	print(
		string.format(
			"[RVTT WorldToken Command] event=terminal commandId=%s actor=%s ok=%s code=%s revision=%s baseRevision=%d",
			commandId,
			pending.actorId,
			tostring(ok),
			tostring(code),
			tostring(revision),
			pending.baseRevision
		)
	)
end

function Controller.start(self: Controller)
	if self.inputConnection ~= nil then
		return
	end
	self.receiptConnection = self.command.remotes.receipt.OnClientEvent:Connect(function(message)
		self:_handleReceipt(message)
	end)
	self.inputConnection = UserInputService.InputBegan:Connect(function(input, processed)
		local primary = input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		if processed then
			if primary then
				local screen = screenPosition(input)
				diagnostic(
					"ignored",
					string.format(
						"reason=processed screen=(%.1f,%.1f)",
						screen.X,
						screen.Y
					)
				)
			end
			return
		end
		if primary then
			self:_handlePrimary(input)
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			self.renderer:setSelected(nil)
			diagnostic("selection", "result=cleared method=secondary")
		end
	end)
end

function Controller.destroy(self: Controller)
	if self.inputConnection ~= nil then
		self.inputConnection:Disconnect()
		self.inputConnection = nil
	end
	if self.receiptConnection ~= nil then
		self.receiptConnection:Disconnect()
		self.receiptConnection = nil
	end
	table.clear(self.pendingMoves)
	self.PickResolved:Destroy()
	self.MoveRequested:Destroy()
	self.MoveResolved:Destroy()
end

return Controller
