-- Implementation-dependent functions that *should* be customised.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local InventoryManager = require(script.Parent.Parent.ReplicatedFirst.InventoryManager)
local Weapons = require(script.Parent.Parent.ReplicatedFirst.WeaponsManager.Weapons)
local UpdateRoundInfo = require(script.Parent.UpdateRoundInfo)
local ProfileService = require(ServerScriptService.PlayerSetup.ProfileService)
local Types = require(ReplicatedFirst.RoundHandler.Types)

local getProfile = ServerScriptService.PlayerSetup.GetProfile
local updateProfile = ServerScriptService.PlayerSetup.UpdateProfile

local remotes = ReplicatedStorage.RoundHandler

local vowels = {"a", "e", "i", "o", "u"}
local function stringWithDeterminer(str: string): string
    local lowered = str:lower()

    local determiner = "a "
    if table.find(vowels, lowered:sub(1)) then
        determiner = "an "
    end

    return determiner..str
end

local ProfileStore = ProfileService.GetProfileStore("GameData_v2", {Version = "0.0.0"})

local deathsounds = {
	"9125652432",
	"9125651099",
	"9125651607",
	"9125652452",
	"9125651373",
	"9125652147",
	"9125652675",
}

local module: Types.Adapter = {
    HIGHLIGHTS_TIME = 10, -- Time to spend after the round ends before destroying the round
    PREPARING_TIME = 5, -- Time to spend after a round is created where players can join the round
    SLAY_VOTES = 2, -- Minimum number of votes to slay someone, at which point they will be slain
    INTERMISSION_TIME = 10,
    LOAD_LIGHTING_SETTINGS = true,
    LOAD_TERRAIN_SETTINGS = true,
    BOUNDS_COLLISION_GROUP = "Bounds",

    SetDefaultLighting = function()
        Lighting.Ambient = Color3.fromRGB(70, 70, 70)
        Lighting.Brightness = 3
        Lighting.ClockTime = 14.5
        Lighting.ColorShift_Bottom = Color3.new()
        Lighting.ColorShift_Top = Color3.new()
        Lighting.EnvironmentDiffuseScale = 1
        Lighting.EnvironmentSpecularScale = 1
        Lighting.ExposureCompensation = 0
        Lighting.FogColor = Color3.fromRGB(192, 192, 192)
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        Lighting.GeographicLatitude = 0
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)

        Lighting:ClearAllChildren()
    end,

    DoIntermission = function()
        local roundNumber = (ServerStorage:GetAttribute("RoundNumber") or -1) + 1 -- or -1, because +1, so then == 0, so % 5 == 0.
        ServerStorage:SetAttribute("RoundNumber", roundNumber)
        if roundNumber % 2 == 0 then
            -- also enable map voting here, or whatever
            return true
        end
        return false
    end,

    GiveEquipment = function(participant, item)
        -- Gives an item to a player. If the item is a function, calls it. The standard implementation uses the Backpack.
        -- Returns a string if there was an issue giving the item.

        local plr = participant.Player

        if type(item.Item) == "function" then
            item.Item(item, participant)
            remotes.InformClientSideEquipment:FireClient(plr, item.Name)
            return
        end

        InventoryManager.AddEquipment(plr, Weapons[item.Name])

        return
    end,

    RemoveEquipment = function(participant, item)
        InventoryManager.RemoveEquipment(participant.Player, Weapons[item.Name])
    end,

    ClearAllEquipment = function(participant)
        InventoryManager.ClearInventory(participant.Player)
    end,

    CheckForUpdate = function(round)
        if not game:GetService("RunService"):IsStudio() and game.PlaceId ~= 9648179685 then
            local newVersion: ProfileService.Profile & {Data: {Version: string}} = ProfileStore:ViewProfileAsync("Version")

            if newVersion then
                if newVersion.Data.Version ~= script:GetAttribute("Version") then
                    ServerStorage:SetAttribute("ServerLocked", true)
                    ServerScriptService.PlayerSetup.ReleaseAllProfiles:Fire()
                    return true
                end
            end
        end
        return false
    end,

    SendMessage = function(message, severity, messageType, recipients)
        -- If isGlobal = true, then recipients is empty. The adapter is expected to send this message to all connected players (Players:GetPlayers()).
        -- Sends a private server message to each recipient.
        -- The message can be further processed here, such as using rich text to change text colour depending on severity.

        local remote = remotes.SendMessage
        
        local fontColour = ""
        -- These colours suck
        if severity == "error" then
            fontColour = "#ff0000"
        elseif severity == "warn" then
            fontColour = "#ffff00"
        elseif severity == "info" then
            fontColour = "#0000ff"
        end
        message = `<font color='{fontColour}'>{message}</font>`

        if recipients == true then
            return remote:FireAllClients(message, messageType)
        end
        for _, v in recipients do
            if v.Player then
                remote:FireClient(v.Player, message, messageType)
            end
        end
        return
    end,

    SendRoleAlert = function(recipient, role)
        local remote = remotes.SendRoleAlert
        remote:FireClient(recipient.Player, role.Name, role.Colour, role.Description, role.Extras.Sound)
    end,

    SendRoundHighlights = function(recipients, highlights, events, scores, victors)
        local remote = remotes.SendHighlights
        for _, v in recipients do
            remote:FireClient(v.Player, highlights, events, scores, victors)
        end
    end,

    GetKarma = function(plr)
        -- This is only used when first adding the Participant to the round, Participant.Karma is used for the duration of the round.
        -- SetKarma() is used when the round ends.

        return getProfile:Invoke(plr).Karma
    end,

    SetKarma = function(plr, karma)
        return updateProfile:Fire(plr, "Karma", karma)
    end,

    OnCharacterLoad = function(participant)
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://"..deathsounds[math.random(1, #deathsounds)]
        sound.Name = "DeathSound"
        sound.Parent = participant.Character.PrimaryPart
    end,

    SendSlayVote = function(to, target)
        local remote = remotes.SlayVote
        remote:FireClient(to.Player, target.Player)
    end,

    CalculateDamageModifier = function(karma)
        return ((0.00005 * (karma^2)) + 50) / 100
    end,

    OnDeath = function(victim)
        local char = victim.Character
        local plr = victim.Player
        if not char:IsDescendantOf(workspace) then
            return
        end

        char.Archivable = true
        local clone = char:Clone()

        local root = clone:FindFirstChild("HumanoidRootPart") :: Part?
        local hum = clone:FindFirstChildOfClass("Humanoid")

        local equipment = InventoryManager.GetInventory(plr)
        for i = #equipment, 1, -1 do
            if equipment[i].CanDrop then
                InventoryManager.Drop(plr, equipment[i])
            else
                InventoryManager.RemoveEquipment(plr, equipment[i])
            end
        end

        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
            hum.EvaluateStateMachine = false
        end
        if root then
            root.CanCollide = false
            root.CanTouch = false
            root.CanQuery = false
        end

        char:Destroy()
        clone.Parent = workspace

        victim.Character = clone
        victim.Player.Character = nil

        local joints = ServerStorage.RagdollJoints:Clone()
        for _, v in joints:GetChildren() do
            assert(v:IsA("Constraint"))

            local bodyPart = clone:FindFirstChild(v.Name)
            if not bodyPart then
                continue
            end
            
            local motor = bodyPart:FindFirstChildOfClass("Motor6D")
            if not motor or not motor.Part0 then
                continue
            end
            v.Attachment0 = motor.Part0:FindFirstChild(motor.Name.."RigAttachment") :: Attachment
            v.Attachment1 = bodyPart:FindFirstChild(motor.Name.."RigAttachment") :: Attachment
        end
        joints.Parent = clone :: any

        -- This has to be after parenting because motor6ds don't exist?
        for _, v in clone:GetDescendants() do
            if v:IsA("JointInstance") or v:IsA("BaseScript") or v:IsA("Motor6D") then
                v:Destroy()
            elseif v:IsA("BasePart") then
                v.CanCollide = v.Name ~= "HumanoidRootPart"
                v:SetNetworkOwner()
            elseif v.Name == "DeathSound" and v:IsA("Sound") then
                v:Play()
            end
        end

        for _, v in Players:GetPlayers() do
            UpdateRoundInfo.SendUpdatedParticipants(victim.Round.Participants, victim, victim.Player)
        end
    end,

    CalculateUserFacingEvents = function(events: Types.RoundEventLog, winners)
        local userFacingLog: {Types.UserFacingRoundEvent} = {}

        local function getDeathEvent(data: Types.RoundEvent_Death)
            local attacker = data.Attacker
            local weapon = data.Weapon
            local text = data.Victim.FormattedName

            local attackerName
            if attacker then
                attackerName = attacker.FormattedName
            end
            if weapon == "Fall" then
                text ..= " was doomed to fall"
                if attacker then
                    text ..= ` at the hands of {attackerName}`
                end
            elseif weapon == "Drown" then
                text ..= " was doomed to drown"
                if attacker then
                    text ..= ` at the hands of {attackerName}`
                end
            elseif weapon == "Suicide" then
                text ..= " couldn't take it anymore and killed themselves"
            elseif weapon == "Crush" then
                text ..= " was crushed"
                if attacker then
                    text ..= ` by {attackerName}`
                end
            elseif weapon == "Mutation" then
                text ..= "'s DNA was mutated"
                if attacker then
                    text ..= ` by {attackerName}`
                end
            elseif type(weapon) == "table" then
                local attack = weapon.AttackType
                local name = stringWithDeterminer(weapon.Name)
                if attack == "Blade" then
                    text ..= ` was stabbed by {name}`
                elseif attack == "Blunt" then
                    text ..= ` was bludgeoned by {name}`
                elseif attack == "Explosion" then
                    text ..= ` was blown up by {name}`
                elseif attack == "Firearm" then
                    text ..= ` was shot by {name}`
                elseif attack == "None" then
                    text ..= ` was murdered by magic`
                end
                if attacker then
                    text ..= ` used by {attackerName}`
                end
            end
            text ..= "."
            return text
        end

        for _, v in events.MetaEvent do
            local event = {
                Text = "",
                Icons = {},
                Category = "MetaEvent" :: Types.RoundEventCategory,
                Timestamp = v.Timestamp,
            }
            if v.Data.RoundPhase then
                event.Text = "The round begins."
            elseif v.Data.NewMap then
                event.Text = `The map changes to {v.Data.NewMap}.`
            elseif v.Data.Winners then
                event.Text = v.Data.Winners.VictoryText :: string
            end
            table.insert(userFacingLog, event)
        end

        for _, v in events.CorpseSearched do
            local event = {
                Text = "",
                Icons = {},
                Category = "CorpseSearched" :: Types.RoundEventCategory,
                Timestamp = v.Timestamp,
            }
            if v.Data.CreditsFound then
                event.Text = `{v.Data.Participant} found {v.Data.CreditsFound} credits on the body of {v.Data.Corpse}.`
            else
                event.Text = `{v.Data.Participant} found the body of {v.Data.Corpse}.`
            end
            table.insert(userFacingLog, event)
        end

        for _, v in events.Death do
            local icons = {}
            table.insert(icons, if v.Data.CorrectKill then "CorrectKill" else "IncorrectKill")
            if v.Data.SelfDefense then
                table.insert(icons, "SelfDefense")
            end
            if v.Data.FreeKill then
                table.insert(icons, "FreeKill")
            end

            table.insert(userFacingLog, {
                Text = getDeathEvent(v.Data),
                Icons = icons,
                Category = "Death",
                Timestamp = v.Timestamp
            })
        end

        table.sort(userFacingLog, function(a, b)
            return a.Timestamp < b.Timestamp
        end)

        return userFacingLog
    end,
}

return module