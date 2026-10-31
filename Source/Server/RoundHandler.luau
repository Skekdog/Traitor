local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Audio = require(ReplicatedStorage.API.Audio)
local TeamChat = require(ServerScriptService.Chat.TeamChat)
local Ban = require(ServerScriptService.Moderation.Ban)
local GetMaterial = require(ReplicatedStorage.API.GetMaterial)
local Impulse = require(ReplicatedStorage.API.Impulse)
local RoundHooks = require(ReplicatedStorage.API.GameHooks)
local HitSounds = require(ReplicatedStorage.Shared.Combat.HitSounds)
local DeathSounds = require(ReplicatedStorage.Shared.Config.DeathSounds)
local StringWithDeterminer = require(ReplicatedStorage.Shared.Grammar.StringWithDeterminer)
local ShowAlert = require(ReplicatedStorage.Shared.Interface.Util.ShowAlert)
local GetDisplayName = require(ReplicatedStorage.Shared.RoundRule.Common.GetDisplayName)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local GamemodeValidation = require(ReplicatedStorage.Shared.RoundRule.GamemodeValidation)
local KarmaManager = require(ServerScriptService.Player.KarmaManager)
local ScoreManager = require(ServerScriptService.Player.ScoreManager)
local Map = require(ReplicatedStorage.Shared.RoundRule.Map)
local Replication = require(ReplicatedStorage.Shared.RoundRule.Replication)
local Round = require(ReplicatedStorage.Shared.RoundRule.Round)
local Types = require(ReplicatedStorage.API.Types)
local DynamicValue = require(ReplicatedStorage.Shared.Util.DynamicValue)

local module = {}

local defaultGamemode = GamemodeValidation.ValidateGamemodeScript(ReplicatedStorage.Shared.GameDefinition.Gamemodes.Traitor)

local EXCLUDED_GAMEMODES: {Instance} = {ReplicatedStorage.Shared.GameDefinition.Gamemodes.FloodEscape}

const NO_KARMA_BANS = true
const KARMA_BAN_THRESHOLD = 250

Round.Config.DeathSounds = DeathSounds

local forcedMap: Types.MapStructure?
local forcedGamemode: Types.GamemodeDefinition?

local currentMap = "International"

function module.SetForcedMap(map: Types.MapStructure?): ()
    forcedMap = map

    if forcedMap then
        currentMap = forcedMap.Name
    end
end

function module.SetForcedGamemode(gamemode: Types.GamemodeDefinition?): ()
    forcedGamemode = gamemode
end

local blockNewRounds = false
function module.BlockNewRounds(): ()
    blockNewRounds = true
end

local function impulseCorpse(round: Types.Round, participant: Types.Participant): ()
    if not participant.Extras.CombatImpulse or not participant.Corpse or not participant.Corpse.Model or not participant.Corpse.Model.PrimaryPart then
        return
    end

    Impulse.ApplyImpulse(participant.Corpse.Model.PrimaryPart, participant.Extras.CombatImpulse, true)
end

local function removeTeamChat(round: Types.Round, participant: Types.Participant): ()
    TeamChat.TryRemove(participant.Player.UserId)
end

local function youWereKilledBy(round: Types.Round, participant: Types.Participant): ()
    if not participant.Corpse then
        return
    end

    local attacker = participant.Corpse.Killer
    if not attacker or attacker == participant then
        return
    end

    local roleName = GetDisplayName(attacker:GetRole().Definition)
    local formattedRoleName = attacker:GetRole():GetFormattedName()
    local determiner = StringWithDeterminer(roleName):split(" ")[1]
    if participant:IsAlliedWithParticipant(attacker) then
        ShowAlert(`You were killed by {attacker:GetFormattedName()}{if participant.Corpse.CorpseView.WasSelfDefense then " in self-defense" else ""}. They were {determiner} {formattedRoleName}.`, participant.Player)
    else
        ShowAlert(`You were killed by {determiner} {formattedRoleName}!`, participant.Player)
    end
end

