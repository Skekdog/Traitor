local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsValidProp = require(script.IsValidProp)
local DamageSource = require(ReplicatedStorage.API.DamageSource)
local PropHuntItems = require(script.Items)
local StandardGame = require(ReplicatedStorage.API.StandardGame)
local Types = require(ReplicatedStorage.API.Types)

local Ammo = StandardGame.GetAllAmmo()
local Interactables = StandardGame.GetInteractables()

local items = {}
for i, v in StandardGame.GetItems() do
	items[i] = v
end

for i, v in PropHuntItems do
	items[i] = v
end

local ROUND_DURATION = 300
local HIDE_TIME = 30

local INCORRECT_DAMAGE_AMOUNT = 10

local PROP_THRESHOLD_FOR_MAPS = 20

local Items = items

local roles: {[string]: Types.RoleDefinition} = {
    Hunter = {
        Kind = "RoleDefinition",
        Name = "Hunter",
        Description = "Eliminate the Props!",
        Sound = "rbxassetid://9042088276",
        Color = Color3.fromRGB(229, 53, 13),

        Allegiance = {Kind = "Role", Role = "Hunter"},

        IsEvil = false, -- traitor nodes are cool but decoy relies on IsEvil

        StartingItems = {Items["Crowbar"], Items["Scanner"]},
        StartingCredits = 1,

        EquipmentShop = {
            Items["Radar"],
            Items["Jetpack"],
			Items["Teleporter"],
			Items["Golden Gun"],
			Items["UMP"],
        },

        CanSeeMissingInAction = true,
        CanStealCreditsFromCorpses = true,

        AwardCreditsToRolesOnDeath = {
            Prop = 1,
        },

        RevealedRoles = {"Hunter", "Prop"},
    },

    Prop = {
        Kind = "RoleDefinition",
        Name = "Prop",
        Description = "Hide from the Hunters! They have Radars.",
        Sound = "rbxassetid://9042819926",
        Color = Color3.fromRGB(13, 197, 229),

        Allegiance = {Kind = "Role", Role = "Prop"},

        StartingItems = {Items.Propper},
        StartingCredits = 1,

        EquipmentShop = {
            Items["Radar"],
			Items["Decoy"],
			Items["Newton Launcher"],
			Items["Radio"],
			Items["Flashbang"],
			Items["FreezeGrenade"],
			Items["Cheeze"],
        },

        CanSeeMissingInAction = true,
        CanStealCreditsFromCorpses = false,

        RevealedRoles = {"Hunter", "Prop"},
    }
}

local function onStart(round: Types.Round): ()
    local map = round:GetMap()
    local platform = map.Structure.Dynamic:FindFirstChild("_PropHunt_Platform") :: typeof(ReplicatedStorage.Assets.Gamemode.PropHunt._PropHunt_Platform)?

    if not platform then
        local new = ReplicatedStorage.Assets.Gamemode.PropHunt._PropHunt_Platform:Clone()
        new:PivotTo(CFrame.new(-10000, 10000, 10000))
        new.Parent = map.Structure.Dynamic :: any
        platform = new
    end
    assert(platform)

    for _, hunter in round:GetParticipantsWithRole(round:GetRoleFromRoleName("Hunter")) do
        local char = hunter:GetCharacter()
        if char then
            char:PivotTo(platform.CFrame * CFrame.new(0, 5, 0))
        end
    end

    round:SetPhase("Playing", HIDE_TIME, function()
        round:SetPhase("Playing", ROUND_DURATION - HIDE_TIME)
        for _, hunter in round:GetParticipantsWithRole(round:GetRoleFromRoleName("Hunter")) do
            hunter:MoveToSpawn()
        end
    end)
end

local traitorMusic: {Sound} = {}
for _, v in ReplicatedStorage.Assets.VictoryMusic.Traitor:GetChildren() do
	if v:IsA("Sound") then
		table.insert(traitorMusic, v)
	end
end

local innocentMusic: {Sound} = {}
for _, v in ReplicatedStorage.Assets.VictoryMusic.Innocent:GetChildren() do
	if v:IsA("Sound") then
		table.insert(innocentMusic, v)
	end
end

local timeoutMusic: {Sound} = {}
for _, v in ReplicatedStorage.Assets.VictoryMusic.Timeout:GetChildren() do
	if v:IsA("Sound") then
		table.insert(timeoutMusic, v)
	end
end

