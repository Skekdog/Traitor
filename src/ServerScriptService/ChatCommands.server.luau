local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Adapters = require(script.Parent.Adapters)
local GetRound = require(script.Parent.GetRound)
local RestartServer = require(script.Parent.RestartServer)

-- This is separate from Initialise so that if anything goes badly wrong server restart is still possible.

local meId = 965735486
local testPlace = 9648179685

local function isAdmin(plr: Player)
	return plr.UserId == meId or plr.UserId < 0
end

TeleportService.TeleportInitFailed:Connect(function(plr, result, errorMessage)
    if result == Enum.TeleportResult.Unauthorized then
        Adapters.SendMessage("Teleport failed because at least 1 player is not authorised.", "error", "update", true)
    else
        Adapters.SendMessage(`Teleport failed: {errorMessage}`, "error", "update", true)
    end
end)

Players.PlayerAdded:Connect(function(plr: Player)
    plr.Chatted:Connect(function(msg, to)
        if to then
            return
        end

        msg = msg:lower()

        if msg == "!testplace" and game.PlaceId ~= testPlace then
            local targets = {plr}
			if isAdmin(plr) then
				targets = Players:GetPlayers()
                Adapters.SendMessage("Teleporting everyone to test place.", "info", "update", true)
            else
                Adapters.SendMessage(`Teleporting {plr} to test place.`, "info", "update", true)
            end

            TeleportService:TeleportAsync(testPlace, targets)
        elseif msg == "!pause" and isAdmin(plr) then
            local round = GetRound()
			if not round or not round:IsRoundInProgress() then
				return Adapters.SendMessage("Failed to pause as there is no round in progress.", "error", "update", true)
			end

            round:PauseRound()

            if not round.Paused then
                ReplicatedStorage.RoundHandler:SetAttribute("TimeMilestone", round.TimeMilestone)
            end
            ReplicatedStorage.RoundHandler:SetAttribute("IsPaused", round.Paused)
        elseif msg == "!restart" and plr.UserId == meId then
            Adapters.SendMessage("Server restarting...", "error", "update", true)
            RestartServer(5)
        end
    end)
end)