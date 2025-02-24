local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local IsAdmin = require(ReplicatedStorage.IsAdmin)
local PlaceIDs = require(ReplicatedStorage.PlaceIDs)
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

local function openSettingsForPlayer(plr: Player): ()
    ReplicatedStorage.ServerClient.OpenSettings:FireClient(plr)
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
        elseif cmd == "!settings" then
            openSettingsForPlayer(plr)
        end
    end)
end)