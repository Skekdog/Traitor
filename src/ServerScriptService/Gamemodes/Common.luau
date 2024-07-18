local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Not a Gamemode, but contains some useful functions that are used by multiple Gamemodes.
-- Not a part of the standard implementation, can be removed to your tastes.

local Types = require(ReplicatedFirst.RoundHandler.Types)

local module = {}

local items = ReplicatedStorage.WeaponModels

module.Equipment = {
    {
        Name = "Crowbar",
        AttackType = "Blunt",

        Item = items.Crowbar
    },
    {
        Name = "Magneto Stick",
        Item = items["Magneto Stick"]
    },
    {
        Name = "Pistol",
        AttackType = "Firearm",

        Item = items.Pistol
    },
    {
        Name = "BAR",
        AttackType = "Firearm",

        Item = items.BAR
    },
    {
        Name = "Assault Rifle",
        AttackType = "Firearm",

        Item = items["Assault Rifle"]
    },
    {
        Name = "XM1014",
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
        Name = "Smoke Grenade",
        Icon = "rbxassetid://8096856961",

        Item = items["Smoke Grenade"]
    },
    {
        Name = "Incendiary Grenade",
        Icon = "rbxassetid://8096856961",
        AttackType = "Explosion",
        NoDNA = true,

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
        NoDNA = true,

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
    },
    {
        Name = "DNA Scanner",
        Description = "scan",
        Item = items["DNA Scanner"]
    },
    {
        Name = "SMG",
        AttackType = "Firearm",

        Item = items["SMG"]
    },
    {
        Name = "Deagle",
        AttackType = "Firearm",

        Item = items["Deagle"]
    },
    {
        Name = "Glock",
        AttackType = "Firearm",

        Item = items["Glock"]
    },
    {
        Name = "Silenced Pistol",
        AttackType = "Firearm",
        Description = "A pistol that has been fitted with a suppressor. People killed with silenced weapons will not scream.",
        Icon = "rbxassetid://299432421",

        Cost = 1,
        MaxStock = 2,

        Item = items["Silenced Pistol"]
    },
    {
        Name = "AWP",
        AttackType = "Firearm",
        Description = "A high-powered sniper rifle that must be scoped in to shoot. Cannot be reloaded.",
        Icon = "rbxassetid://4772214897",

        Cost = 1,
        MaxStock = 2,

        Item = items["AWP"]
    },
    { -- todo: implement this
        Name = "Knife",
        AttackType = "Blade",
        Description = "Instantly and silently kills the target. Can be thrown with Alternate Fire.",
        Icon = "rbxassetid://",

        Cost = 1,
        MaxStock = 2,

        Item = items["Knife"]
    },
    {
        Name = "Scout",
        AttackType = "Firearm",

        Item = items["Scout"]
    },
    {
        Name = "HUGE",
        AttackType = "Firearm",

        Item = items["HUGE"]
    },
} :: {Types.Equipment}

function module.GetDefaultHighlights(round: Types.Round): (Types.RoundEvent_Death?, {Types.RoundHighlight})
    local weaponList = module.GetWeaponHighlights(round.EventLog)
    local highlights: {Types.RoundHighlight} = {}

    table.move(weaponList, 1, #weaponList, 1, highlights)

    local deathLog = round.EventLog.Death
    local firstKill: Types.RoundEvent<Types.RoundEvent_Death>?

    local suiciders = {}
    for _, v in deathLog do
        if v.Data.Attacker == v.Data.Victim then
            table.insert(suiciders, v.Data.Attacker :: Types.Participant)
        elseif v.Data.Attacker and not v.Data.SelfDefense and (not firstKill or v.Timestamp < firstKill.Timestamp) then
            firstKill = v
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

    return if firstKill then firstKill.Data else nil, highlights
end

function module.TestForOneSurvivingRole(self: Types.Gamemode, round: Types.Round): string?
    local allegiances: {string} = {}
    for _, v in self.Roles do
        if not table.find(allegiances, v.Allegiance or v.Name) then
            table.insert(allegiances, v.Allegiance or v.Name)
        end
    end

    assert(#allegiances == 2, "TestForOneSurvivingRole Victory Checker requires 2 teams!")
    assert(self.PhyrricVictors, "TestForOneSurvivingRole Victory Checker requires PhyrricVictors to be set.")

    local function checkAlive(participant: Types.Participant)
        -- Remember what they took from you: https://github.com/luau-lang/luau/pull/501
        local plr = participant.Player
        if not plr then return false end
        local char = plr.Character
        if not char then return false end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return false end
        return hum.Health > 0
    end

    local rolesAlive = {
        [allegiances[1]] = false,
        [allegiances[2]] = false,
    }
    for _, v in round.Participants do
        if checkAlive(v) then
            rolesAlive[v.Role.Allegiance or v.Role.Name] = true
        end
        if rolesAlive[allegiances[1]] and rolesAlive[allegiances[2]] then
            return nil -- Both roles are still alive, nobody wins yet
        end
    end

    if rolesAlive[allegiances[1]] then
        return allegiances[1]
    elseif rolesAlive[allegiances[2]] then
        return allegiances[2]
    else
        return self.PhyrricVictors
    end
end

function module.GetWeaponHighlights(roundEvents: Types.RoundEventLog): {Types.RoundHighlight}
    local deathEvents = roundEvents.Death
    if not deathEvents then
        return {}
    end

    local data: {[Types.EquipmentName]: {[Types.Participant]: number?}?} = {}
    for _, v in deathEvents do
        local attacker = v.Data.Attacker
        local weapon = v.Data.Weapon

        if not attacker or typeof(weapon) ~= "table" then
            continue
        end

        local thisData = data[weapon.Name]
        if not thisData then
            data[weapon.Name] = {}
            thisData = data[weapon.Name]
        end
        assert(thisData)
        
        thisData[attacker] = (thisData[attacker] or 0) + 1
    end

    local results: {[Types.EquipmentName]: {Participant: Types.Participant, Kills: number}} = {}
    for i, v in data do
        assert(v)

        results[i] = {Participant = nil :: any, Kills = 0}

        local ranOnce = false
        for participant, kills in v do
            assert(kills)

            if kills < 2 then
                continue
            end

            if kills > results[i].Kills then
                results[i] = {
                    Participant = participant,
                    Kills = kills,
                }
                ranOnce = true
            end
        end

        if not ranOnce then
            results[i] = nil
        end
    end

    local highlights: {Types.RoundHighlight} = {}
    for i, v in results do
        local participant = v.Participant.FormattedName
        local amount = v.Kills

        local name: string?, description: string?

        if i == "Crowbar" then
            if amount >= 4 then
                name = "Gordonite"
                description = `{participant} smeared their Crowbar in the brains of no less than {amount} people.`
            else
                name = "It's like a crow's beak"
                description = `{participant} thought their Crowbar looked funny and showed it to {amount} people.`
            end
        elseif i == "Pistol" then
            if amount >= 4 then
                name = "Small Arms Slaughter"
                description = `{participant} killed a small army of {amount} using only their pistol. Presumably had a tiny shotgun installed in the barrel.`
            else
                name = "Persistent Little Bugger"
                description = `{participant} scored {amount} kills with their pistol. They then went on and hugged someone to death.`
            end
        end

        if not name or not description then
            continue
        end

        table.insert(highlights, {
            Name = name,
            Description = description,
        })
    end

    return highlights
end

return module