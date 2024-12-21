local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Elimination = require(script.Parent.Parent.ReplicatedFirst.GameDefinition.Gamemodes.Elimination)
local Round = require(script.Parent.Parent.ReplicatedFirst.RoundRule.Round)
local Types = require(ReplicatedFirst.RoundRule.Types)

local module = {}

local function newRound()
    return Round.new(Elimination)
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
    end
end)

local function onPlayerAdded(player: Player)
    round:AddPlayer(player, not round:IsPreGame())
end

for _, v in Players:GetPlayers() do
    onPlayerAdded(v)
end

Players.PlayerAdded:Connect(onPlayerAdded)

return module