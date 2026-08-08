--!strict

local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local GameplayInputGuard = require(script.Parent.GameplayInputGuard)

type StackLike = {
	dispatch: (self: StackLike, action: string, payload: any) -> boolean,
}

type RouterInstance = {
	stack: StackLike,
	started: boolean,
	connections: { RBXScriptConnection },
	start: (self: RouterInstance) -> (),
	destroy: (self: RouterInstance) -> (),
}

local Router = {}
Router.__index = Router

local bindings: { [string]: { Enum.KeyCode } } = {
	Cancel = { Enum.KeyCode.Q },
	Confirm = { Enum.KeyCode.E },
	PrimaryAction1 = { Enum.KeyCode.One },
	PrimaryAction2 = { Enum.KeyCode.Two },
	PrimaryAction3 = { Enum.KeyCode.Three },
	PrimaryAction4 = { Enum.KeyCode.Four },
	PrimaryAction5 = { Enum.KeyCode.Five },
}

local pointerBindings: { [Enum.UserInputType]: string } = {
	[Enum.UserInputType.MouseButton1] = "PrimaryPointer",
	[Enum.UserInputType.MouseButton2] = "ContextActionPointer",
	[Enum.UserInputType.MouseButton3] = "CameraOrbitPointer",
}

function Router.new(stack: StackLike): RouterInstance
	return setmetatable({ stack = stack, started = false, connections = {} }, Router) :: any
end

function Router.semanticActionFor(inputType: Enum.UserInputType, keyCode: Enum.KeyCode): string?
	local pointerAction = pointerBindings[inputType]
	if pointerAction ~= nil then
		return pointerAction
	end
	for action, keys in bindings do
		for _, candidate in keys do
			if candidate == keyCode then
				return action
			end
		end
	end
	return nil
end

function Router.start(self: RouterInstance)
	if self.started then
		return
	end
	self.started = true
	for action, keys in bindings do
		ContextActionService:BindAction("RVTT_" .. action, function(_, state, input)
			if
				state == Enum.UserInputState.Begin
				and GameplayInputGuard.allows(false, UserInputService:GetFocusedTextBox())
				and self.stack:dispatch(action, { input = input })
			then
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end, false, table.unpack(keys))
	end
	table.insert(
		self.connections,
		UserInputService.InputBegan:Connect(function(input, processed)
			if not GameplayInputGuard.allows(processed, UserInputService:GetFocusedTextBox()) then
				return
			end
			local action = Router.semanticActionFor(input.UserInputType, input.KeyCode)
			if action ~= nil and pointerBindings[input.UserInputType] ~= nil then
				self.stack:dispatch(action, { input = input })
			end
		end)
	)
end

function Router.destroy(self: RouterInstance)
	if not self.started then
		return
	end
	self.started = false
	for action in bindings do
		ContextActionService:UnbindAction("RVTT_" .. action)
	end
	for _, connection in self.connections do
		connection:Disconnect()
	end
	self.connections = {}
end

return Router
