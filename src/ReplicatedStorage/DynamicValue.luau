
export type ConnectionId = never
export type Callback<T> = (T) -> ()

export type DynamicValue<T> = typeof(setmetatable({} :: {
	_value: T,
	GetValue: (DynamicValue<T>) -> T,
	SetValue: (DynamicValue<T>, value: T) -> (),

	_connections: {[ConnectionId]: Callback<T>},
	Connect: (DynamicValue<T>, callback: Callback<T>) -> ConnectionId,
	Disconnect: (DynamicValue<T>, connectionId: ConnectionId) -> (),
	Wait: (DynamicValue<T>) -> T,
}, {} :: {
	__call: (self: DynamicValue<T>) -> T
}))

local function Connect<T>(self: DynamicValue<T>, callback: Callback<T>): ConnectionId
	local key = newproxy()
	self._connections[key] = callback
	return key
end

local function Disconnect<T>(self: DynamicValue<T>, connectionId: ConnectionId): ()
	self._connections[connectionId] = nil
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

	self:Disconnect(connection)

	return value
end

local function GetValue<T>(self: DynamicValue<T>): T
	return self._value
end

local function SetValue<T>(self: DynamicValue<T>, value: T): ()
	self._value = value

	for _, callback in self._connections do
		callback(value)
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
		Disconnect = Disconnect,
		Wait = Wait,
	}, {
		__call = function(self: DynamicValue<T>): T
			return self:GetValue()
		end
	})
end

return module