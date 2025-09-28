
local function IsNaN(value: unknown): boolean
	if typeof(value) ~= "number" then
		return false
	end
	return value ~= value
end

return IsNaN