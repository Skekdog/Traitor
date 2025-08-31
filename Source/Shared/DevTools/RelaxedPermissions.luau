local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DynamicValue = require(ReplicatedStorage.Shared.Util.DynamicValue)
local PlaceIDs = require(ReplicatedStorage.Shared.Util.PlaceIDs)

local module = {}

module.TemporaryPermissions = DynamicValue.new({} :: {[number]: boolean})

function module.GivePermission(user: Player): ()
	print("gave", user)
	module.TemporaryPermissions()[user.UserId] = true
	module.TemporaryPermissions:Invoke()

	user.Destroying:Once(function()
		module.TemporaryPermissions()[user.UserId] = nil
		module.TemporaryPermissions:Invoke()
	end)
end

function module.HasRelaxedPermissions(user: number | Player): boolean
	if game.PlaceId ~= PlaceIDs.TestPlace then
		return false
	end

	local id = if typeof(user) == "number" then user else user.UserId
	return module.TemporaryPermissions()[id] or false
end

return module