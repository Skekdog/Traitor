local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Exec = require(ReplicatedStorage.DevTools.Exec)
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

local gamemodes: {Types.Gamemode} = {}
for _, v in ReplicatedStorage.GameDefinition.Gamemodes:GetChildren() do
    for i = 1, if v.Name == "ThoseYouTrust" then 4 else 1 do
        table.insert(gamemodes, (require)(v))
    end
end

local module = {}

local forcedGamemode = nil :: Types.Gamemode?

function module.TrySetForcedGamemode(gamemode: string?): boolean
    if not gamemode then
        module.ForcedGamemode = nil
        return true
    end

    local found: Types.Gamemode?
    for _, v in gamemodes do
        if v.Name == gamemode then
            found = v
            break
        end
    end

    if not found then
        return false
    end

    forcedGamemode = found
    return true
end

local function pickNextGamemode(): Types.Gamemode
    if forcedGamemode then
        return forcedGamemode
    end

    return gamemodes[math.random(#gamemodes)]
end

local function newRound(): Types.Round
    roundCount += 1

    local gamemode = pickNextGamemode()
    local round = Round.new(gamemode)
    round:LoadMap(currentMap)

    return round
end

local round = newRound()

function module.GetRound(): Types.Round
    return round
end

local function doMapVote(): ()
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

task.spawn(function()
    while true do
        if round:GetRoundPhase() ~= "Intermission" then
            task.wait()
            continue
        end

        if roundCount % MAP_VOTE_INTERVAL == 0 then
            doMapVote()
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

ReplicatedStorage.ClientServer.Fell.OnServerEvent:Connect(function(player: Player, distance: number)
    local participant = round:GetParticipant(player.Name)
    if not participant then
        return
    end

    if distance <= 15 then
        return
    end

    local damage = (0.5 * (distance - 15) ^ 1.5) * 80 / workspace.Gravity

    participant:TryTakeDamage({
        Amount = damage,
        Source = "Fall",
    })
end)

ReplicatedStorage.ClientServer.GetCorpseInfo.OnServerInvoke = function(plr, body: unknown, covert: unknown): Types.CorpseView?
    if typeof(body) ~= "Instance" or (not body:IsA("Model") and not body:IsA("Player")) then
        return nil
    end

    if typeof(covert) ~= "boolean" then
        return nil
    end

    local participant = round:GetParticipant(plr.Name)
    if not participant then
        return nil
    end

    if participant:GetStatus() == "Alive" and not body:IsA("Model") then
        return nil -- if alive then we need to find a body to view corpse info. Spectators don't need to do that
    end

    local otherParticipant = round:GetParticipant(body.Name)
    if not otherParticipant then
        return nil
    end

    local corpse = otherParticipant:GetCorpse()
    if not corpse then
        return nil
    end

    local success = corpse:Search(participant, covert)
    if success then
        return corpse.CorpseView
    end

    return nil
end

ReplicatedStorage.ClientServer.Exec.OnServerInvoke = function(plr, command: string): string | true
    return Exec.ServerExecute(plr, round, command)
end

return module