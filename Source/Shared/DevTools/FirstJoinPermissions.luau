local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local RelaxedPermissions = require(script.Parent.RelaxedPermissions)

if RunService:IsClient() then
	if workspace:GetAttribute("FirstJoiner") == Players.LocalPlayer.UserId then
		RelaxedPermissions.GivePermission(Players.LocalPlayer)
	elseif not workspace:GetAttribute("FirstJoiner") then
		RelaxedPermissions.GivePermission(Players.LocalPlayer)
	end
	return nil
end

local function set(player: Player): ()
	workspace:SetAttribute("FirstJoiner", player.UserId)
	RelaxedPermissions.GivePermission(player)
end

for _, player in Players:GetPlayers() do
	set(player)
	break
end

if not workspace:GetAttribute("FirstJoiner") then
	local con: RBXScriptConnection
	con = Players.PlayerAdded:Connect(function(player)
		con:Disconnect()
		set(player)
	end)
end

return nil