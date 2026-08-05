--!strict

local WorldTokenRenderer = require(script.Parent.WorldTokenRenderer)
local WorldTokenInputController = require(script.Parent.WorldTokenInputController)

export type Runtime = {
	Replica: any,
	Command: any,
	Renderer: any,
	Input: any,
	SelectionChanged: any,
	MoveRequested: any,
	connection: any,
	started: boolean,
	start: (self: Runtime) -> (),
	destroy: (self: Runtime) -> (),
}

local Runtime = {}
Runtime.__index = Runtime

function Runtime.new(replica: any, command: any): Runtime
	local renderer = WorldTokenRenderer.new(nil, nil)
	local input = WorldTokenInputController.new(renderer, replica, command)
	return setmetatable({
		Replica = replica,
		Command = command,
		Renderer = renderer,
		Input = input,
		SelectionChanged = renderer.SelectionChanged,
		MoveRequested = input.MoveRequested,
		connection = nil,
		started = false,
	}, Runtime) :: any
end

function Runtime.start(self: Runtime)
	if self.started then
		return
	end
	self.started = true
	self.Renderer:reconcile(self.Replica.payload)
	self.connection = self.Replica.Changed:Connect(function(payload)
		self.Renderer:reconcile(payload)
	end)
	self.Input:start()
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
	self.Input:destroy()
	self.Renderer:destroy()
end

return Runtime
