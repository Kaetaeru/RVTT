--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameplayHudViewModel = require(ReplicatedStorage.RVTT.Shared.UI.GameplayHudViewModel)
local WorldActionMenu = require(script.Parent.WorldActionMenu)
local WorldCameraController = require(script.Parent.WorldCameraController)
local WorldContextActionResolver = require(script.Parent.WorldContextActionResolver)
local WorldTokenRenderer = require(script.Parent.WorldTokenRenderer)
local WorldPreviewRenderer = require(script.Parent.WorldPreviewRenderer)
local WorldTokenInputController = require(script.Parent.WorldTokenInputController)

export type Runtime = {
	Replica: any,
	Command: any,
	Renderer: any,
	ActionResolver: any,
	ActionMenu: any,
	Input: any,
	Camera: any,
	PreviewRenderer: any,
	SelectionChanged: any,
	PickResolved: any,
	MoveRequested: any,
	MoveResolved: any,
	ContextActionRequested: any,
	ContextActionResolved: any,
	ActionMenuChanged: any,
	PreviewChanged: any,
	Reconciled: any,
	DestinationChanged: any,
	connection: any,
	cameraCompatibilityConnection: any,
	previewConnection: any,
	started: boolean,
	start: (self: Runtime) -> (),
	destroy: (self: Runtime) -> (),
}

local Runtime = {}
Runtime.__index = Runtime

local rvtt = ReplicatedStorage:WaitForChild("RVTT")
local acceptanceMode = rvtt:FindFirstChild("Slice01AcceptanceMode")
local ACCEPTANCE_MODE = acceptanceMode ~= nil
	and acceptanceMode:IsA("BoolValue")
	and acceptanceMode.Value

local function logProjection(summary: any)
	if not ACCEPTANCE_MODE then
		return
	end
	if summary.created == 0 and summary.updated == 0 and summary.removed == 0 then
		return
	end
	print(
		string.format(
			"[RVTT WorldToken Projection] event=reconcile revision=%s created=%d updated=%d removed=%d count=%d",
			tostring(summary.revision),
			summary.created,
			summary.updated,
			summary.removed,
			summary.count
		)
	)
end

function Runtime.new(replica: any, command: any, inputStack: any): Runtime
	local renderer = WorldTokenRenderer.new(nil, nil)
	local actionResolver = WorldContextActionResolver.new(replica)
	local actionMenu = WorldActionMenu.new()
	local input = WorldTokenInputController.new(
		renderer,
		replica,
		command,
		actionResolver,
		actionMenu,
		inputStack
	)
	local camera = WorldCameraController.new(renderer, ACCEPTANCE_MODE)
	local previewRenderer = WorldPreviewRenderer.new(renderer)
	local compatibilityConnection = nil
	if ACCEPTANCE_MODE then
		compatibilityConnection = camera.InputResolved:Connect(
			function(action, _source, applied, changed, processed)
				if action == "orbit" then
					camera.InputResolved:Fire(
						"pan",
						"mouse-middle-orbit",
						applied,
						changed,
						processed
					)
				end
			end
		)
	end
	return setmetatable({
		Replica = replica,
		Command = command,
		Renderer = renderer,
		ActionResolver = actionResolver,
		ActionMenu = actionMenu,
		Input = input,
		Camera = camera,
		PreviewRenderer = previewRenderer,
		SelectionChanged = renderer.SelectionChanged,
		PickResolved = input.PickResolved,
		MoveRequested = input.MoveRequested,
		MoveResolved = input.MoveResolved,
		ContextActionRequested = input.ContextActionRequested,
		ContextActionResolved = input.ContextActionResolved,
		ActionMenuChanged = input.ActionMenuChanged,
		PreviewChanged = input.PreviewChanged,
		Reconciled = renderer.Reconciled,
		DestinationChanged = renderer.DestinationChanged,
		connection = nil,
		cameraCompatibilityConnection = compatibilityConnection,
		previewConnection = nil,
		started = false,
	}, Runtime) :: any
end

function Runtime.start(self: Runtime)
	if self.started then
		return
	end
	self.started = true
	logProjection(self.Renderer:reconcile(self.Replica.payload, self.Replica.revision))
	self.Input:ensureSemanticSelection()
	self.previewConnection = self.Input.PreviewChanged:Connect(function(rawPreview)
		self.PreviewRenderer:render(
			GameplayHudViewModel.preview(
				self.Replica.payload,
				self.Renderer:getSelectedActorId(),
				rawPreview,
				self.Replica.revision
			)
		)
	end)
	self.connection = self.Replica.Changed:Connect(function(payload, envelope)
		local revision = if type(envelope) == "table"
				and type(envelope.revision) == "number"
			then envelope.revision
			else self.Replica.revision
		logProjection(self.Renderer:reconcile(payload, revision))
		self.Input:ensureSemanticSelection()
		self.Input:refreshPreview()
	end)
	self.Input:start()
	self.Camera:start()
end

function Runtime.destroy(self: Runtime)
	if not self.started then
		return
	end
	self.started = false
	if self.connection ~= nil then
		self.connection:Disconnect()
		self.connection = nil
	end
	if self.cameraCompatibilityConnection ~= nil then
		self.cameraCompatibilityConnection:Disconnect()
		self.cameraCompatibilityConnection = nil
	end
	if self.previewConnection ~= nil then
		self.previewConnection:Disconnect()
		self.previewConnection = nil
	end
	self.Camera:destroy()
	self.Input:destroy()
	self.ActionMenu:destroy()
	self.PreviewRenderer:destroy()
	self.Renderer:destroy()
end

return Runtime
