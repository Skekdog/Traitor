local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetDisplayName = require(ReplicatedStorage.Shared.RoundRule.Common.GetDisplayName)
local LocalParticipantInfo = require(script.Parent.LocalParticipantInfo)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local function makeIcon(player: Player, role: Types.Role): BillboardGui
    local gui = Instance.new("BillboardGui")
    gui.Name = "RoleIcon"

    local head: BasePart -- we need to lie here because it thinks that Adornee cannot be nil, even though it can
    if player.Character then
        local found = player.Character:FindFirstChild("Head")
        if found and found:IsA("BasePart") then
            head = found
        end
    end
    gui.Adornee = head

    gui.Size = UDim2.fromScale(1, 1)

    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = role.Definition.Color
    frame.Size = UDim2.fromScale(1, 1)
    frame.Parent = gui

    do
        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 8)
        uiCorner.Parent = frame
    end

    local textLabel = Instance.new("TextLabel")
    textLabel.Text = GetDisplayName(role.Definition):sub(1, 1):upper()
    textLabel.TextColor3 = Color3.new(1, 1, 1) --todo: follow WCAG contrast guidelines for determining colour
    textLabel.TextScaled = true

    do
        local uiPadding = Instance.new("UIPadding")
        uiPadding.PaddingBottom = UDim.new(0, 5)
        uiPadding.PaddingLeft = UDim.new(0, 5)
        uiPadding.PaddingRight = UDim.new(0, 5)
        uiPadding.PaddingTop = UDim.new(0, 5)
        uiPadding.Parent = textLabel
    end

    gui:AddTag("AllyMarker")
    gui.Parent = player.Character

    return gui
end

local function highlight(player: Player, role: Types.Role)
    local clone = Instance.new("Highlight")
    clone:AddTag("AllyMarker")
    clone.FillTransparency = 1
    clone.OutlineColor = role.Definition.Color
    clone.OutlineTransparency = 0
    clone.Parent = player.Character
    makeIcon(player, role)
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