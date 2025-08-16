local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

assert(RunService:IsClient(), "GetInteractableDefinition should only be called on the client")

local function GetInteractableDefinition(name: string): Types.InteractableDefinition?
    local gamemode = LocalRoundInfo.Gamemode()
    if gamemode and gamemode.InteractableDefinitions[name] then
        return gamemode.InteractableDefinitions[name]
    end

    return nil
end

return GetInteractableDefinition