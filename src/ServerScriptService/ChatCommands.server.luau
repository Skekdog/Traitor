local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Adapters = require(script.Parent.Adapters)
local GetRound = require(script.Parent.GetRound)
local Types = require(ReplicatedFirst.RoundHandler.Types)
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

local oldVictory: ((Types.Gamemode, Types.Participant) -> ())?

local deaths: {Types.Participant} = {}

local function unPauseVictory(round: Types.Round): ()
    round.Gamemode.OnDeath = oldVictory
    oldVictory = nil

    if not round.Gamemode.OnDeath then
        return
    end
    
    for _, v in deaths do
        round.Gamemode.OnDeath(round.Gamemode, v)
    end
end

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
            unPauseVictory(round)
        end
    end
    ReplicatedStorage.RoundHandler:SetAttribute("IsPaused", round.Paused)

    return round
end

local function send(message: string): ()
    Adapters.SendMessage(message, "info", "other", true)
end

Players.PlayerAdded:Connect(function(plr: Player)
    plr.Chatted:Connect(function(msg, to)
        if to then
            return
        end

        local args = msg:split(" ")
        local cmd = args[1]:lower()

        if cmd == "!testplace" then
            if game.PlaceId == testPlace then
                return send("You are already in test place, silly.")
            end

            local targets = {plr}
			if isAdmin(plr) then
				targets = Players:GetPlayers()
                send("Teleporting everyone to test place.")
            else
                send(`Teleporting {plr.Name} to test place.`)
            end

            TeleportService:TeleportAsync(testPlace, targets)
        elseif cmd == "!pause" and isAdmin(plr) then
            pause()
        elseif cmd == "!restart" and plr.UserId == meId then
            Adapters.SendMessage("Server restarting...", "info", "update", true) -- type is update to be consistent with RoundHandler restarts
            RestartServer(5)
        elseif cmd == "!pausevictory" and isAdmin(plr) then
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

            deaths = {}
            if round.Paused then
                oldVictory = round.Gamemode.OnDeath
                round.Gamemode.OnDeath = function(self, participant)
                    table.insert(deaths, participant)
                end
            else
                unPauseVictory(round)
            end
        elseif cmd == "!settings" then
            ReplicatedStorage.ServerClient.OpenSettings:FireClient(plr)
        elseif cmd == "!endround" and isAdmin(plr) then
            if not args[2] then
                return send("Missing Argument 2")
            end
            local round = GetRound()
            if not round or not round:IsRoundInProgress() then
                return send("Failed to end round as there is no round in progress.")
            end

            local success, err = pcall(function()
                round:EndRound(round:GetParticipant(args[2]) or round:GetRoleFromName(args[2]))
            end)
            if success then
                send("Round ended.")
            else
                send("Failed to end round: "..err)
            end
        end
    end)
end)