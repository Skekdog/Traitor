local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local Types = require(ReplicatedStorage.RoundRule.Types)

assert(RunService:IsClient(), "GetItemDefinition should only be called on the client")

local function GetItemDefinition(name: string): Types.AnyItemDefinition
    local map = LocalRoundInfo.GetMap()
    if map and map.AvailableItems[name] then
        return map.AvailableItems[name]
    end

    local gamemode = LocalRoundInfo.GetGamemode()
    if gamemode and gamemode.AvailableItems[name] then
        return gamemode.AvailableItems[name]
    end

    error(`Item {name} does not exist in map or gamemode`)
end

return GetItemDefinition