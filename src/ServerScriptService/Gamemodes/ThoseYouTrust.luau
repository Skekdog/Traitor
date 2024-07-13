local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedFirst.RoundHandler.Types)
local common = require(script.Parent.Common)

local items = ReplicatedStorage.WeaponModels

local module: Types.Gamemode = {
    Name = "Those You Trust",
    Description = "Spy HQ has been infiltrated by Traitor spies. Can you separate those you trust, from those you shouldn't?",
    Authors = "@Scelly_Dog, Bad King Urgrain",

    EngineVersion = "0.0.1",

    MinimumPlayers = 1,
    RecommendedPlayers = 4,
    MaximumPlayers = 32,
    
    TimeoutVictors = "Innocent",
    TimeoutMusic = ReplicatedStorage.VictoryMusic.Timeout:GetChildren() :: any,
    PhyrricVictors = "Traitor",

    CalculateRoundHighlights = function(self, round)
        local weaponList = common.GetWeaponHighlights(round.EventLog)
        local highlights: {Types.RoundHighlight} = {}

        table.move(weaponList, 1, #weaponList, 1, highlights)

        local deathLog = round.EventLog.Death
        local firstKill: Types.RoundEvent_Death?
        local eventIndex = 0

        local suiciders = {}
        for _, v in deathLog do
            if v.Data.Attacker == v.Data.Victim then
                table.insert(suiciders, v.Data.Attacker :: Types.Participant)
            end
        end

        table.sort(suiciders, function(a, b)
            return a.KilledAt < b.KilledAt
        end)

        if #suiciders > 0 then
            if #suiciders == 1 then
                table.insert(highlights, {
                    Name = "Lonely and Sad",
                    Description = `{suiciders[1].FormattedName} was the only one to kill themselves.`
                })
            else
                table.insert(highlights, {
                    Name = "Suicide Cult Leader",
                    Description = `{suiciders[1].FormattedName} showed the other suiciders how to do it by being the first to go.`
                })
            end
        end

        while (eventIndex < #deathLog) and (not firstKill) do
            eventIndex += 1
            local log = deathLog[eventIndex]
            if not log then
                break
            end

            local data = log.Data
            if data.Attacker and data.Attacker ~= data.Victim then
                firstKill = deathLog[eventIndex].Data
                break
            end
        end
        
        if firstKill then
            assert(firstKill.Attacker)
            local aRole = firstKill.Attacker.Role.Allegiance
            local vRole = firstKill.Victim.Role.Allegiance

            local attackerName = firstKill.Attacker.FormattedName
            if (aRole == "Traitor") and (vRole == "Traitor") then
                table.insert(highlights, {
                    Name = "First Bloody Stupid Kill",
                    Description = `{attackerName} scored the first kill by shooting a fellow traitor. Good job.`
                })
            elseif (aRole == "Innocent") and (vRole == "Traitor") then
                table.insert(highlights, {
                    Name = "First Blow",
                    Description = `{attackerName} struck the first blow for the innocents by making the first death a traitor's.`
                })
            elseif ((aRole == "Innocent") and (vRole == "Innocent")) and ((not firstKill.SelfDefense) and (not firstKill.FreeKill)) then
                table.insert(highlights, {
                    Name = "First Blooper",
                    Description = `{attackerName} was the first to kill. Too bad it was an innocent comrade.`
                })
            elseif (aRole == "Traitor") and (vRole == "Innocent") then
                table.insert(highlights, {
                    Name = "First Blood",
                    Description = `{attackerName} delivered the first innocent death at a traitor's hands.`
                })
            end
        end

        local mostAllyKills: {any} = {"", 0} -- username, amount
        local mostEnemyKills: {any} = {"", 0} -- username, amount
        for _, participant in round.Participants do
            local allyKills = 0
            local enemyKills = 0
            for _, kill in participant.KillList do
                if kill == participant then
                    continue
                end
                if not kill.KilledInSelfDefense and round:IsRoleAlliedWith(participant.Role, kill.Role) then
                    allyKills += 1
                else
                    enemyKills += 1
                end
            end

            if allyKills > mostAllyKills[2] then
                mostAllyKills = {participant.FormattedName, allyKills}
            end
            if enemyKills > mostEnemyKills[2] then
                mostEnemyKills = {participant.FormattedName, enemyKills}
            end
        end

        if mostAllyKills[2] > 3 then
            table.insert(highlights, {
                Name = "Roleplayer",
                Description = `{mostAllyKills[1]} was role-playing a madman, honest. That's why they killed most of their team.`
            })
        elseif mostAllyKills[2] == 2 then
            table.insert(highlights, {
                Name = "Double Oops",
                Description = `{mostAllyKills[1]} had their finger "slip" twice when they were just aiming at a "buddy".`
            })
        elseif mostAllyKills[2] == 1 then
            table.insert(highlights, {
                Name = "Butterfingers",
                Description = `{mostAllyKills[1]} had their finger slip when they were just aiming at a buddy.`
            })
        end

        return highlights
    end,

    FriendlyFire = true,
    SelfDefense = true,
    UseKarma = true,

    StartingEquipment = {"Crowbar", "Magneto Stick", "Grenade", "Flashbang", "Discombobulator"},
    AvailableEquipment = {
        {
            Name = "Crowbar",
            Icon = "rbxassetid://",
            AttackType = "Blunt",

            Item = items.Crowbar
        },
        {
            Name = "Magneto Stick",
            Icon = "rbxassetid://",

            Item = items["Magneto Stick"]
        },
        {
            Name = "Newton Launcher",
            Icon = "rbxassetid://",

            Item = items["Newton Launcher"]
        },
        {
            Name = "Pistol",
            Icon = "rbxassetid://",
            AttackType = "Firearm",

            Item = items.Pistol
        },
        {
            Name = "BAR",
            Icon = "rbxassetid://",
            AttackType = "Firearm",

            Item = items.BAR
        },
        {
            Name = "Assault Rifle",
            Icon = "rbxassetid://",
            AttackType = "Firearm",

            Item = items["Assault Rifle"]
        },
        {
            Name = "XM1014",
            Icon = "rbxassetid://",
            AttackType = "Firearm",

            Item = items.XM1014
        },
        {
            Name = "Golden Gun",
            Description = "Instant kills if the death is justified. Otherwise - bad luck.",
            Icon = "rbxassetid://10282780102",
            Cost = 1,
            AttackType = "Firearm",
            MaxStock = 1,

            Item = items["Golden Gun"]
        },
        {
            Name = "Flare Gun",
            Description = "Sets fire to anyone it hits. Can be used to incinerate corpses, hiding evidence.",
            Icon = "rbxassetid://444145395",
            AttackType = "Firearm",
            MaxStock = 1,
            Cost = 1,

            Item = items["Flare Gun"]
        },
        {
            Name = "Grenade",
            Description = "Explodes in a decent radius after a few seconds.",
            Cost = 2,
            Icon = "rbxassetid://8096856961",
            MaxStock = 1,
            AttackType = "Explosion",

            Item = items.Grenade
        },
        {
            Name = "Smoke Grenade",
            Icon = "rbxassetid://8096856961",

            Item = items["Smoke Grenade"]
        },
        {
            Name = "Incendiary Grenade",
            Icon = "rbxassetid://8096856961",
            AttackType = "Explosion",

            Item = items["Incendiary Grenade"]
        },
        {
            Name = "Discombobulator",
            Icon = "rbxassetid://8096856961",

            Item = items.Discombobulator
        },
        {
            Name = "Grenade",
            Description = "Explodes in a decent radius after a few seconds.",
            Cost = 2,
            Icon = "rbxassetid://8096856961",
            MaxStock = 1,
            AttackType = "Explosion",

            Item = items.Grenade
        },
        {
            Name = "Flashbang",
            Description = "Blinds and deafens anyone in range.",
            Cost = 1,
            Icon = "rbxassetid://10753198321",
            MaxStock = 2,
            Item = items.Flashbang,
        },
        {
            Name = "Radar",
            Description = "Reveals the location of all living players every 30 seconds.",
            Cost = 1,
            Icon = "rbxassetid://62159372",
            MaxStock = 1,

            Item = function() end,
        }
    } :: {Types.Equipment},

    Roles = {
        {
            Kind = "Role",
            Name = "Traitor",
            FormattedName = "<font color='#ff0000'>Traitor</font>",
            Description = "Work with the other Traitors to defeat all the Innocents. Keep your role secret.",
            Colour = Color3.new(1, 0, 0),
            Extras = {
                AssignmentProportion = 0.25,
                AssignmentPriority = 1,
                Sound = 9042088276,
            },

            Allies = {"Traitor"},
            VictoryMusic = ReplicatedStorage.VictoryMusic.Traitor:GetChildren() :: any,
            VictoryText = "The dastardly traitors have won the round!",

            AnnounceDisconnect = true,
            CanStealCredits = true,
            AwardOnDeath = {
                Detective = 1,
            },

            StartingCredits = 2,
			EquipmentShop = {"Radar", "Flare Gun", "Grenade", "Flashbang"},
			CanSeeMissing = true,

            HighlightRoles = {"Traitor"},
            KnowsRoles = {"Traitor", "Detective"},
            TeamChat = true,
        },
        {
            Kind = "Role",
            Name = "Detective",
            FormattedName = "<font color='#0000ff'>Detective</font>",
            Description = "Work with the Innocents to identify the Traitors.",
            Colour = Color3.new(0, 0, 1),
            Extras = {
                AssignmentProportion = 0.125,
                AssignmentPriority = 2,
                Sound = 9042823666,
            },

            Allies = {"Innocent", "Detective"},
            Allegiance = "Innocent",

            AnnounceDisconnect = true,
			CanStealCredits = true,
            AwardOnDeath = {
                Traitor = 1,
            },
            CorpseResultsPublicised = true,

            StartingCredits = 2,
            EquipmentShop = {"Radar", "Golden Gun", "Flashbang", "Grenade"},

            KnowsRoles = {"Detective"},
        },
        {
            Kind = "Role",
            Name = "Innocent",
            FormattedName = "<font color='#00ff00'>Innocent</font>",
            Description = "Survive the Traitors.",
            Colour = Color3.new(0, 1, 0),
            Extras = {
                AssignmentProportion = 0.625,
                AssignmentPriority = 3,
                Sound = 9042819926,
            },

            Allies = {"Detective", "Innocent"},
            VictoryMusic = ReplicatedStorage.VictoryMusic.Innocent:GetChildren() :: any,
            VictoryText = "The loveable innocents have won the round!",
            KnowsRoles = {"Detective"},
        }
    },

    AssignRoles = function(self, participants)
        -- Participants are already shuffled, no need to do it here
        local roles = self.Roles

        if false then return participants[1]:AssignRole(roles[2]) end
        -- Sort roles by lowest AssignmentPriority. These roles will be assigned first.
        -- The greatest value for AssignmentPriority is used as a backup role for anyone who did not receive their role.
        -- Lower AssignmentPriority values will be used first, if there are not enough players for a proper round.
        -- e.g, Traitor will be assigned first, then detective. In a one player server, there will only be a Traitor.
        table.sort(roles, function(role1, role2)
            assert(role1.Extras and role2.Extras) -- Extras is not standard, but this gamemode also isn't standard.
            return role1.Extras.AssignmentPriority < role2.Extras.AssignmentPriority
        end)
        
        local roleToAssign, roleToAssignIndex = roles[1], 1
        local total, subtractFromI = #participants, 0
        for i, v in participants do
            assert(roleToAssign.Extras) -- Extras is still not standard, but this gamemode also still isn't standard.
            
            -- The greatest AssignmentPriority is used as a bargain bin, anyone who wasn't assigned to the other roles gets assigned here
            if ((i - subtractFromI) > math.max(total * roleToAssign.Extras.AssignmentProportion, 1)) and roleToAssignIndex < #roles then
                -- If we have already assigned enough people to this role, start assigning to the next role
                
                roleToAssignIndex += 1
                roleToAssign = roles[roleToAssignIndex] -- Go to the next role
                subtractFromI = i - 1 -- Start counting for how many people to assign from where we start assigning. -1 because lua is 1-indexed
            end
            v:AssignRole(roleToAssign) -- Hand it over to the module to assign the role
        end
    end,

    OnDeath = function(self, victim)
        local round = victim.Round
        if round:IsRoundOver() then
            return
        end

        local winner = common.TestForOneSurvivingRole(self, round)
        if winner then
            round:EndRound(round:GetRoleFromName(winner))
        end
    end,
    
    Duration = function(self, numParticipants)
        return 10 + (numParticipants * 10)
    end,

    OnCharacterLoad = function(self, char)
        local healthScript = char:FindFirstChild("Health")
        if healthScript then
            healthScript:Destroy()
        end
    end
}

return module