RoundHooks.OnDeath["ImpulseCorpse"] = impulseCorpse
RoundHooks.OnDeath["RemoveTeamChat"] = removeTeamChat
RoundHooks.OnDeath["YouWereKilledBy"] = youWereKilledBy

function Round.Config.OnPhaseChanged(round: Types.Round, phase: Types.Phase): ()
    for _, hook in RoundHooks.OnPhaseChanged do
        hook(round, phase)
    end
end

function Round.Config.OnDeath(round: Types.Round, participant: Types.Participant): ()
    for _, hook in RoundHooks.OnDeath do
        hook(round, participant)
    end
end

function Round.Config.BeforeDamageParticipant(round: Types.Round, participant: Types.Participant, params: Types.DamageParams): boolean
    for _, hook in RoundHooks.BeforeDamageParticipant do
        hook(round, participant, params)
    end

    return true
end

function Round.Config.OnItemDropped(round: Types.Round, participant: Types.Participant, item: Types.Item): ()
    for _, hook in RoundHooks.OnItemDropped do
        hook(round, participant, item)
    end
end

module.OnCharacterAdded = {} :: {(Types.Round, Types.Participant) -> ()}
function Round.Config.OnCharacterAdded(round: Types.Round, participant: Types.Participant): ()
    participant.Extras.CombatImpulse = nil

    for _, v in module.OnCharacterAdded do
        v(round, participant)
    end
end

