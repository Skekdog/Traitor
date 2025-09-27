local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local IsLabs = require(ReplicatedStorage.Shared.Places.IsLabs)

if not IsLabs then
	return nil
end

if RunService:IsStudio() or (game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0) then
	workspace:SetAttribute("LabsGreenLight", true)
	return nil
end

while true do
	for _, player in Players:GetPlayers() do
		player:Kick("Create a free private server to join Labs.")
	end
	task.wait()
end