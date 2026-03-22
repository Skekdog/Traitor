local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CreateRadarPoint = require(ReplicatedStorage.API.CreateRadarPoint)
local Custom = require(ReplicatedStorage.API.Item.Presets.Custom)
local Decoy = require(ReplicatedStorage.Shared.GameDefinition.Interactables.Decoy)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local GREY_COLOUR = Color3.new(0.5, 0.5, 0.5)
local GREEN_COLOUR = Color3.fromRGB(55, 174, 37)

local function HeartbeatClient(item: Types.Item): ()
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
        local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)
        table.insert(decoyPlayers, v.Extras.Player)

        assert(v.Model:IsA("BasePart"))
        CreateRadarPoint(v.Model.CFrame, if LocalParticipantInfo.GetParticipant().Role().Definition.IsEvil then GREY_COLOUR else GREEN_COLOUR, "RadarScan")
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

local item = Custom({
    Description = "Reveals the location of all living players every 30 seconds.",
    Cost = 1,
    MaxStock = 1,
    IconContent = Content.fromAssetId(62159372),
    Name = "Radar",

    CorpseIconDescription = "They were using %s. Unfortunately, it is now broken.",

    HeartbeatClient = HeartbeatClient,
})

return table.freeze(item)