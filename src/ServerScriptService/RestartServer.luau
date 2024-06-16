local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local TeleportService = game:GetService("TeleportService")

local options = Instance.new("TeleportOptions")
options.ShouldReserveServer = false
options.ServerInstanceId = ""

return function(timeDelay: number)
    ServerScriptService.PlayerSetup.ReleaseAllProfiles:Fire()
    task.delay(timeDelay, function()
        TeleportService:TeleportAsync(game.PlaceId, Players:GetPlayers(), options)
        Players.PlayerAdded:Connect(function(plr)
            plr:Kick("This server is shutting down for an update.")
        end)
    end)
end