local function getVictoryMusic(round: Types.Round, victor: Types.Victor, isTimeout: boolean): Sound
	if isTimeout then
		return timeoutMusic[math.random(#timeoutMusic)]
	end

	assert(victor.Kind == "Role")

	if victor.Definition.Name == "Hunter" then
		return traitorMusic[math.random(#traitorMusic)]
	end
	return innocentMusic[math.random(#innocentMusic)]
end

local function isValidOnMap(map: Types.MapStructure): boolean
    local props = map.Dynamic:QueryDescendants("Model .Prop, BasePart .Prop")

    local validProps = 0
    for _, prop in props do
        if IsValidProp(prop) then
            validProps += 1
        end
    end

    return validProps >= PROP_THRESHOLD_FOR_MAPS
end

local function awardScoreForKill(attacker: Types.Participant, victim: Types.Participant): ()
    local attackerRole = attacker:GetRole().Definition
    local victimRole = victim:GetRole().Definition

    if attacker == victim then
        attacker:AddScore("Suicide", -2)
    elseif attackerRole == roles.Hunter and victimRole == roles.Prop then
        attacker:AddScore("Caught Prop", 1)
    end
end

local function getWinner(round: Types.Round): Types.Role?
    local huntersAlive, propsAlive = 0, 0

    for _, participant in round:GetParticipants() do
        if not participant:IsAlive() then
            continue
        end

        if participant:GetRole().Definition == roles.Hunter then
            huntersAlive += 1
        else
            propsAlive += 1
        end
    end

    if propsAlive == 0 then
        return round:GetRoleFromRoleName("Hunter")
    elseif huntersAlive == 0 then
        return round:GetRoleFromRoleName("Prop")
    end

    return nil
end

local function tryFinishRound(round: Types.Round): ()
    local winner = getWinner(round)
    if winner then
        round:Finish(winner)
    end
end

local function killHighlights(attacker: Types.Participant, victim: Types.Participant): ()
    if attacker.Round.Extras.AnyKillsHappened or attacker == victim then
        return
    end

    attacker.Round.Extras.AnyKillsHappened = true
    attacker.Round:AddHighlight({
        Title = "First Blood",
        Description = attacker:GetFormattedName() .. " drew the first blood of the round.",
        Priority = 2,
        Group = "First Blood",
    })
end

local function beforeDamageParticipant(_, participant: Types.Participant, params: Types.DamageParams): boolean
    local attacker = params.Attacker
    if not attacker then
        return true
    end

    if params.Amount <= 0 then
        return true
    end

    if participant:GetRole().Definition == roles.Hunter and attacker:GetRole().Definition == roles.Prop then
        return false
    end

    return true
end

local function beforeDamageProp(_, prop: Types.Prop, params: Types.DamageParams): boolean
    local attacker = params.Attacker
    if not attacker then
        return true
    end

    if attacker:GetRole().Definition == roles.Hunter then
        if DamageSource.IsFirearm(params.Source) or DamageSource.IsMelee(params.Source) then
            attacker:TryTakeDamage({
                Amount = INCORRECT_DAMAGE_AMOUNT,
                Source = params.Source,
                Attacker = attacker,
            })
            return true -- allow, but harm, intentional damage to props
        end
        return false -- disallow unintentional damage
    end

    if params.Amount > 0 then
        return false
    end

    return true
end

local gamemode: Types.GamemodeDefinition = {
    Name = "PropHunt",
    DisplayName = "Prop Hunt",
    Description = "Hide from hunters as props.",

    Authors = "@Skekdogs",

    MinimumPlayers = 1,

    TimeoutVictor = function(round)
        return round:GetRoleFromRoleName("Prop")
    end,

    GetRoundEndMusic = getVictoryMusic,

    AssignRoles = function(i, participants: {Types.Participant}): ()
        if #participants == 1 then
            participants[1]:SetRole(roles.Prop)
            return
        end

        local numHunters = math.max(#participants // 4, 1)
        for i, v in participants do
            if i <= numHunters then
                v:SetRole(roles.Hunter)
            else
                v:SetRole(roles.Prop)
            end
        end
    end,

    GetVictoryEventText = function(round: Types.Round, victor: Types.Victor, isTimeout: boolean): string?
        local propRole = round:GetRoleFromRoleName("Prop")
        local hunterRole = round:GetRoleFromRoleName("Hunter")

        if isTimeout then
            return `The time has run out and the {propRole:FormatString("Props")} have won!`
        end

        assert(victor.Kind == "Role")

        if victor == propRole then
            return `The sneaky {propRole:FormatString("Props")} have survived!`
        end

        return `The evil {hunterRole:FormatString("Hunters")} have won!`
    end,

    EnableFriendlyFire = false,
    EnableKarma = false,

    AvailableItems = Items,
    AvailableAmmo = Ammo,

    InteractableDefinitions = Interactables,

    StartingItems = {},

    Duration = function()
		return 0
	end,

    Roles = roles,

    OnDeath = function(round, participant: Types.Participant, deferVictoryCheck: boolean)
        StandardGame.Highlights.OnDeath(round, participant)

        local corpse = participant.Corpse
        local attacker = if corpse then corpse.Killer else nil
        if attacker then
            awardScoreForKill(attacker, participant)
            killHighlights(attacker, participant)

            if attacker:GetRole().Definition == roles.Hunter and participant:GetRole().Definition == roles.Prop then
                attacker:AddCredits(1)
                round:SendMessage(attacker.Player, attacker:GetRole():GetFormattedName() .. ", you have been awarded 1 credit for your work.")
            end
        end

        if deferVictoryCheck then
            task.defer(tryFinishRound, participant.Round)
        else
            tryFinishRound(participant.Round)
        end
    end,

    AddFinishHighlights = function(round)
        StandardGame.Highlights.FinishHighlights(round)

        local victor = assert(round.VictoryData).Victor
        assert(victor.Kind == "Role")

        if victor.Definition == roles.Prop then
            local props = round:GetParticipantsWithRole(victor)

            local survivingProps = 0
            for _, prop in props do
                if prop:IsAlive() then
                    survivingProps += 1
                end
            end

            for _, prop in props do
                prop:AddScore("Surviving Props", 0.25 * survivingProps)
            end
        end
    end,

    OnStart = onStart,

    IsValidOnMap = isValidOnMap,

    BeforeDamageParticipant = beforeDamageParticipant,
    BeforeDamageProp = beforeDamageProp,

    UnloadGamemode = function(round): ()
        local map = round:GetMap()
        local platform = map.Structure.Dynamic:FindFirstChild("_PropHunt_Platform")

        if platform then
            platform:Destroy()
        end
    end
}

return gamemode