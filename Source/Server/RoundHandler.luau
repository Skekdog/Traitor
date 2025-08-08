local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local KarmaManager = require(ServerScriptService.Player.KarmaManager)
local ScoreManager = require(ServerScriptService.Player.ScoreManager)
local Map = require(ReplicatedStorage.Shared.RoundRule.Map)
local Round = require(ReplicatedStorage.Shared.RoundRule.Round)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local DynamicValue = require(ReplicatedStorage.Shared.Util.DynamicValue)

local remotes = ReplicatedStorage.Remotes

local maps = ServerStorage.Maps

local random = Random.new(workspace:GetServerTimeNow())

local currentMap = maps.Skylands

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

local gamemodes: {Types.GamemodeDefinition} = {}
for _, v in ReplicatedStorage.Shared.GameDefinition.Gamemodes:GetChildren() do
    if not v:IsA("ModuleScript") then
        continue
    end

    for i = 1, if v.Name == "ThoseYouTrust" then 4 else 1 do
        table.insert(gamemodes, (require)(v))
    end
end

local module = {}

local forcedGamemode = nil :: Types.GamemodeDefinition?

function module.TrySetForcedGamemode(gamemode: string?): boolean
    if not gamemode then
        module.ForcedGamemode = nil
        return true
    end

    local found: Types.GamemodeDefinition?
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

local function pickNextGamemode(): Types.GamemodeDefinition
    if forcedGamemode then
        return forcedGamemode
    end

    return gamemodes[math.random(#gamemodes)]
end

module.Round = DynamicValue.new((nil :: any) :: Types.Round)

local didEnd = false
local function newRound(): Types.Round
    didEnd = false
    roundCount += 1

    local gamemode = pickNextGamemode()
    module.Round:SetValue(Round.new(gamemode))
    task.defer(module.Round().LoadMap, module.Round(), currentMap) -- somefuckinghow loading normally will cause recursive require errors on SERVER scripts, not even module scripts. WTF.

    return module.Round()
end

newRound()

function module.GetRound(): Types.Round
    return module.Round()
end

local function doMapVote(): ()
    local votableMaps = getMapsForVote()

    local votes: {[Player]: string} = {}
    local con: RBXScriptConnection
    con = remotes.ClientServer.VoteMap.OnServerEvent:Connect(function(plr, mapName: unknown)
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

        remotes.ServerClient.UpdateMapVotes:FireAllClients(counts)
    end)

    remotes.ServerClient.TriggerMapVote:FireAllClients(true, votableMaps)
    module.Round():SetPhase("Intermission", INTERMISSION_TIME)
    task.wait(INTERMISSION_TIME)

    con:Disconnect()

    remotes.ServerClient.TriggerMapVote:FireAllClients(false)

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

local function onRoundEnd(): ()
    didEnd = true
    for _, v in module.Round():GetParticipants() do
        assert(v)

        local totalScore = 0
        for _, v in v.Scores do
            assert(v)
            totalScore += v
        end

        if module.Round().Gamemode.EnableKarma then
            KarmaManager.SetKarma(v.Player, v:GetKarma())
        end
        
        ScoreManager.AddScore(v.Player, totalScore)
    end
end

task.spawn(function()
    while true do
        if not didEnd and module.Round():GetPhase() == "Highlights" then
            onRoundEnd()
        end

        if module.Round():GetPhase() ~= "Intermission" then
            task.wait()
            continue
        end

        if roundCount % MAP_VOTE_INTERVAL == 0 then
            doMapVote()
        end
        newRound()
    end
end)

remotes.ClientServer.JoinRound.OnServerInvoke = function(player: Player): boolean?
    if not module.Round():IsPreGame() then
        return false
    end

    local existingParticipant = module.Round():GetParticipant(player.Name)
    if existingParticipant then
        return false
    end

    module.Round():AddPlayer(player, KarmaManager.GetKarma(player))

    return true
end

ReplicatedStorage.Shared.RoundRule.Remotes.PurchaseItem.OnServerInvoke = function(player: Player, itemName: unknown): Types.ItemPurchaseResult
    if typeof(itemName) ~= "string" then
        return "InvalidItemForRole"
    end

    local participant = module.Round():GetParticipant(player.Name)
    if not participant then
        return "NotInRound"
    end

    local item = participant.Round:GetItemDefinition(itemName)
    if not item then
        return "InvalidItemForRole"
    end

    return participant:PurchaseItem(item)
end

ReplicatedStorage.Shared.RoundRule.Remotes.SlayVote.OnServerEvent:Connect(function(player: Player, against: unknown): ()
    if typeof(against) ~= "string" then
        return
    end

    local participant = module.Round():GetParticipant(player.Name)
    if not participant then
        return
    end

    local againstParticipant = module.Round():GetParticipant(against)
    if not againstParticipant then
        return
    end

    againstParticipant:TryAddSlayVote(participant)
end)

remotes.ClientServer.GetCorpseInfo.OnServerInvoke = function(plr, body: unknown, covert: unknown): Types.CorpseView?
    if typeof(body) ~= "Instance" or (not body:IsA("Model") and not body:IsA("Player")) then
        return nil
    end

    if typeof(covert) ~= "boolean" then
        return nil
    end

    local participant = module.Round():GetParticipant(plr.Name)

    if participant and participant:GetStatus() == "Alive" and not body:IsA("Model") then
        return nil -- if alive then we need to find a body to view corpse info. Spectators don't need to do that
    end

    local otherParticipant = module.Round():GetParticipant(body.Name)
    if not otherParticipant then
        return nil
    end

    local corpse = otherParticipant.Corpse
    if not corpse then
        return nil
    end

    local success = corpse:Search(participant, covert, if not participant then plr else nil)
    if success then
        return corpse.CorpseView
    end

    return nil
end

remotes.ClientServer.ConfirmDeath.OnServerEvent:Connect(function(player: Player, corpseName: unknown): ()
    if typeof(corpseName) ~= "string" then
        return
    end

    local participant = module.Round():GetParticipant(player.Name)
    if not participant or not participant:IsAlive() then
        return
    end

    local otherParticipant = module.Round():GetParticipant(corpseName)
    if not otherParticipant then
        return
    end

    local corpse = otherParticipant.Corpse
    if not corpse then
        return
    end

    corpse:SearchAsAlive(participant, false)
end)

remotes.ClientServer.CallRole.OnServerEvent:Connect(function(player: Player, corpseName: unknown): ()
    if typeof(corpseName) ~= "string" then
        return
    end

    local participant = module.Round():GetParticipant(player.Name)
    if not participant or not participant:IsAlive() then
        return
    end

    local otherParticipant = module.Round():GetParticipant(corpseName)
    if not otherParticipant then
        return
    end

    local corpse = otherParticipant.Corpse
    if not corpse then
        return
    end

    corpse:CallRole(participant)
end)

return module