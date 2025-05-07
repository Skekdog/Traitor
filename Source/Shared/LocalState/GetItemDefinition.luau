local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

assert(RunService:IsClient(), "GetItemDefinition should only be called on the client")

local function GetItemDefinition(name: string): Types.AnyItemDefinition?
    local map = LocalRoundInfo.Map()
    if map and map.AvailableItems[name] then
        return map.AvailableItems[name]
    end

    local gamemode = LocalRoundInfo.Gamemode()
    if gamemode and gamemode.AvailableItems[name] then
        return gamemode.AvailableItems[name]
    end

    return nil
end

return GetItemDefinition