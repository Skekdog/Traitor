local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Types = require(ReplicatedStorage.API.Types)

assert(RunService:IsClient(), "GetInteractableDefinition should only be called on the client")

local function GetInteractableDefinition(name: string, gamemode: Types.GamemodeDefinition, map: Types.Map): Types.InteractableDefinition?
    return map.InteractableDefinitions[name] or gamemode.InteractableDefinitions[name]
end

return GetInteractableDefinition