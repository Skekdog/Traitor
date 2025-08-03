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

    gui.Size = UDim2.new(1, 20, 1, 20)

    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = Color3.new(1, 1, 1)
    frame.BackgroundTransparency = 0.1
    frame.Size = UDim2.fromScale(1, 1)
    frame.Parent = gui

    do
        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 8)
        uiCorner.Parent = frame

        local uiGradient = Instance.new("UIGradient")
        uiGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), role.Definition.Color)
        uiGradient.Offset = Vector2.new(0, 0.5)
        uiGradient.Rotation = -90
        uiGradient.Parent = frame

        local uiStroke = Instance.new("UIStroke")
        uiStroke.Thickness = 1
        uiStroke.Color = Color3.new(1, 1, 1)
        uiStroke.Parent = frame
    end

    local textLabel = Instance.new("TextLabel")
    textLabel.Text = GetDisplayName(role.Definition):sub(1, 1):upper()

    -- I tried using the WCAG contrast guidelines for this and the results were... eh.
    -- Probably because of the transparency and gradient (modifying the function to account for transparency didn't help)
    -- So instead we just compare to the denary value of 0.8, 0.8, 0.8 (0.5 is too dark)
    -- Not exactly perfect but well, colour is subjective anyway, and also, who is going to make a role that is so bright??
    textLabel.TextColor3 = if tonumber("0x" .. role.Definition.Color:ToHex()) > 13421772 then Color3.new() else Color3.new(1, 1, 1)

    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSans
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.fromScale(1, 1)
    textLabel.Parent = frame

    do
        local uiPadding = Instance.new("UIPadding")
        uiPadding.PaddingBottom = UDim.new(0, 5)
        uiPadding.PaddingLeft = UDim.new(0, 5)
        uiPadding.PaddingRight = UDim.new(0, 5)
        uiPadding.PaddingTop = UDim.new(0, 5)
        uiPadding.Parent = textLabel
    end

    gui:AddTag("AllyMarker")
    gui.AlwaysOnTop = true
    gui.StudsOffsetWorldSpace = Vector3.new(0, 1.5, 0)
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