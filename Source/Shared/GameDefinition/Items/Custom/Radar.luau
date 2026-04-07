local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CreateRadarPoint = require(ReplicatedStorage.API.CreateRadarPoint)
local Custom = require(ReplicatedStorage.API.Item.Presets.Custom)
local Decoy = require(ReplicatedStorage.Shared.GameDefinition.Interactables.Decoy)
local Types = require(ReplicatedStorage.API.Types)

local GREY_COLOUR = Color3.new(0.5, 0.5, 0.5)
local GREEN_COLOUR = Color3.fromRGB(55, 174, 37)

local function HeartbeatClient(item: Types.Item): ()
    local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)

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

    for _, player in Players:GetPlayers() do
        local cframe, isDecoy = Decoy.GetPlayerPosition(player)
        if not cframe then
            continue
        end

        local colour = if isDecoy and (player == Players.LocalPlayer or
            LocalParticipantInfo.GetParticipant().Role():IsAlliedWith(LocalParticipantInfo.GetParticipant(player.Name).Role())) then
                GREY_COLOUR
            else
                GREEN_COLOUR

        CreateRadarPoint(cframe, colour, "RadarScan")
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