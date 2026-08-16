--!strict

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Signal = require(ReplicatedStorage.RVTT.Shared.Core.Signal)
local GameplayInputGuard = require(script.Parent.Parent.GameplayInputGuard)

local Controller = {}
Controller.__index = Controller

local RAY_DISTANCE = 2048
local INPUT_CONTEXT_ID = "world_direct_play"
local INPUT_CONTEXT_PRIORITY = 20

type Action = {
	id: string,
	label: string,
	kind: string,
	commandType: string,
	payload: { [string]: any },
	isDefault: boolean,
	enabled: boolean,
	disabledReason: string?,
	category: string,
	sortOrder: number,
	projectionRevision: number,
}

type Target = {
	kind: string,
	actorId: string?,
	objectId: string?,
	position: Vector3?,
	instance: Instance?,
}

local function attributeInAncestors(instance: Instance?, name: string): any
	local current = instance
	while current ~= nil do
		local value = current:GetAttribute(name)
		if value ~= nil then
			return value
		end
		current = current.Parent
	end
	return nil
end

local function terminalResult(message: any): (string?, any?)
	if type(message) ~= "table" or message.phase ~= "terminal" then
		return nil, nil
	end
	if type(message.commandId) ~= "string" then
		return nil, nil
	end
	return message.commandId, message.result
end

function Controller.new(
	renderer: any,
	replica: any,
	command: any,
	resolver: any,
	menu: any,
	inputStack: any
): any
	return setmetatable({
		renderer = renderer,
		replica = replica,
		command = command,
		resolver = resolver,
		menu = menu,
		inputStack = inputStack,
		connections = {},
		pending = {},
		started = false,
		PickResolved = Signal.new(),
		MoveRequested = Signal.new(),
		MoveResolved = Signal.new(),
		ContextActionRequested = Signal.new(),
		ContextActionResolved = Signal.new(),
		ActionMenuChanged = Signal.new(),
		PreviewChanged = Signal.new(),
		currentPreview = nil,
	}, Controller)
end

function Controller:_setPreview(preview: any?)
	self.currentPreview = preview
	self.PreviewChanged:Fire(preview)
end

function Controller:getCurrentPreview(): any?
	return self.currentPreview
end

function Controller:invalidateTransientState()
	table.clear(self.pending)
	self.menu:close("projection-rebuild")
	self.renderer:clearDestination(nil)
	self:_setPreview(nil)
end

function Controller:ensureSemanticSelection(): string?
	local selectedActorId = self.renderer:getSelectedActorId()
	if selectedActorId ~= nil and self.resolver:isControllable(selectedActorId) then
		return selectedActorId
	end
	local fallbackActorId = self.resolver:defaultControllableActorId()
	if fallbackActorId ~= nil then
		self.renderer:setSelected(fallbackActorId)
	elseif selectedActorId ~= nil then
		self.renderer:setSelected(nil)
	end
	return fallbackActorId
end

function Controller:_pointerPosition(): Vector2
	local pointer = UserInputService:GetMouseLocation()
	local inset = GuiService:GetGuiInset()
	return pointer - inset
end

function Controller:_raycastTarget(): Target
	local camera = Workspace.CurrentCamera
	if camera == nil then
		return { kind = "none" }
	end
	local pointer = self:_pointerPosition()
	local ray = camera:ViewportPointToRay(pointer.X, pointer.Y)
	local result = Workspace:Raycast(ray.Origin, ray.Direction * RAY_DISTANCE)
	if result ~= nil then
		local actorId = self.renderer:actorIdFromInstance(result.Instance)
		if actorId ~= nil then
			return {
				kind = "actor",
				actorId = actorId,
				position = result.Position,
				instance = result.Instance,
			}
		end
		local objectId = attributeInAncestors(result.Instance, "RVTTObjectId")
		if type(objectId) == "string" then
			return {
				kind = "object",
				objectId = objectId,
				position = result.Position,
				instance = result.Instance,
			}
		end
		if attributeInAncestors(result.Instance, "RVTTMoveSurface") == true then
			return {
				kind = "surface",
				position = result.Position,
				instance = result.Instance,
			}
		end
	end

	local fallbackActorId = self.renderer:actorIdFromViewportPoint(camera, pointer, nil)
	if fallbackActorId ~= nil then
		return { kind = "actor", actorId = fallbackActorId }
	end
	return { kind = "none" }
