local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

assert(RunService:IsClient(), "GetAmmoDefinition should only be called on the client")

local function GetAmmoDefinition(name: string): Types.AmmoDefinition
    local map = LocalRoundInfo.Map()
    if map and map.AvailableAmmo[name] then
        return map.AvailableAmmo[name]
    end

    local gamemode = LocalRoundInfo.Gamemode()
    if gamemode and gamemode.AvailableAmmo[name] then
        return gamemode.AvailableAmmo[name]
    end

    error(`Ammo {name} does not exist in map or gamemode`)
end

return GetAmmoDefinition