function Round.Config.BeforeDamageProp(round: Types.Round, prop: Types.Prop, params: Types.DamageParams): boolean
    if typeof(params.Source) == "table" then
        return true
    end

    local health = prop:GetHealth()
    local willDestroy = if health then health - params.Amount <= 0 else false

    if not willDestroy then
        return true
    end

    local hitPart = params.HitPart or GetPrimaryPart(prop.Model)

    local sounds = HitSounds[GetMaterial(hitPart)] or HitSounds.Default
	local sound = sounds[math.random(#sounds)]

    Audio.PlayAt(sound, params.HitPosition or hitPart.Position)

    return true
end

RoundHooks.OnRoleAssigned["TeamChat"] = function(round: Types.Round, participant: Types.Participant): ()
    TeamChat.TryAssign(participant)
end

function Round.Config.OnRoleAssigned(round: Types.Round, participant: Types.Participant, role: Types.Role): ()
    for _, v in RoundHooks.OnRoleAssigned do
        v(round, participant, role)
    end
end

local remotes = ReplicatedStorage.Remotes

local maps = ServerStorage.Maps

local random = Random.new(workspace:GetServerTimeNow())

local function getMap(name: string): Types.MapStructure
    return Map.ValidateStructure((maps :: any)[name]:Clone())
end

type ClientMapInfo = {
    Name: string,
    Icon: Content
}

local function getMapsForVote(): {ClientMapInfo}
    local votableMaps: {ClientMapInfo} = {}

    local mapChildren = maps:GetChildren()
    random:Shuffle(mapChildren)

    for _, v in mapChildren do
        if #votableMaps > 3 then
            break
        end

        if v.Name ~= currentMap and not v:GetAttribute("Experimental") then
            local success, structure = pcall(Map.ValidateStructure, v)
            if not success then
                warn(`Failed to load map {v.Name}: {structure}`)
                continue
            end

            local map = Map.new(structure)

            table.insert(votableMaps, {
                Name = GetDisplayName(map),
                Icon = map.Icon
            })
        end
    end

    return votableMaps
end

local roundCount = -1

local MAP_VOTE_INTERVAL = 3
local INTERMISSION_TIME = 15

local varietyGamemodes: {Types.GamemodeDefinition} = {}
function module.UpdateLoadedGamemodes(): ()
    varietyGamemodes = {}
    for _, v in ReplicatedStorage.Shared.GameDefinition.Gamemodes:GetChildren() do
        if not v:IsA("ModuleScript") then
            continue
        end

        if table.find(EXCLUDED_GAMEMODES, v) or defaultGamemode.Name == v.Name then
            continue
        end

        table.insert(varietyGamemodes, GamemodeValidation.ValidateGamemodeScript(v))
    end
end

module.UpdateLoadedGamemodes()

local function pickNextGamemode(map: Types.MapStructure): Types.GamemodeDefinition
    if forcedGamemode then
        return forcedGamemode
    end

    if roundCount == 0 or roundCount % MAP_VOTE_INTERVAL ~= 0 then
        return defaultGamemode
    end

    local validGamemodes: {Types.GamemodeDefinition} = {}
    for _, gamemode in varietyGamemodes do
        if not gamemode.IsValidOnMap or gamemode.IsValidOnMap(map) then
            table.insert(validGamemodes, gamemode)
        end
    end

    assert(#validGamemodes > 0, "No valid gamemodes found for this map")

    return validGamemodes[math.random(#validGamemodes)]
end

module.Round = DynamicValue.new((nil :: any) :: Types.Round)

local didEnd = false
local function newRound(): Types.Round
    didEnd = false
    roundCount += 1

    if not NO_KARMA_BANS then
        for _, player in Players:GetPlayers() do
            local karma = KarmaManager.GetKarma(player)
            if karma and karma < KARMA_BAN_THRESHOLD then
                Ban.Karma(player)
            end
        end
    end

    TeamChat.Clear()

    local map = getMap(currentMap)

    local gamemode = pickNextGamemode(map)
    module.Round:SetValue(Round.new(gamemode))
    task.defer(module.Round().LoadMap, module.Round(), map) -- somefuckinghow loading normally will cause recursive require errors on SERVER scripts, not even module scripts. WTF.

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

    local playerAddedCon = Players.PlayerAdded:Connect(function(player)
        remotes.ServerClient.TriggerMapVote:FireClient(player, true, votableMaps)

        local counts: {[string]: number} = {}
        for _, v in votes do
            counts[v] = (counts[v] or 0) + 1
        end

        remotes.ServerClient.UpdateMapVotes:FireClient(player, counts)
    end)

    local finished = false
    module.Round():SetPhase("Intermission", INTERMISSION_TIME, function()
        finished = true
    end)

    while not finished do
        task.wait()
    end

    playerAddedCon:Disconnect()
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
    assert(bestMap)

    currentMap = bestMap
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

        if blockNewRounds then
            module.Round:Invoke()
            break
        end

        if not forcedMap and roundCount % MAP_VOTE_INTERVAL == 0 then
            doMapVote()
        end

        for model in module.Round():GetItems() do
            model:Destroy()
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

remotes.ClientServer.GetCorpseInfo.OnServerInvoke = function(plr, body: unknown, covert: unknown): Types.ClientCorpseView?
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
        if typeof(corpse.CorpseView.DamageSource) == "table" then
            local view: Types.ClientCorpseView = table.clone(corpse.CorpseView) :: any
            view.DamageSource = Replication.GetItemReplicate(corpse.CorpseView.DamageSource, false, {"IconContent"})
            return view
        end
        return (corpse.CorpseView :: Types.BaseCorpseView) :: Types.ClientCorpseView
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

    local searcherChar = participant:GetCharacter()
    if not searcherChar or not searcherChar.PrimaryPart then
        return
    end

    local corpseChar = corpse.Model
    if not corpseChar or not corpseChar.PrimaryPart then
        return
    end

    if (searcherChar.PrimaryPart.Position - corpseChar.PrimaryPart.Position).Magnitude > participant.CorpseSearchDistance then
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

    local searcherChar = participant:GetCharacter()
    if not searcherChar or not searcherChar.PrimaryPart then
        return
    end

    local corpseChar = corpse.Model
    if not corpseChar or not corpseChar.PrimaryPart then
        return
    end

    if (searcherChar.PrimaryPart.Position - corpseChar.PrimaryPart.Position).Magnitude > participant.CorpseSearchDistance then
        return
    end

    corpse:CallRole(participant)
end)

return table.freeze(module)