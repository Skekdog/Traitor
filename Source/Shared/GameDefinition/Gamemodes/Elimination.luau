local ReplicatedStorage = game:GetService("ReplicatedStorage")
local C4 = require(ReplicatedStorage.Shared.GameDefinition.Interactables.C4)
local DeathStation = require(ReplicatedStorage.Shared.GameDefinition.Interactables.DeathStation)
local Decoy = require(ReplicatedStorage.Shared.GameDefinition.Interactables.Decoy)
local HealthStation = require(ReplicatedStorage.Shared.GameDefinition.Interactables.HealthStation)
local Visualiser = require(ReplicatedStorage.Shared.GameDefinition.Interactables.Visualiser)
local Ammo = require(script.Parent.Parent.Items.Ammo)
local Items = require(script.Parent.Parent.Items.Items)
local Types = require(script.Parent.Parent.Parent.RoundRule.Types)

local function getBestParticipant(_: unknown, round: Types.Round): Types.Participant
    local bestScore, bestParticipant: Types.Participant? = -math.huge, nil
    for _, participant in round:GetParticipants() do
        assert(participant)

        local totalScore = 0
        for _, v in participant:GetScores() do
            assert(v)
            totalScore += v
        end

        if totalScore > bestScore then
            bestScore = totalScore
            bestParticipant = participant
        end
    end

    return bestParticipant or error("No participants in round")
end

local competitorVictoryMusic: {Sound} = {}
for _, v in ReplicatedStorage.Assets.VictoryMusic.Traitor:GetChildren() do
    if v:IsA("Sound") then
        table.insert(competitorVictoryMusic, v)
    end
end

local timeoutVictoryMusic: {Sound} = {}
for _, v in ReplicatedStorage.Assets.VictoryMusic.Timeout:GetChildren() do
    if v:IsA("Sound") then
        table.insert(timeoutVictoryMusic, v)
    end
end

local function getVictoryMusic(_, round: Types.Round, victor: Types.Victor, isTimeout: boolean): Sound
    if isTimeout then
        return timeoutVictoryMusic[math.random(#timeoutVictoryMusic)]
    end
    return competitorVictoryMusic[math.random(#competitorVictoryMusic)]
end

local roles: {[string]: Types.RoleDefinition} = {
    Competitor = {
        Kind = "RoleDefinition",
        Name = "Competitor",
        Description = "It's you against the world. Kill them all.",
        Sound = "rbxassetid://9042088276",
        Color = Color3.fromRGB(255, 176, 7),

        IsBadGuys = true,

        Allegiance = {Kind = "Solo"},

        VictoryText = "Everyone is dead!",

        StartingItems = {Items.Radar},
        StartingCredits = 1,

        EquipmentShop = {
            Items.Flashbang,
            Items.AWP,
            Items["Ballistic Vest"],
            Items.BAR,
            Items["Flare Gun"],
            Items["Newton Launcher"],
            Items["UMP"],
            Items["Poltergeist"],
            Items["HealthStation"],
            Items["Teleporter"],
            Items["Knife"],
        },

        CanSeeMissingInAction = true,
        CanStealCreditsFromCorpses = true,

        RevealedRoles = {"Competitor"},
    }
}

local function tryEndRound(round: Types.Round): ()
    if not round:IsInProgress() then
        return
    end

    local survivor: Types.Participant?
    for _, v in round:GetParticipants() do
        assert(v)
        if v:IsAlive() then
            if survivor then
                return
            end
            survivor = v
        end
    end

    if survivor then
        round:EndRound(survivor)
    else
        round:EndRound(getBestParticipant(nil, round))
    end
end

local gamemode: Types.Gamemode = {
    Name = "Elimination",
    Description = "Last player standing wins",

    Authors = "@Scelly_Dog",

    MinimumPlayers = 1,

    TimeoutVictor = getBestParticipant,
    GetRoundEndMusic = getVictoryMusic,

    AssignRoles = function(gamemode: Types.Gamemode, participants: {Types.Participant})
        for _, v in participants do
            v:SetRole(roles.Competitor)
        end
    end,

    EnableFriendlyFire = true,
    EnableKarma = false,

    AvailableItems = Items,
    AvailableAmmo = Ammo,

    InteractableDefinitions = {
        C4 = C4.Interactable,
        HealthStation = HealthStation.Interactable,
        DeathStation = DeathStation,
        Decoy = Decoy.Interactable,
        Visualiser = Visualiser,
    },

    StartingItems = {Items.Crowbar, Items["Magneto Stick"]},

    Duration = function(numParticipants: number)
		return 120 + 10 * numParticipants
	end,

    Roles = roles,

    DeathSounds = {
		"rbxassetid://9125652432",
		"rbxassetid://9125651099",
		"rbxassetid://9125651607",
		"rbxassetid://9125652452",
		"rbxassetid://9125651373",
		"rbxassetid://9125652147",
		"rbxassetid://9125652675"
	},

    OnDeath = function(gamemode: Types.Gamemode, participant: Types.Participant, deferVictoryCheck: boolean)
        local corpse = participant:GetCorpse()
        local attacker = if corpse then corpse.Killer else nil
        if attacker then
            if attacker == participant then
                attacker:AddScore("Suicide", -2)
            else
                attacker:AddScore("Killed Player", 1)
            end
        end

        if deferVictoryCheck then
            task.defer(tryEndRound, participant.Round)
        else
            tryEndRound(participant.Round)
        end
    end,

    OnCharacterAdded = function() end,
}

return gamemode