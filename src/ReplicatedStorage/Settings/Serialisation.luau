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

return module