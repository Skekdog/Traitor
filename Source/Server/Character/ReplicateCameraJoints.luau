local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetRemote = require(ReplicatedStorage.API.GetRemote)

local replicateRemote = GetRemote("CameraJoints", ReplicatedStorage.Remotes.ServerClient, true)

local rateLimits: {[Player]: number?} = {}

ReplicatedStorage.Remotes.ClientServer.RotateHead.OnServerEvent:Connect(function(player, angle: unknown)
	if (rateLimits[player] or 0) > os.clock() then
		return
	end

	rateLimits[player] = os.clock() + (1 / 20)

	if typeof(angle) ~= "number" or not math.isfinite(angle) then
		return
	end

	local character = player.Character
	if not character or character:HasTag("Ragdoll") then
		return
	end

	local clampedAngle = math.clamp(angle, -1.4, 1.4)
	replicateRemote:FireAllClients(character, clampedAngle)
end)

Players.PlayerRemoving:Connect(function(player)
	rateLimits[player] = nil
end)

return nil