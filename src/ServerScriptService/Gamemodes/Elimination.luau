local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Common = require(script.Parent.Common)
local Types = require(ReplicatedFirst.RoundHandler.Types)

local function determineWinnerByScore(self: Types.Gamemode, round: Types.Round): Types.Victor
    local bestScore: number, bestPlayer: Types.Participant? = 0, nil
    for _, v in round.Participants do
        local kills = v.Score.Kills
        if kills and kills > bestScore then
            bestScore = kills
            bestPlayer = v
        end
    end

    return bestPlayer or self.Roles[1]
end

local module: Types.Gamemode = {
    Name = "Elimination",
    Description = "It's every man for himself.",
    Authors = "@Scelly_Dog",

    EngineVersion = "0.0.1",

    MinimumPlayers = 1,
    RecommendedPlayers = 3,
    MaximumPlayers = 32,
    
    TimeoutVictors = determineWinnerByScore,
    PhyrricVictors = "Competitor",
    TimeoutMusic = ReplicatedStorage.VictoryMusic.Timeout:GetChildren() :: any,
    
    CalculateRoundHighlights = function(self, round)
        local firstKill, highlights = Common.GetDefaultHighlights(round)

        if firstKill then
            assert(firstKill.Attacker)
            table.insert(highlights, {
                Name = "First Blood",
                Description = `{firstKill.Attacker.FormattedName} drew the first blood.`
            })
        end

        return highlights
    end,

    FriendlyFire = true,
    SelfDefense = false,
    UseKarma = false,

    StartingCredits = 1,
    StartingEquipment = {"Crowbar", "Magneto Stick"},
    AvailableEquipment = Common.Equipment,

    Roles = {
        {
            Kind = "Role",
            Name = "Competitor",
            FormattedName = "<font color='#808000'>Competitor</font>",
            Description = "Kill them all.",
            Colour = Color3.fromHex("#808000"),
            Extras = {
                Sound = 9042088276,
            },

            CanSeeMissing = true,
            CanStealCredits = true,
            CorpseResultsPublicised = true,

            VictoryMusic = ReplicatedStorage.VictoryMusic.Traitor:GetChildren() :: any,
            VictoryText = "The round has ended.",

            EquipmentShop = {"Grenade", "Flashbang", "Flare Gun", "AWP"},
            StartingEquipment = {"Radar"},

            KnowsRoles = {"Competitor"},
        }
    },

    Duration = 180,
    OnDeath = function(self, victim)
        local survivor: Types.Participant?, moreThanOneSurvivor = nil, false
        for _, v in victim.Round.Participants do
            if not v:IsDead() then
                if survivor then
                    moreThanOneSurvivor = true
                    break
                else
                    survivor = v
                end
            end
        end

        local attacker = victim.KilledByParticipant
        if attacker and attacker ~= victim then
            attacker:AddScore("Kills", 1)
        end

        if not moreThanOneSurvivor then
            victim.Round:EndRound(survivor or determineWinnerByScore(self, victim.Round))
        end
    end,

    OnCharacterLoad = function(self, char)
        local healthScript = char:FindFirstChild("Health")
        if healthScript then
            healthScript:Destroy()
        end
    end,

    AssignRoles = function(self, participants)
        for _, participant in participants do
            participant:AssignRole(self.Roles[1])
        end
    end,
}

return module