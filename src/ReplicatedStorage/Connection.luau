
export type ConnectionId = number

export type Callback<T...> = (T...) -> ()

export type Connection<T...> = {
	_callbacks: {[number]: Callback<T...>},

	Connect: (Connection<T...>, callback: Callback<T...>) -> ConnectionId,
	Disconnect: (Connection<T...>, ConnectionId) -> (),

	Invoke: (Connection<T...>, T...) -> (),
}

local module = {}

local function Connect<T...>(connection: Connection<T...>, callback: (T...) -> ()): ConnectionId
	local index = #connection._callbacks + 1
	connection._callbacks[index] = callback

	return index
end

local function Disconnect<T...>(connection: Connection<T...>, index: ConnectionId): ()
	connection._callbacks[index] = nil
end

local function Invoke<T...>(connection: Connection<T...>, ...): ()
	for _, v in connection._callbacks do
		v(...)
	end
end

function module.new<T...>(...: T...): Connection<T...>
	return {
		_callbacks = {},

		Connect = Connect,
		Disconnect = Disconnect,
		Invoke = Invoke,
	}
end

return module