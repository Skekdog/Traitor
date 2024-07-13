local ReplicatedFirst = game:GetService("ReplicatedFirst")
-- Not a Gamemode, but contains some useful functions that are used by multiple Gamemodes.
-- Not a part of the standard implementation, can be removed to your tastes.

local Types = require(ReplicatedFirst.RoundHandler.Types)

local module = {}

function module.TestForOneSurvivingRole(self: Types.Gamemode, round: Types.Round): string?
    local allegiances: {string} = {}
    for _, v in self.Roles do
        if not table.find(allegiances, v.Allegiance or v.Name) then
            table.insert(allegiances, v.Allegiance or v.Name)
        end
    end

    if #allegiances ~= 2 then
        error("TestForOneSurvivingRole Victory Checker only works if there are 2 teams!")
    end

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
    end
    return allegiances[2]
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