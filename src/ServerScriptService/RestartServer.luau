local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")
local ProfileManager = require(script.Parent.ProfileManager)

local options = Instance.new("TeleportOptions")
options.ShouldReserveServer = false
options.ServerInstanceId = ""

return function(timeDelay: number)
    ServerStorage:SetAttribute("ServerLocked", true)
    ProfileManager.ReleaseAllProfiles()
    task.delay(timeDelay, function()
        TeleportService:TeleportAsync(game.PlaceId, Players:GetPlayers(), options)
        Players.PlayerAdded:Connect(function(plr)
            plr:Kick("This server is shutting down for an update.")
        end)
    end)
end