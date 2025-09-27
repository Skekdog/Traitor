local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsLabs = require(ReplicatedStorage.Shared.Util.IsLabs)

if not IsLabs then
	return nil
end

if game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0 then
	workspace:SetAttribute("LabsGreenLight", true)
	return nil
end

while true do
	for _, player in Players:GetPlayers() do
		player:Kick("Create a free private server to join Labs.")
	end
	task.wait()
end