end

function Controller:resolveActionsForTarget(target: Target): { Action }
	local selectedActorId = self.renderer:getSelectedActorId()
	if selectedActorId == nil then
		return {}
	end
	return self.resolver:resolve(selectedActorId, target)
end

function Controller:_targetLabel(target: Target): string
	if target.actorId ~= nil then
		return target.actorId
	end
	if target.objectId ~= nil then
		return target.objectId
	end
	if target.kind == "surface" then
		return "바닥"
	end
	return ""
end

function Controller:openActionsForTarget(target: Target, screenPosition: Vector2?): { Action }
	local actions = self:resolveActionsForTarget(target)
	self.menu:open(
		actions,
		screenPosition or UserInputService:GetMouseLocation(),
		self:_targetLabel(target)
	)
	self.ActionMenuChanged:Fire(self.menu:isOpen(), actions, target)
	return actions
end

function Controller:_executeAction(action: Action): string?
	if action.enabled == false or action.projectionRevision ~= self.replica.revision then
		return nil
	end
	local selectedActorId = self.renderer:getSelectedActorId()
	if selectedActorId == nil then
		return nil
	end
	local baseRevision = self.replica.revision
	local commandId = self.command:submit(action.commandType, action.payload)
	self.pending[commandId] = {
		action = action,
		baseRevision = baseRevision,
	}
	if action.kind == "move" then
		local destination = action.payload.destination
		local position = Vector3.new(destination.x, destination.y, destination.z)
		self.renderer:showDestination(selectedActorId, position, commandId)
		self.MoveRequested:Fire(selectedActorId, destination, commandId, baseRevision)
	end
	self.ContextActionRequested:Fire(action, commandId, baseRevision)
	self:_setPreview(nil)
	return commandId
end

function Controller:executeAction(action: Action): string?
	return self:_executeAction(action)
end

function Controller:_onReceipt(message: any)
	local commandId, result = terminalResult(message)
	if commandId == nil then
		return
	end
	local pending = self.pending[commandId]
	if pending == nil then
		return
	end
	self.pending[commandId] = nil
	local action = pending.action
	local ok = type(result) == "table" and result.ok == true
	local code = if type(result) == "table" and type(result.error) == "table"
		then result.error.code
		else nil
	local revision = if type(result) == "table" and type(result.value) == "table"
		then result.value.revision
		else nil
	if action.kind == "move" then
		self.renderer:resolveDestination(
			commandId,
			if ok then "accepted" else "rejected",
			revision,
			code
		)
		self.MoveResolved:Fire(
			action.payload.actorId,
			action.payload.destination,
			commandId,
			ok,
			code,
			revision,
			pending.baseRevision
		)
	end
	self.ContextActionResolved:Fire(action, commandId, ok, code, revision, result)
end

function Controller:_pick(actorId: string, method: string, instance: Instance?): boolean
	local selected = self.renderer:setSelected(actorId)
	self.PickResolved:Fire(
		actorId,
		method,
		selected,
		if instance ~= nil then instance:GetFullName() else "screen"
	)
	return selected
end

function Controller:_leftClick()
	if self.menu:isOpen() then
		-- The open action table owns PrimaryPointer until Q closes it.
		return
	end
	local target = self:_raycastTarget()
	local selectedActorId = self.renderer:getSelectedActorId()
	if selectedActorId == nil then
		if target.actorId ~= nil and self.resolver:isControllable(target.actorId) then
			self:_pick(target.actorId, "ray", target.instance)
		end
		return
	end
	if
		target.actorId ~= nil
		and target.actorId ~= selectedActorId
		and self.resolver:isControllable(target.actorId)
	then
		self:_pick(target.actorId, "ray", target.instance)
		return
	end

	local actions = self:resolveActionsForTarget(target)
	local defaultAction = self.resolver:defaultAction(actions)
	if defaultAction ~= nil and defaultAction.enabled then
		self:_executeAction(defaultAction)
	end
end

