local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RoundHandler = require(ReplicatedFirst.RoundHandler.RoundHandler)
return function()
    local id = ServerStorage:GetAttribute("RoundID")
    if not id then
        return "No round is in progress."
    end
    local round = RoundHandler.GetRound(id)
    if not round:IsRoundInProgress() then
        return "Round is not currently in progress."
    end

    round:PauseRound()

    if not round.Paused then
        ReplicatedStorage.RoundHandler:SetAttribute("TimeMilestone", round.TimeMilestone)
    end
    ReplicatedStorage.RoundHandler:SetAttribute("IsPaused", round.Paused)

    return `Successfully {round.Paused and "paused" or "unpaused"} the current round.`
end
