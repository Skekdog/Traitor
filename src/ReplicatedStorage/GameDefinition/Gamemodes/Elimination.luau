local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ammo = require(script.Parent.Parent.Ammo)
local Items = require(script.Parent.Parent.Items)
local Types = require(script.Parent.Parent.Parent.RoundRule.Types)

local function getBestParticipant(gamemode: Types.Gamemode, round: Types.Round): Types.Participant
    local bestScore, bestParticipant: Types.Participant? = -1, nil
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
for _, v in ReplicatedStorage.VictoryMusic.Traitor:GetChildren() do
    if v:IsA("Sound") then
        table.insert(competitorVictoryMusic, v)
    end
end

local timeoutVictoryMusic: {Sound} = {}
for _, v in ReplicatedStorage.VictoryMusic.Timeout:GetChildren() do
    if v:IsA("Sound") then
        table.insert(timeoutVictoryMusic, v)
    end
end

local roles: {[string]: Types.RoleDefinition} = {
    Competitor = {
        Kind = "RoleDefinition",
        Name = "Competitor",
        Description = "It's you against the world. Kill them all.",
        Sound = "rbxassetid://9042088276",
        Color = Color3.fromRGB(255, 176, 7),

        Allegiance = {Kind = "Solo"},

        VictoryMusic = competitorVictoryMusic,
        VictoryText = "Everyone is dead!",

        StartingItems = {Items.Radar},
        StartingCredits = 1,

        EquipmentShop = {
            Items.Flashbang,
            Items.AWP,
            Items["Ballistic Vest"],
            Items.BAR,
            Items["Flare Gun"],
        },

        CanSeeMissingInAction = true,
        CanStealCreditsFromCorpses = true,

        AwardCreditsToRolesOnDeath = {},

        WalkSpeed = 16,
        JumpPower = 18,
        Health = 100,

        Accessories = {},

        DamageKarmaMultiplier = 1,

        RevealedRoles = {"Competitor"},
    }
}

local gamemode: Types.Gamemode = {
    Name = "Elimination",
    Description = "Last player standing wins",

    Authors = "@Scelly_Dog",

    MinimumPlayers = 1,

    DefaultVictor = getBestParticipant,
    TimeoutVictor = getBestParticipant,
    TimeoutMusic = timeoutVictoryMusic,

    AssignRoles = function(gamemode: Types.Gamemode, participants: {Types.Participant})
        for _, v in participants do
            v:SetRole(roles.Competitor)
        end
    end,

    EnableFriendlyFire = true,
    EnableKarma = false,

    AvailableItems = Items,
    AvailableAmmo = Ammo,

    StartingItems = {Items.Crowbar},

    Duration = function(numParticipants: number)
        return 0 + 10 * numParticipants
    end,

    Roles = roles,

    OnDeath = function(gamemode: Types.Gamemode, participant: Types.Participant)
        local survivor: Types.Participant?
        for _, v in participant.Round:GetParticipants() do
            assert(v)
            if v:IsAlive() then
                if survivor then
                    return
                end
                survivor = v
            end
        end

        if survivor then
            participant.Round:EndRound(survivor)
        else
            participant.Round:EndRound(getBestParticipant(gamemode, participant.Round))
        end
    end,

    OnCharacterAdded = function() end,
}

return gamemode