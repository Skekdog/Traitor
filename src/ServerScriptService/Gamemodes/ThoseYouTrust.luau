--!strict
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
    PhyrricVictors = "Traitor",

    CalculateRoundHighlights = function(self, round)
        local weaponList = common.GetWeaponHighlights(round.EventLog)
        local highlights: {Types.RoundHighlight} = {}
        
        for equipmentName, v in weaponList do
            if true then continue end
            if not v then
                continue
            end
            local username = v[1]
            local amount = v[2]

            local name = ""
            local description = ""

            if not amount or amount < 2 then
                continue
            end

            if equipmentName == "Crowbar" then
                if amount >= 4 then
                    name = "Gordonite"
                    description = `{username} smeared their Crowbar in the brains of no less than {amount} people.`
                else
                    name = "It's like a crow's beak"
                    description = `{username} thought their Crowbar looked funny and showed it to {amount} people.`
                end
            elseif equipmentName == "Pistol" then
                if amount >= 4 then
                    name = "Persistent Little Bugger"
                    description = `{username} scored {amount} kills with their pistol. They then went on and hugged someone to death.`
                else
                    name = "Small Arms Slaughter"
                    description = `{username} killed a small army of {amount} using only their pistol. Presumably had a tiny shotgun installed in the barrel.`
                end
            end

            table.insert(highlights, {
                Name = name,
                Description = description
            })
        end

        local deathLog = round.EventLog.Death
        local firstKill: Types.RoundEvent_Death?
        local eventIndex = 0

        while (eventIndex < #deathLog) and (not firstKill) do
            eventIndex += 1
            if deathLog[eventIndex] and deathLog[eventIndex].Data.Attacker then
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

    StartingEquipment = {"Crowbar", "Pistol", "BAR", "Magneto Stick"},
    AvailableEquipment = {
        {
            Name = "Crowbar",
            Description = "Become a Gordonite",
            Icon = "rbxassetid://",
            AttackType = "Blunt",

            Item = items.Crowbar
        },
        {
            Name = "Magneto Stick",
            Description = "Haha props",
            Icon = "rbxassetid://",

            Item = items["Magneto Stick"]
        },
        {
            Name = "Newton Launcher",
            Description = "Haha props",
            Icon = "rbxassetid://",

            Item = items["Newton Launcher"]
        },
        {
            Name = "Pistol",
            Description = "Reliable",
            Icon = "rbxassetid://",
            AttackType = "Firearm",

            Item = items.Pistol
        },
        {
            Name = "BAR",
            Description = "Reliable",
            Icon = "rbxassetid://",
            AttackType = "Firearm",

            Item = items.BAR
        },
        {
            Name = "Assault Rifle",
            Description = "pewpewpew",
            Icon = "rbxassetid://",
            AttackType = "Firearm",

            Item = items["Assault Rifle"]
        },
        {
            Name = "XM1014",
            Description = "bang bang bang",
            Icon = "rbxassetid://",
            AttackType = "Firearm",

            Item = items.XM1014
        },
        {
            Name = "Golden Gun",
            Description = "One shot. Don't fumble it.",
            Icon = "rbxassetid://10282780102",
            AttackType = "Firearm",
            MaxStock = 1,

            Item = items["Golden Gun"]
        },
        {
            Name = "Flare Gun",
            Description = "Ouch fire hot.",
            Icon = "rbxassetid://",
            AttackType = "Firearm",
            MaxStock = 1,

            Item = items["Flare Gun"]
        },
        {
            Name = "Grenade",
            Description = "Boom",
            Cost = 1,
            Icon = "rbxassetid://8096856961",
            MaxStock = 1,
            AttackType = "Explosion",

            Item = items.Grenade
        },
        {
            Name = "Radar",
            Description = "Beep... beep... beep",
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
            Allegiance = "Traitor",
            VictoryMusic = ReplicatedStorage.VictoryMusic.Traitor:GetChildren() :: any,
            VictoryText = "The dastardly traitors have won the round!",

            AnnounceDisconnect = true,
            CanStealCredits = true,
            AwardOnDeath = {
                Detective = 1,
            },

            StartingCredits = 2,
			EquipmentShop = {"Grenade", "Radar", "Flare Gun"},
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
            EquipmentShop = {"Radar", "Golden Gun"},

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
            Allegiance = "Innocent",
            VictoryMusic = ReplicatedStorage.VictoryMusic.Innocent:GetChildren() :: any,
            VictoryText = "The loveable innocents have won the round!",
            KnowsRoles = {"Detective"},
        }
    },

    AssignRoles = function(self, participants)
        -- Participants are already shuffled, no need to do it here
        local roles = self.Roles
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