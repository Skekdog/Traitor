
type ConnectionId = nil
export type Callback<T> = (T) -> ()

export type Connection<T> = {
	_dynamicValue: DynamicValue<T>,
	_connectionId: ConnectionId,

	IsConnected: boolean,
	Disconnect: (Connection<T>) -> (),
}

export type DynamicValue<T> = typeof(setmetatable({} :: {
	_value: T,
	GetValue: (DynamicValue<T>) -> T,
	SetValue: (DynamicValue<T>, value: T) -> (),

	_connections: {[ConnectionId]: Callback<T>},
	Connect: (DynamicValue<T>, callback: Callback<T>, runImmediately: boolean?) -> Connection<T>,
	Once: (DynamicValue<T>, callback: Callback<T>) -> Connection<T>,
	Wait: (DynamicValue<T>) -> T,

	Invoke: (DynamicValue<T>) -> (),
	[any]: nil,
}, {} :: {
	__call: (self: DynamicValue<T>) -> T
}))

local function Disconnect<T>(self: Connection<T>): ()
	self.IsConnected = false
	self._dynamicValue._connections[self._connectionId] = nil
end

local function runCallback<T>(callback: Callback<T>, value: T): ()
	task.spawn(callback, value)
end

local function Connect<T>(self: DynamicValue<T>, callback: Callback<T>, runImmediately: boolean?): Connection<T>
	local key: ConnectionId = newproxy()
	self._connections[key] = callback

	if runImmediately then
		task.defer(runCallback, callback, self._value)
	end

	return {
		_dynamicValue = self,
		_connectionId = key,

		IsConnected = true,
		Disconnect = Disconnect,
	}
end

local function Once<T>(self: DynamicValue<T>, callback: Callback<T>): Connection<T>
	local connection
	connection = self:Connect(function(value)
		connection:Disconnect()
		callback(value)
	end)
	return connection
end

local function Wait<T>(self: DynamicValue<T>): T
	local value: T
	local didSet = false

	-- note: we need didSet, because checking for value == nil will not work if value is set to nil

	local connection = self:Connect(function(newValue: T)
		value = newValue
		didSet = true
	end)

	while not didSet do
		task.wait()
	end

	connection:Disconnect()

	return value
end

local function GetValue<T>(self: DynamicValue<T>): T
	return self._value
end

local function SetValue<T>(self: DynamicValue<T>, value: T): ()
	self._value = value
	self:Invoke()
end

local function Invoke<T>(self: DynamicValue<T>): ()
	for _, callback in self._connections do
		runCallback(callback, self._value)
	end
end

local module = {}

function module.new<T>(initialValue: T): DynamicValue<T>
	return setmetatable({
		_value = initialValue,
		GetValue = GetValue,
		SetValue = SetValue,

		_connections = {},
		Connect = Connect,
		Once = Once,
		Wait = Wait,

		Invoke = Invoke,
	}, {
		__call = function(self: DynamicValue<T>): T
			return self:GetValue()
		end
	})
end

return table.freeze(module)