function Controller:refreshPreview()
	if self.menu:isOpen() then
		self:_setPreview(nil)
		return
	end
	local selectedActorId = self.renderer:getSelectedActorId()
	if selectedActorId == nil or not self.resolver:isControllable(selectedActorId) then
		self:_setPreview(nil)
		return
	end
	local target = self:_raycastTarget()
	local actions = self:resolveActionsForTarget(target)
	local action = self.resolver:previewAction(actions)
	if action == nil then
		self:_setPreview(nil)
		return
	end
	self:_setPreview({
		actorId = selectedActorId,
		target = target,
		action = action,
		projectionRevision = self.replica.revision,
	})
end

function Controller:_rightClick()
	if self.renderer:getSelectedActorId() == nil then
		local target = self:_raycastTarget()
		if target.actorId ~= nil and self.resolver:isControllable(target.actorId) then
			self:_pick(target.actorId, "ray", target.instance)
		end
		return
	end
	self:_setPreview(nil)
	self:openActionsForTarget(self:_raycastTarget(), UserInputService:GetMouseLocation())
end

function Controller:_cancel(): boolean
	if self.menu:isOpen() then
		self.menu:close("context-cancel")
		return true
	end
	if self.renderer:getSelectedActorId() ~= nil then
		local fallbackActorId = self.resolver:defaultControllableActorId()
		if self.renderer:getSelectedActorId() ~= fallbackActorId then
			self.renderer:setSelected(fallbackActorId)
			return true
		end
	end
	return false
end

function Controller:handleSemantic(action: string, _: any): boolean
	if not GameplayInputGuard.allows(false, UserInputService:GetFocusedTextBox()) then
		return false
	end
	if action == "PrimaryPointer" then
		if self.menu:isOpen() then
			return true
		end
		self:_leftClick()
		return true
	elseif action == "ContextActionPointer" then
		self:_rightClick()
		return true
	elseif action == "Cancel" then
		return self:_cancel()
	elseif action == "Confirm" then
		-- Phase 6 targeting/preview contexts register their own higher-priority Confirm.
		return false
	elseif action == "CameraOrbitPointer" then
		-- WorldCameraController owns the drag while this context leaves it unconsumed.
		return false
	end
	return false
end

function Controller:start()
	if self.started then
		return
	end
	self.started = true
	self:ensureSemanticSelection()
	self.inputStack:push(INPUT_CONTEXT_ID, INPUT_CONTEXT_PRIORITY, {
		PrimaryPointer = function(payload)
			return self:handleSemantic("PrimaryPointer", payload)
		end,
		ContextActionPointer = function(payload)
			return self:handleSemantic("ContextActionPointer", payload)
		end,
		CameraOrbitPointer = function(payload)
			return self:handleSemantic("CameraOrbitPointer", payload)
		end,
		Cancel = function(payload)
			return self:handleSemantic("Cancel", payload)
		end,
		Confirm = function(payload)
			return self:handleSemantic("Confirm", payload)
		end,
	})
	table.insert(
		self.connections,
		UserInputService.InputChanged:Connect(function(input, processed)
			if
				input.UserInputType == Enum.UserInputType.MouseMovement
				and GameplayInputGuard.allows(processed, UserInputService:GetFocusedTextBox())
			then
				self:refreshPreview()
			end
		end)
	)
	table.insert(
		self.connections,
		self.command.remotes.receipt.OnClientEvent:Connect(function(message)
			self:_onReceipt(message)
		end)
	)
	table.insert(
		self.connections,
		self.menu.ActionInvoked:Connect(function(action)
			self:_executeAction(action)
		end)
	)
	table.insert(
		self.connections,
		self.menu.Opened:Connect(function(actions)
			self.ActionMenuChanged:Fire(true, actions, nil)
		end)
	)
	table.insert(
		self.connections,
		self.menu.Closed:Connect(function(reason)
			self.ActionMenuChanged:Fire(false, {}, reason)
		end)
	)
end

function Controller:destroy()
	if not self.started then
		return
	end
	self.started = false
	self.inputStack:remove(INPUT_CONTEXT_ID)
	for _, connection in self.connections do
		connection:Disconnect()
	end
	self.connections = {}
	self.pending = {}
	self.currentPreview = nil
	self.PickResolved:Destroy()
	self.MoveRequested:Destroy()
	self.MoveResolved:Destroy()
	self.ContextActionRequested:Destroy()
	self.ContextActionResolved:Destroy()
	self.ActionMenuChanged:Destroy()
	self.PreviewChanged:Destroy()
end

return Controller
