
local function GetFlag(flag: string): boolean
	local success, result = pcall(function()
		return UserSettings():IsUserFeatureEnabled(flag)
	end)

	return if success then result else false
end

return GetFlag