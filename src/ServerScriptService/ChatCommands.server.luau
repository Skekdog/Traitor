local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")

local Types = require(script.Parent.Parent.ReplicatedFirst.RoundHandler.Types)
local RoundHandler = require(script.Parent.Parent.ReplicatedFirst.RoundHandler.RoundHandler) :: Types.ServerRoundHandler

local meId = 965735486
local testPlace = 9648179685
Players.PlayerAdded:Connect(function(plr)
    plr.Chatted:Connect(function(msg, to)
        if to then
            return
        end

        msg = msg:lower()

        if msg == "!testplace" and game.PlaceId ~= testPlace then
            local targets = {plr}
			if plr.UserId == meId then
				targets = game:GetService("Players"):GetPlayers()
			end
			TeleportService:TeleportAsync(testPlace, targets)
        elseif msg == "!pause" and plr.UserId == meId then
            local id = ServerStorage:GetAttribute("RoundID")
            local round = RoundHandler.GetRound(id)
            if not round:IsRoundInProgress() then
                return
            end

            round:PauseRound()

            if not round.Paused then
                ReplicatedStorage.RoundHandler:SetAttribute("TimeMilestone", round.TimeMilestone)
            end
            ReplicatedStorage.RoundHandler:SetAttribute("IsPaused", round.Paused)
        elseif msg == "!restart" and plr.UserId == meId then
            pcall(function()
                ServerScriptService.PlayerSetup.ReleaseAllProfiles:Fire()
                task.wait(5)
            end)
            Players.PlayerAdded:Connect(function(plr)
                plr:Kick("This server is shutting down for an update.")
            end)
            TeleportService:TeleportPartyAsync(game.PlaceId, Players:GetPlayers())
        end
    end)
end)