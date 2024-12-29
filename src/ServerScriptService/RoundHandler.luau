local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Elimination = require(script.Parent.Parent.ReplicatedFirst.GameDefinition.Gamemodes.Elimination)
local Round = require(script.Parent.Parent.ReplicatedFirst.RoundRule.Round)
local Types = require(ReplicatedFirst.RoundRule.Types)

local maps = ServerStorage.Maps

local module = {}

local function newRound(): Types.Round
    local round = Round.new(Elimination)
    round:LoadMap(maps.Skyscraper)
    return round
end

local round = newRound()

function module.GetRound(): Types.Round
    return round
end

task.spawn(function()
    while true do
        if round:GetRoundPhase() == "Intermission" then
            round = newRound()
        end
        task.wait()
    end
end)

local function onPlayerAdded(player: Player)
    round:AddPlayer(player, true)
end

for _, v in Players:GetPlayers() do
    onPlayerAdded(v)
end

Players.PlayerAdded:Connect(onPlayerAdded)

ReplicatedStorage:WaitForChild("RoundHandler").JoinRound.OnServerInvoke = function(player: Player): boolean?
    if not round:IsPreGame() then
        return false
    end

    local existingParticipant = round:GetParticipant(player.Name)
    if existingParticipant and existingParticipant:GetStatus() ~= "Spectating" then
        return false
    end

    round:AddPlayer(player, false)

    return true
end

return module