local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IsLabs = require(ReplicatedStorage.Shared.Places.IsLabs)
local IsTestPlace = require(ReplicatedStorage.Shared.Places.IsTestPlace)
local RelaxedPermissions = require(script.Parent.RelaxedPermissions)

if not IsLabs and not IsTestPlace then
	return nil
end

if RunService:IsClient() then
	if workspace:GetAttribute("ServerHost") == Players.LocalPlayer.UserId then
		RelaxedPermissions.GivePermission(Players.LocalPlayer)
	elseif not workspace:GetAttribute("ServerHost") then
		RelaxedPermissions.GivePermission(Players.LocalPlayer)
	end
	return nil
end

local function set(player: Player): ()
	workspace:SetAttribute("ServerHost", player.UserId)
	RelaxedPermissions.GivePermission(player)
end

for _, player in Players:GetPlayers() do
	set(player)
	break
end

if not workspace:GetAttribute("ServerHost") then
	local con: RBXScriptConnection
	con = Players.PlayerAdded:Connect(function(player)
		con:Disconnect()
		set(player)
	end)
end

return nil