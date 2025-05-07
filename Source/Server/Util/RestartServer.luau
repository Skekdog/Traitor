local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ProfileManager = require(ServerScriptService.PlayerData.ProfileManager)
local SafeTeleport = require(ReplicatedStorage.Shared.Util.SafeTeleport)

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