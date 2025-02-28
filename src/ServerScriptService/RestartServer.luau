local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local SafeTeleport = require(ReplicatedStorage.SafeTeleport)
local ProfileManager = require(script.Parent.ProfileManager)

local options = Instance.new("TeleportOptions")
options.ShouldReserveServer = true

return function(timeDelay: number)
    if ServerStorage:GetAttribute("ServerLocked") then
        return
    end
    ServerStorage:SetAttribute("ServerLocked", true)
    ProfileManager.ReleaseAllProfiles()
    task.delay(timeDelay, SafeTeleport, game.PlaceId, Players:GetPlayers(), options)
end