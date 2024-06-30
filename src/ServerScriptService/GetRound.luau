local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerStorage = game:GetService("ServerStorage")
local Types = require(ReplicatedFirst.RoundHandler.Types)
local RoundHandler = require(ReplicatedFirst.RoundHandler.RoundHandler)

return function(): Types.Round?
    local roundId = ServerStorage:GetAttribute("RoundID")
    if not roundId then
        return
    end

    return RoundHandler.GetRound(roundId)
end
