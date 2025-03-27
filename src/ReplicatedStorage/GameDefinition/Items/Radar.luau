local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.RoundRule.Types)

local radarPoint = ReplicatedStorage:WaitForChild("RadarPoint")
local item: Types.ItemDefinition = {
	Kind = "Item" :: "Item",
    Description = "Reveals the location of all living players every 30 seconds.",
    CreditCost = 1,
    MaxStock = 1,
    Icon = "rbxassetid://62159372",
    Name = "Radar",

    HeartbeatClient = function(item: Types.AnyItem)
        assert(item.Kind == "Item")
        local lastScan: number = item.Extras.LastScan or 0

        local timeNow = workspace:GetServerTimeNow()
        if timeNow - lastScan < 30 then
            return
        end

        item.Extras.LastScan = timeNow

        workspace.RadarPoints:ClearAllChildren()

        for _, v in Players:GetPlayers() do
            local char = v.Character
            if not char or v == Players.LocalPlayer then
                continue
            end

            local root = char.PrimaryPart
            local hum = char:FindFirstChildOfClass("Humanoid")

            if not root or not hum or hum.Health <= 0 then
                continue
            end

            local clone = radarPoint:Clone()
            clone:PivotTo(root.CFrame)
            clone.RadarPoint.TextLabel.Text = tostring(math.round(v:DistanceFromCharacter(root.Position)))
            clone.RadarPoint.Enabled = true
            clone.Parent = workspace.RadarPoints
        end
    end
}

return item