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
	elseif not workspace:GetAttribute("ServerHost") and not IsLabs then
		RelaxedPermissions.GivePermission(Players.LocalPlayer)
	end
	return nil
end

local function getCurrentHost(): Player?
	local currentHostId = workspace:GetAttribute("ServerHost")
	if typeof(currentHostId) == "number" then
		return Players:GetPlayerByUserId(currentHostId)
	end
	return nil
end

local function trySet(player: Player): ()
	local currentHost = getCurrentHost()
	if currentHost then
		return
	end

	if IsLabs and game.PrivateServerOwnerId ~= player.UserId then
		return
	end

	workspace:SetAttribute("ServerHost", player.UserId)
	RelaxedPermissions.GivePermission(player)
end

Players.PlayerRemoving:Connect(function(player)
	if workspace:GetAttribute("ServerHost") ~= player.UserId then
		return
	end

	workspace:SetAttribute("ServerHost", nil)
	for _, other in Players:GetPlayers() do
		if other ~= player then
			trySet(other)
		end
	end
end)

for _, player in Players:GetPlayers() do
	trySet(player)
end

Players.PlayerAdded:Connect(trySet)

return nil