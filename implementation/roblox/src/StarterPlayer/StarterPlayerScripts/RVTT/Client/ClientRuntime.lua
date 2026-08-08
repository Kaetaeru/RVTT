--!strict

export type Disconnectable = { Disconnect: (self: Disconnectable) -> () }
export type ChangedSignal = {
	Connect: (self: ChangedSignal, callback: (...any) -> ()) -> Disconnectable,
}
export type ProjectionReplica = {
	epoch: string?,
	revision: number,
	sequence: number,
	payload: { [string]: unknown },
	Changed: ChangedSignal,
}
export type InputContextStack = {
	push: (
		self: InputContextStack,
		name: string,
		priority: number,
		handlers: { [string]: (...any) -> boolean }
	) -> (),
	remove: (self: InputContextStack, name: string) -> (),
}
export type Runtime = {
	Replica: ProjectionReplica,
	Command: any,
	Input: InputContextStack,
	WorldTokens: any,
	Preferences: any,
}

local current: Runtime? = nil
local ready = Instance.new("BindableEvent")
local ClientRuntime = {}

function ClientRuntime.set(runtime: Runtime)
	assert(current == nil, "ClientRuntime has already been initialized")
	current = runtime
	ready:Fire()
end

function ClientRuntime.get(): Runtime?
	return current
end

function ClientRuntime.await(): Runtime
	local existing = current
	if existing ~= nil then
		return existing
	end

	ready.Event:Wait()
	local runtime = current
	assert(runtime ~= nil, "ClientRuntime readiness event fired before initialization")
	return runtime
end

return ClientRuntime

