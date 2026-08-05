--!strict

export type Connection = { Disconnect: (Connection) -> () }
export type Signal<T...> = {
	Connect: (Signal<T...>, (T...) -> ()) -> Connection,
	Fire: (Signal<T...>, T...) -> (),
	Destroy: (Signal<T...>) -> (),
}

type SignalImpl<T...> = Signal<T...> & {
	_listeners: { [number]: (T...) -> () },
	_nextId: number,
}

local Signal = {}
Signal.__index = Signal

function Signal.new<T...>(): Signal<T...>
	local signal = setmetatable({
		_listeners = {},
		_nextId = 0,
	}, Signal) :: any
	return signal :: Signal<T...>
end

function Signal.Connect<T...>(signal: SignalImpl<T...>, callback: (T...) -> ()): Connection
	signal._nextId += 1
	local listenerId = signal._nextId
	signal._listeners[listenerId] = callback

	local connected = true
	local connection = {} :: any
	function connection:Disconnect()
		if not connected then
			return
		end
		connected = false
		signal._listeners[listenerId] = nil
	end
	return connection :: Connection
end

function Signal.Fire<T...>(signal: SignalImpl<T...>, ...: T...)
	for _, callback in signal._listeners do
		task.spawn(callback, ...)
	end
end

function Signal.Destroy<T...>(signal: SignalImpl<T...>)
	table.clear(signal._listeners)
end

return Signal
