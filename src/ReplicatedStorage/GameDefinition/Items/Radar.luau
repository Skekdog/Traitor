local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CreateRadarPoint = require(script.Parent.Common.CreateRadarPoint)
local Decoy = require(script.Parent.Parent.Interactables.Decoy)
local Types = require(ReplicatedStorage.RoundRule.Types)

local GREY_COLOUR = Color3.new(0.5, 0.5, 0.5)
local GREEN_COLOUR = Color3.fromRGB(154, 255, 138)

local function HeartbeatClient(item: Types.AnyItem): ()
    assert(item.Kind == "Item")
    local lastScan: number = item.Extras.LastScan or 0

    local timeNow = workspace:GetServerTimeNow()
    if timeNow - lastScan < 30 then
        return
    end

    item.Extras.LastScan = timeNow

    for _, v in workspace.RadarPoints:GetChildren() do
        if v.Name == "RadarScan" then
            v:Destroy()
        end
    end

    local decoyPlayers: {Player} = {}
    for _, v in Decoy.ActiveDecoysClient do
        local LocalRoundInfo = require(ReplicatedStorage.LocalRoundInfo)
        table.insert(decoyPlayers, v.Extras.Player)

        local roleValue = LocalRoundInfo.PlayerRoles()[Players.LocalPlayer.Name]
        local role = if roleValue then roleValue() else nil
        CreateRadarPoint(v.Object.CFrame, if role and role.Definition.IsBadGuys then GREY_COLOUR else GREEN_COLOUR, "RadarScan")
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

        CreateRadarPoint(root.CFrame, GREEN_COLOUR, "RadarScan")
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