--!strict

export type Connection = { Disconnect: (Connection) -> () }
export type Signal<T...> = {
	Connect: (Signal<T...>, (T...) -> ()) -> Connection,
	Fire: (Signal<T...>, T...) -> (),
	Destroy: (Signal<T...>) -> (),
}

local Signal = {}
Signal.__index = Signal

function Signal.new<T...>(): Signal<T...>
	local self = setmetatable({ _listeners = {} }, Signal)
	return self :: Signal<T...>
end

function Signal:Connect(callback)
	local listeners = self._listeners
	local token = {}
	listeners[token] = callback
	local connection = {}
	function connection:Disconnect()
		listeners[token] = nil
	end
	return connection
end

function Signal:Fire(...)
	for _, callback in self._listeners do
		task.spawn(callback, ...)
	end
end

function Signal:Destroy()
	table.clear(self._listeners)
end

return Signal
