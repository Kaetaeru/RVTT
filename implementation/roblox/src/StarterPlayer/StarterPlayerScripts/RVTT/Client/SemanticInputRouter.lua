--!strict

local ContextActionService = game:GetService("ContextActionService")

type StackLike = {
	dispatch: (self: StackLike, action: string, payload: any) -> boolean,
}

type RouterInstance = {
	stack: StackLike,
	started: boolean,
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

function Router.new(stack: StackLike): RouterInstance
	return setmetatable({ stack = stack, started = false }, Router) :: any
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
				and self.stack:dispatch(action, { input = input })
			then
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end, false, table.unpack(keys))
	end
end

function Router.destroy(self: RouterInstance)
	if not self.started then
		return
	end
	self.started = false
	for action in bindings do
		ContextActionService:UnbindAction("RVTT_" .. action)
	end
end

return Router
