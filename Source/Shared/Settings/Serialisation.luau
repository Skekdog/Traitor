local HttpService = game:GetService("HttpService")
local module = {}

function module.SerialiseValue(value: any): string
	assert(typeof(value) ~= "table", "Value must not be a table")
	assert(typeof(value) ~= "nil", "Value must not be nil")

	if typeof(value) == "string" then
		return `"{value}"`
	elseif typeof(value) == "number" then
		return tostring(value)
	elseif typeof(value) == "boolean" then
		return if value then "true" else "false"
	elseif typeof(value) == "UDim2" then
		return `[{value.X.Scale},{value.X.Offset},{value.Y.Scale},{value.Y.Offset}]`
	elseif typeof(value) == "EnumItem" then
		return `"{tostring(value)}"`
	end

	error("Unable to serialise value of type: " .. typeof(value))
end

function module.SerialiseTable(tbl: {[string]: any}): string
	local serialised = "{"
	for i, v in tbl do
		local toAppend: string
		if typeof(v) == "table" then
			toAppend = module.SerialiseTable(v)
		else
			toAppend = module.SerialiseValue(v)
		end

		local isLast = not next(tbl, i)
		serialised ..= `"{i}":{toAppend}{if isLast then "" else ","}`
	end

	serialised ..= "}"

	return serialised
end

local function deserialiseSomeStringValue(value: string): string | EnumItem
	local split = value:split(".")
	if #split == 3 then
		assert(split[1] == "Enum", "Invalid enum value")
		local enumCategory = assert(Enum[split[2]], "Invalid enum category")
		local enumItem = assert(enumCategory[split[3]], "Invalid enum item")
		return enumItem
	end

	return value
end

local function deserialiseSomeTableValue(value: {[string | number]: any}): {[string]: any} | UDim2
	if #value == 4 then
		return UDim2.new(value[1], value[2], value[3], value[4])
	end
	
	local decoded: {[string]: any} = {}
	for i, v in value do
		assert(typeof(i) == "string", "Table key must be a string")
		decoded[i] = module.DeserialiseJSONValue(v)
	end

	return decoded
end

function module.DeserialiseJSONValue(value: any): any
	if typeof(value) == "string" then
		return deserialiseSomeStringValue(value)
	elseif typeof(value) == "table" then
		return deserialiseSomeTableValue(value)
	elseif typeof(value) == "number" then
		return value
	elseif typeof(value) == "boolean" then
		return value
	end

	error("Unable to deserialise value of type: " .. typeof(value))
end

function module.DeserialiseJSON(json: string): {[string]: any}
	local fromHttpService = HttpService:JSONDecode(json)
	local decoded = module.DeserialiseJSONValue(fromHttpService)
	return decoded
end

return table.freeze(module)