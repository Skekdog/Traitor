
export type ConnectionId = number

export type Callback<T...> = (T...) -> ()

export type Connection<T...> = {
	_callbacks: {[number]: Callback<T...>},

	Connect: (Connection<T...>, callback: Callback<T...>) -> ConnectionId,
	Disconnect: (Connection<T...>, ConnectionId) -> (),
	Wait: (Connection<T...>) -> T...,

	Invoke: (Connection<T...>, T...) -> (),
}

local module = {}

local function Connect<T...>(connection: Connection<T...>, callback: (T...) -> ()): ConnectionId
	local index = #connection._callbacks + 1
	connection._callbacks[index] = callback

	return index
end

local function Wait<T...>(connection: Connection<T...>): T...
	local values = nil
	connection:Connect(function(...: any)
		values = {...}
	end)

	while values == nil do
		task.wait()
	end

	return table.unpack(values)
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
		Wait = Wait,

		Invoke = Invoke,
	}
end

return module