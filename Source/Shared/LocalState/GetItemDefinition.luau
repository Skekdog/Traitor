local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local Types = require(ReplicatedStorage.API.Types)

assert(RunService:IsClient(), "GetItemDefinition should only be called on the client")

local function GetItemDefinition(name: string): Types.ItemComponents?
    local map = LocalRoundInfo.Map()
    if map and map.ItemDefinitions[name] then
        return map.ItemDefinitions[name]
    end

    local gamemode = LocalRoundInfo.Gamemode()
    if gamemode and gamemode.AvailableItems[name] then
        return gamemode.AvailableItems[name]
    end

    return nil
end

return GetItemDefinition