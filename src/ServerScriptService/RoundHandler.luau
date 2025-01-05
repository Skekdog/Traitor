local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Elimination = require(ReplicatedStorage.GameDefinition.Gamemodes.Elimination)
local Map = require(ReplicatedStorage.RoundRule.Map)
local Round = require(ReplicatedStorage.RoundRule.Round)
local Types = require(ReplicatedStorage.RoundRule.Types)

local maps = ServerStorage.Maps

local random = Random.new(workspace:GetServerTimeNow())

local currentMap = maps.Skyscraper

type ClientMapInfo = {
    Name: string,
    Icons: {
        ["16:9"]: string?,
        ["4:3"]: string?,
        ["1:1"]: string?,
    }
}

local function getMapsForVote(): {ClientMapInfo}
    local votableMaps: {ClientMapInfo} = {}
    
    local mapChildren = maps:GetChildren()
    random:Shuffle(mapChildren)

    for _, v in mapChildren do
        if #votableMaps > 3 then
            break
        end

        assert(v:IsA("ModuleScript"), "Invalid Map")

        if v.Name ~= currentMap.Name and v.Name ~= "TestMap" then
            local map = Map.fromModuleScript(v)
            table.insert(votableMaps, {
                Name = map.Name,
                Icons = map.MapIcons
            })
        end
    end

    return votableMaps
end

local roundCount = -1

local MAP_VOTE_INTERVAL = 3
local INTERMISSION_TIME = 15

local module = {}

local function newRound(): Types.Round
    roundCount += 1
    local round = Round.new(Elimination)
    round:LoadMap(currentMap)
    return round
end

local round = newRound()

function module.GetRound(): Types.Round
    return round
end

task.spawn(function()
    while true do
        if round:GetRoundPhase() ~= "Intermission" then
            task.wait()
            continue
        end

        if roundCount % MAP_VOTE_INTERVAL == 0 then
            local votableMaps = getMapsForVote()

            local votes: {[Player]: string} = {}
            local con: RBXScriptConnection
            con = ReplicatedStorage.ClientServer.VoteMap.OnServerEvent:Connect(function(plr, mapName: unknown)
                if typeof(mapName) ~= "string" then
                    return
                end

                local isVotable = false
                for _, v in votableMaps do
                    if v.Name == mapName then
                        isVotable = true
                        break
                    end
                end

                if not isVotable then
                    return
                end

                votes[plr] = mapName

                local counts: {[string]: number} = {}
                for _, v in votes do
                    counts[v] = (counts[v] or 0) + 1
                end

                ReplicatedStorage.ServerClient.UpdateMapVotes:FireAllClients(counts)
            end)

            ReplicatedStorage.ServerClient.TriggerMapVote:FireAllClients(true, votableMaps)
            round:SetRoundPhase("Intermission", INTERMISSION_TIME)
            task.wait(INTERMISSION_TIME)

            con:Disconnect()

            ReplicatedStorage.ServerClient.TriggerMapVote:FireAllClients(false)

            local totalVotes: {[string]: number} = {}
            for _, v in votes do
                totalVotes[v] = (totalVotes[v] or 0) + 1
            end

            local bestVotes, bestMap: string? = 0, nil
            for mapName, voteCount in totalVotes do
                if voteCount > bestVotes then
                    bestVotes = voteCount
                    bestMap = mapName
                end
            end

            if not bestMap then
                bestMap = votableMaps[1].Name
            end

            currentMap = (maps :: any)[bestMap]
            assert(currentMap:IsA("ModuleScript"), "Invalid Map")
        end
        round = newRound()
    end
end)

local function onPlayerAdded(player: Player)
    round:AddPlayer(player, true)
end

for _, v in Players:GetPlayers() do
    onPlayerAdded(v)
end

Players.PlayerAdded:Connect(onPlayerAdded)

ReplicatedStorage.ClientServer.JoinRound.OnServerInvoke = function(player: Player): boolean?
    if not round:IsPreGame() then
        return false
    end

    local existingParticipant = round:GetParticipant(player.Name)
    if existingParticipant and existingParticipant:GetStatus() ~= "Spectating" then
        return false
    end

    round:AddPlayer(player, false)

    return true
end

ReplicatedStorage.RoundRule.Remotes.PurchaseItem.OnServerInvoke = function(player: Player, itemName: string): Types.ItemPurchaseResult
    local participant = round:GetParticipant(player.Name)
    if not participant then
        return "NotInRound"
    end

    local item = participant.Round:GetItemDefinition(itemName)
    if not item then
        return "InvalidItemForRole"
    end

    return participant:PurchaseItem(item)
end

return module