local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TeleportService = game:GetService("TeleportService")
local IsAdmin = require(ServerScriptService.DevTools.IsAdmin)
local PlaceIDs = require(ServerScriptService.DevTools.PlaceIDs)
local Types = require(ReplicatedStorage.RoundRule.Types)
local RestartServer = require(script.Parent.RestartServer)
local RoundHandler = require(script.Parent.RoundHandler)

local function send(message: string): ()
    local round = RoundHandler.GetRound()
    round:SendMessage(Players:GetPlayers(), message, "Chat")
end

TeleportService.TeleportInitFailed:Connect(function(plr, result, errorMessage)
    if result == Enum.TeleportResult.Unauthorized then
        send("Teleport failed because at least 1 player is not authorised.")
    else
        send(`Teleport failed: {errorMessage}`)
    end
end)

local function toTestPlace(plr: Player)
    if game.PlaceId == PlaceIDs.TestPlace then
        return send("You are already in test place, silly.")
    end

    local targets = {plr}
    if IsAdmin(plr) then
        targets = Players:GetPlayers()
        send("Teleporting everyone to test place.")
    else
        send(`Teleporting {plr.Name} to test place.`)
    end

    TeleportService:TeleportAsync(PlaceIDs.TestPlace, targets)
end

local function pause(): Types.Round?
    local round = RoundHandler.GetRound()
    if round:GetRoundPhase() == "Intermission" or round:GetRoundPhase() == "Waiting" then
        return send("Cannot pause round during intermission or waiting phase.")
    end

    round:PauseRound(not round:GetIsRoundPaused())
    send(if round:GetIsRoundPaused() then "Round paused." else "Round unpaused.")

    return round
end

local endRoundParams: {any}?
local normalEndRound: (...any) -> ()

local function disabledEndRound(...: any): ()
    endRoundParams = {...}
end

local function toggleVictory(): ()
    local round = RoundHandler.GetRound()
    if not round:IsInProgress() then
        return send("Cannot toggle victory if round is not in progress.")
    end

    if round.EndRound ~= disabledEndRound then
        endRoundParams = nil
        normalEndRound = round.EndRound
        round.EndRound = disabledEndRound
        send("Victory disabled.")
    else
        round.EndRound = normalEndRound
        if endRoundParams then
            normalEndRound(table.unpack(endRoundParams))
        end
        send("Victory enabled.")
    end
end

local function openSettingsForPlayer(plr: Player): ()
    ReplicatedStorage.ServerClient.OpenSettings:FireClient(plr)
end

local function endRound(roleName: string?): ()
    if not roleName then
        return send("Missing Argument 2 (role name)")
    end

    local round = RoundHandler.GetRound()
    if not round:IsInProgress() then
        return send("Failed to end round as round is not in progress.")
    end

    local success, err = pcall(function()
        round:EndRound(round:GetRoleFromRoleName(roleName))
        if round.EndRound == disabledEndRound then
            toggleVictory()
        end
    end)

    if success then
        send("Round ended.")
    else
        send("Failed to end round: "..err)
    end
end

Players.PlayerAdded:Connect(function(plr: Player)
    plr.Chatted:Connect(function(msg, to)
        if to then
            return
        end

        local args = msg:split(" ")
        local cmd = args[1]:lower()

        if cmd == "!testplace" then
            toTestPlace(plr)
        elseif cmd == "!pause" and IsAdmin(plr) then
            pause()
        elseif cmd == "!restart" and IsAdmin(plr) then
            send("Server restarting...")
            RestartServer(5)
        elseif cmd == "!pausevictory" and IsAdmin(plr) then
            toggleVictory()
        elseif cmd == "!settings" then
            openSettingsForPlayer(plr)
        elseif cmd == "!endround" and IsAdmin(plr) then
            endRound(args[2])
        end
    end)
end)