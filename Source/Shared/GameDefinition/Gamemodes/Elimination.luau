local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StandardHighlights = require(ReplicatedStorage.Shared.GameDefinition.Gamemodes.Common.StandardHighlights)
local C4 = require(ReplicatedStorage.Shared.GameDefinition.Interactables.C4)
local DeathStation = require(ReplicatedStorage.Shared.GameDefinition.Interactables.DeathStation)
local Decoy = require(ReplicatedStorage.Shared.GameDefinition.Interactables.Decoy)
local HealthStation = require(ReplicatedStorage.Shared.GameDefinition.Interactables.HealthStation)
local Radio = require(ReplicatedStorage.Shared.GameDefinition.Interactables.Radio)
local Visualiser = require(ReplicatedStorage.Shared.GameDefinition.Interactables.Visualiser)
local Ammo = require(script.Parent.Parent.Items.Ammo)
local Items = require(script.Parent.Parent.Items.Items)
local Types = require(script.Parent.Parent.Parent.RoundRule.Types)

local function getBestParticipant(_: unknown, round: Types.Round): Types.Participant
    local bestScore, bestParticipant: Types.Participant? = -math.huge, nil
    for _, participant in round:GetParticipants() do
        assert(participant)

        local totalScore = 0
        for _, v in participant.Scores do
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
        Description = "Free for all! Kill everyone.",
        Sound = "rbxassetid://9042088276",
        Color = Color3.fromRGB(255, 176, 7),

        IsBadGuys = true,

        Allegiance = {Kind = "Solo"},

        StartingItems = {Items.Radar},
        StartingCredits = 1,

        EquipmentShop = {
            Items["Ballistic Vest"],
            Items["HealthStation"],
            Items["Teleporter"],
            Items["Knife"],
            Items["Flare Gun"],
            Items.Flashbang,
            Items.AWP,
            Items["Newton Launcher"],
            Items["UMP"],
            Items["Poltergeist"],
            Items.BAR,
            Items["Radio"],
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
        round:Finish(survivor)
    else
        round:Finish(getBestParticipant(nil, round))
    end
end

local gamemode: Types.GamemodeDefinition = {
    Name = "Elimination",
    Description = "Last player standing wins",

    Authors = "@Scelly_Dog",

    MinimumPlayers = 1,

    TimeoutVictor = getBestParticipant,
    GetRoundEndMusic = getVictoryMusic,

    AssignRoles = function(gamemode: Types.GamemodeDefinition, participants: {Types.Participant})
        for _, v in participants do
            v:SetRole(roles.Competitor)
        end
    end,

    GetVictoryEventText = function(gamemode: Types.GamemodeDefinition, round: Types.Round, victor: Types.Victor, isTimeout: boolean): string?
        if isTimeout then
            return "The time has run out and the player with the highest score has won."
        end
        return if victor.Kind == "Participant" then victor:GetFormattedName() .. " has won the round!" else nil
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
        Radio = Radio,
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

    OnDeath = function(gamemode: Types.GamemodeDefinition, participant: Types.Participant, deferVictoryCheck: boolean)
        StandardHighlights.OnDeath(gamemode, participant, deferVictoryCheck)

        local corpse = participant.Corpse
        local attacker = if corpse then corpse.Killer else nil
        if attacker then
            if attacker == participant then
                attacker:AddScore("Suicide", -2)
            else
                attacker:AddScore("Killed Player", 1)
                if not participant.Round.Extras.AnyKillsHappened then
                    participant.Round.Extras.AnyKillsHappened = true
                    participant.Round:AddHighlight({
                        Title = "First Blood",
                        Description = attacker:GetFormattedName() .. " drew the first blood of the round.",
                        Priority = 2,
                        Group = "First Blood",
                    })
                end
            end
        end

        if deferVictoryCheck then
            task.defer(tryEndRound, participant.Round)
        else
            tryEndRound(participant.Round)
        end
    end,

    AddFinishHighlights = function(gamemode, round)
        StandardHighlights.FinishHighlights(gamemode, round)
        local mostKillsAmount, mostKillsParticipant: Types.Participant? = 0, nil
        for _, v in round:GetParticipants() do
            local count = #v.KillList
            if table.find(v.KillList, v) then
                count -= 1
            end

            if count > mostKillsAmount then
                mostKillsAmount = count
                mostKillsParticipant = v
            elseif count == mostKillsAmount then
                mostKillsParticipant = nil -- don't award if there is a tie
            end
        end

        if mostKillsParticipant then
            round:AddHighlight({
                Title = "Most Kills",
                Description = mostKillsParticipant:GetFormattedName() .. " scored the most kills this round.",
                Group = "Most Kills",
                Priority = 2,
            })
        end
    end,

    OnCharacterAdded = function() end,
}

return gamemode