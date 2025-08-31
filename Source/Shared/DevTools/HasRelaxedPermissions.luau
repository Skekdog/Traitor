local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaceIDs = require(ReplicatedStorage.Shared.Util.PlaceIDs)

local function HasRelaxedPermissions(user: number | Player): boolean
	if game.PlaceId ~= PlaceIDs.TestPlace then
		return false
	end

	local id = if typeof(user) == "number" then user else user.UserId
	return id == workspace:GetAttribute("FirstJoiner")
end

return HasRelaxedPermissions