local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local Types = require(ReplicatedStorage.RoundRule.Types)

local function highlight(player: Player, role: Types.Role)
    local clone = Instance.new("Highlight")
    CollectionService:AddTag(clone, "AllyMarker")
    clone.FillTransparency = 1
    clone.OutlineColor = role.Definition.Color
    clone.OutlineTransparency = 0
    clone.Parent = player.Character
end

local function tryHighlightPlayer(player: Player): ()
    local ownRole = LocalRoundInfo.GetPlayerRole(Players.LocalPlayer.Name)
    local theirRole = LocalRoundInfo.GetPlayerRole(player.Name)
    if not ownRole or not theirRole or not ownRole.Definition.HighlightedRoles then
        return
    end
    
    if table.find(ownRole.Definition.HighlightedRoles, theirRole.Definition.Name) then
        highlight(player, theirRole)
    end
end

return tryHighlightPlayer