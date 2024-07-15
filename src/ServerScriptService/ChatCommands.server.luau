local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Adapters = require(script.Parent.Adapters)
local GetRound = require(script.Parent.GetRound)
local Types = require(script.Parent.Parent.ReplicatedFirst.RoundHandler.Types)
local RestartServer = require(script.Parent.RestartServer)

-- This is separate from Initialise so that if anything goes badly wrong server restart is still possible.

local meId = 965735486
local testPlace = 9648179685

local function isAdmin(plr: Player)
	return plr.UserId == meId or plr.UserId < 0
end

TeleportService.TeleportInitFailed:Connect(function(plr, result, errorMessage)
    if result == Enum.TeleportResult.Unauthorized then
        Adapters.SendMessage("Teleport failed because at least 1 player is not authorised.", "error", "other", true)
    else
        Adapters.SendMessage(`Teleport failed: {errorMessage}`, "error", "other", true)
    end
end)

local oldVictory: ((any, any) -> ())?

local function pause(): Types.Round?
    local round = GetRound()
    if not round or not round:IsRoundInProgress() then
        return Adapters.SendMessage("Failed to pause as there is no round in progress.", "error", "other", true)
    end

    round:PauseRound()
    Adapters.SendMessage(if round.Paused then "Round paused." else "Round unpaused.", "info", "other", true)

    if not round.Paused then
        ReplicatedStorage.RoundHandler:SetAttribute("TimeMilestone", round.TimeMilestone)
        if oldVictory then
            round.Gamemode.OnDeath = oldVictory
            oldVictory = nil
        end
    end
    ReplicatedStorage.RoundHandler:SetAttribute("IsPaused", round.Paused)

    return round
end

Players.PlayerAdded:Connect(function(plr: Player)
    plr.Chatted:Connect(function(msg, to)
        if to then
            return
        end

        msg = msg:lower()

        if msg == "!testplace" then
            if game.PlaceId == testPlace then
                return Adapters.SendMessage("You are already in test place, silly.", "error", "other", true)
            end

            local targets = {plr}
			if isAdmin(plr) then
				targets = Players:GetPlayers()
                Adapters.SendMessage("Teleporting everyone to test place.", "info", "other", true)
            else
                Adapters.SendMessage(`Teleporting {plr.Name} to test place.`, "info", "other", true)
            end

            TeleportService:TeleportAsync(testPlace, targets)
        elseif msg == "!pause" and isAdmin(plr) then
            pause()
        elseif msg == "!restart" and plr.UserId == meId then
            Adapters.SendMessage("Server restarting...", "info", "update", true) -- type is update to be consistent with RoundHandler restarts
            RestartServer(5)
        elseif msg == "!pausevictory" and isAdmin(plr) then
            local round = GetRound()
            if round and round.Paused then
                if oldVictory then
                    pause()
                    return Adapters.SendMessage("Re-enabled victory.", "info", "other", true)
                end
                return Adapters.SendMessage("Round is already paused.", "error", "other", true)
            end

            pause()
            
            if not round then
                return
            end

            if round.Paused then
                oldVictory = round.Gamemode.OnDeath
                round.Gamemode.OnDeath = nil
            else
                round.Gamemode.OnDeath = oldVictory
                oldVictory = nil
            end
        elseif msg == "!settings" then
            ReplicatedStorage.ServerClient.OpenSettings:FireClient(plr)
        end
    end)
end)