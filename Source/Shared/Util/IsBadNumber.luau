
local function IsBadNumber(value: unknown): boolean
	if typeof(value) ~= "number" then
		return false
	end
	return value ~= value or math.abs(value) == math.huge
end

return IsBadNumber