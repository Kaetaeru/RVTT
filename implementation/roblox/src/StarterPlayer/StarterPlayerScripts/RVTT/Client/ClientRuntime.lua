--!strict

export type Disconnectable = { Disconnect: (self: Disconnectable) -> () }
export type ChangedSignal = {
    Connect: (self: ChangedSignal, callback: (payload: any, envelope: any) -> ()) -> Disconnectable,
}
export type ProjectionReplica = { Changed: ChangedSignal }
export type InputContextStack = {
    push: (self: InputContextStack, name: string, priority: number, handlers: { [string]: (...any) -> boolean }) -> (),
}
export type Runtime = { Replica: ProjectionReplica, Command: any, Input: InputContextStack }

local current: Runtime? = nil
local ready = Instance.new("BindableEvent")
local ClientRuntime = {}

function ClientRuntime.set(runtime: Runtime)
    assert(current == nil, "ClientRuntime has already been initialized")
    current = runtime
    ready:Fire(runtime)
end

function ClientRuntime.get(): Runtime?
    return current
end

function ClientRuntime.await(): Runtime
    if current ~= nil then return current end
    return ready.Event:Wait()
end

return ClientRuntime
