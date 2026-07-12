local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IsLabs = require(ReplicatedStorage.Shared.Places.IsLabs)
local RelaxedPermissions = require(script.Parent.RelaxedPermissions)

if not IsLabs then
	return nil
end

if RunService:IsClient() then
	if workspace:GetAttribute("ServerHost") == Players.LocalPlayer.UserId then
		RelaxedPermissions.GivePermission(Players.LocalPlayer)
	end
	return nil
end

local function trySet(player: Player): ()
	if game.PrivateServerOwnerId ~= player.UserId then
		return
	end

	workspace:SetAttribute("ServerHost", player.UserId)
	RelaxedPermissions.GivePermission(player)
end

for _, player in Players:GetPlayers() do
	trySet(player)
end

Players.PlayerAdded:Connect(trySet)

return nil