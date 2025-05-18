local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalParticipantInfo = require(script.Parent.LocalParticipantInfo)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local function highlight(player: Player, role: Types.Role)
    local clone = Instance.new("Highlight")
    CollectionService:AddTag(clone, "AllyMarker")
    clone.FillTransparency = 1
    clone.OutlineColor = role.Definition.Color
    clone.OutlineTransparency = 0
    clone.Parent = player.Character
end

local function tryHighlightPlayer(player: Player): ()
    local ownRole = LocalParticipantInfo.GetParticipant().Role()
    local theirRole = LocalParticipantInfo.GetParticipant(player.Name).Role()

    if not ownRole.Definition.HighlightedRoles then
        return
    end

    if table.find(ownRole.Definition.HighlightedRoles, theirRole.Definition.Name) then
        highlight(player, theirRole)
    end
end

return tryHighlightPlayer