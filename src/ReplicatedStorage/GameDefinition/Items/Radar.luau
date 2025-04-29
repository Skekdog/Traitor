local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Decoy = require(script.Parent.Parent.Interactables.Decoy)
local Types = require(ReplicatedStorage.RoundRule.Types)

local GREY_COLOUR = Color3.new(0.5, 0.5, 0.5)

local radarPoint = ReplicatedStorage:WaitForChild("RadarPoint")
local function markPosition(cFrame: CFrame, grey: boolean?): ()
    local noZRot = CFrame.Angles(cFrame.Rotation.X, cFrame.Rotation.Y, 0)
    cFrame = CFrame.new(cFrame.Position) * noZRot
    
    local clone = radarPoint:Clone()
    clone:PivotTo(cFrame)

    local ui = clone.RadarPoint
    ui.TextLabel.Text = tostring(math.round(Players.LocalPlayer:DistanceFromCharacter(cFrame.Position)))

    if grey then
        ui.ImageLabel.ImageColor3 = GREY_COLOUR
        ui.TextLabel.TextColor3 = GREY_COLOUR
        clone.Highlight.FillColor = GREY_COLOUR
        clone.Highlight.OutlineColor = GREY_COLOUR
    end

    ui.Enabled = true
    clone.Parent = workspace.RadarPoints
end

local function HeartbeatClient(item: Types.AnyItem): ()
    assert(item.Kind == "Item")
    local lastScan: number = item.Extras.LastScan or 0

    local timeNow = workspace:GetServerTimeNow()
    if timeNow - lastScan < 30 then
        return
    end

    item.Extras.LastScan = timeNow

    workspace.RadarPoints:ClearAllChildren()

    local decoyPlayers: {Player} = {}
    for _, v in Decoy.ActiveDecoysClient do
        table.insert(decoyPlayers, v.Extras.Player)
        markPosition(v.Object.CFrame, true)
    end

    for _, v in Players:GetPlayers() do
        if table.find(decoyPlayers, v) then
            continue
        end

        local char = v.Character
        if not char or v == Players.LocalPlayer then
            continue
        end

        local root = char.PrimaryPart
        local hum = char:FindFirstChildOfClass("Humanoid")

        if not root or not hum or hum.Health <= 0 then
            continue
        end

        markPosition(root.CFrame)
    end
end

local item: Types.ItemDefinition = {
	Kind = "Item" :: "Item",
    Description = "Reveals the location of all living players every 30 seconds.",
    CreditCost = 1,
    MaxStock = 1,
    Icon = "rbxassetid://62159372",
    Name = "Radar",

    HeartbeatClient = HeartbeatClient,
}

return item