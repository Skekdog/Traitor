local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")
local ProfileManager = require(script.Parent.ProfileManager)

local options = Instance.new("TeleportOptions")
options.ShouldReserveServer = true

return function(timeDelay: number)
    if ServerStorage:GetAttribute("ServerLocked") then
        return
    end
    ServerStorage:SetAttribute("ServerLocked", true)
    ProfileManager.ReleaseAllProfiles()
    task.delay(timeDelay, TeleportService.TeleportAsync, TeleportService, game.PlaceId, Players:GetPlayers(), options)
end