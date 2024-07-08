-- Implementation-dependent functions that *should* be customised.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ActionItems = require(script.Parent.ActionItems)
local CalculateDamageModifier = require(script.Parent.Parent.ReplicatedFirst.CalculateDamageModifier)
local API = require(ReplicatedFirst.API)
local InventoryManager = require(ReplicatedFirst.InventoryManager)
local Items = require(ReplicatedFirst.ItemsManager.Items)
local ShatterGlass = require(ReplicatedFirst.ShatterGlass)
local ProfileManager = require(ServerScriptService.ProfileManager)
local RestartServer = require(ServerScriptService.RestartServer)
local ProfileService = require(ServerScriptService.ProfileService)
local Types = require(ReplicatedFirst.RoundHandler.Types)

local remotes = ReplicatedStorage.RoundHandler

local plasticSounds = {5682538842, 9114858163, 9114857307, 9114626534}
local metalSounds = {7842407959, 4072627278, 2303101209}
local woodSounds = {8542226017, 8542224235, 8542224819, 8542225504, 8542223682}
local fabricSounds = {6636232274, 2706199011, 9118771226}
local glassSounds = {3207457473, 9113290528, 9119937112, 9119596406}
local groundSounds = {6876730610, 6876735204, 6877211005, 6877211445}
local hitSounds = {
    Fruit = {9114540315, 9114539908, 9114542474, 9114540327, 9114541282},

    -- Carpet stuff
    Fabric = fabricSounds,
    Carpet = fabricSounds,
    Sand = fabricSounds,
    
    -- Wood stuff
    Wood = woodSounds,
    WoodPlanks = woodSounds,

    -- Metal stuff
    Metal = metalSounds,
    CorrodedMetal = metalSounds,
    DiamondPlate = metalSounds,

    -- Glass stuff
    Glass = glassSounds,
    Glacier = glassSounds,
    Ice = glassSounds,

    -- Ground stuff
    Ground = groundSounds,
    Grass = groundSounds,
    LeafyGrass = groundSounds,
    Mud = groundSounds,
}

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

local ragdollConstraints: {[string]: string} = {
    Neck = "Head",

    LeftAnkle = "LeftFoot",
	LeftKnee = "LeftLowerLeg",
	LeftHip = "LeftUpperLeg",

	RightAnkle = "RightFoot",
	RightKnee = "RightLowerLeg",
	RightHip = "RightUpperLeg",

	Root = "LowerTorso",
	Waist = "UpperTorso",

	LeftWrist = "LeftHand",
	LeftElbow = "LeftLowerArm",
	LeftShoulder = "LeftUpperArm",

	RightWrist = "RightHand",
	RightElbow = "RightLowerArm",
	RightShoulder = "RightUpperArm",
}

local module: Types.Adapter = {
    HIGHLIGHTS_TIME = 10, -- Time to spend after the round ends before destroying the round
    PREPARING_TIME = 5, -- Time to spend after a round is created where players can join the round
    SLAY_VOTES = 2, -- Minimum number of votes to slay someone, at which point they will be slain
    INTERMISSION_TIME = 10,
    LOAD_LIGHTING_SETTINGS = true,
    LOAD_TERRAIN_SETTINGS = true,
    LOAD_GRAVITY_SETTING = true,
    DEFAULT_GRAVITY = 80,
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

    SetDefaultTerrain = function()
        local terrain = workspace.Terrain
        terrain.WaterReflectance = 1
        terrain.WaterTransparency = 0.3
        terrain.WaterWaveSize = 0.15
        terrain.WaterWaveSpeed = 10
        terrain.WaterColor = Color3.fromRGB(12, 84, 92)

        local function s(material: Enum.Material, r: number, g: number, b: number)
            terrain:SetMaterialColor(material, Color3.fromRGB(r, g, b))
        end

        local m = Enum.Material
        s(m.Asphalt, 115, 123, 107)
        s(m.Basalt, 30, 30, 37)
        s(m.Brick, 138, 86, 62)
        s(m.Cobblestone, 132, 123, 90)
        s(m.Concrete, 127, 102, 63)
        s(m.CrackedLava, 232, 156, 74)
        s(m.Glacier, 101, 176, 234)
        s(m.Grass, 106, 127, 63)
        s(m.Ground, 102, 92, 59)
        s(m.Ice, 129, 194, 224)
        s(m.LeafyGrass, 115, 132, 74)
        s(m.Limestone, 206, 173, 148)
        s(m.Mud, 58, 46, 36)
        s(m.Pavement, 148, 148, 140)
        s(m.Rock, 102, 108, 111)
        s(m.Salt, 198, 189, 181)
        s(m.Sand, 143, 126, 95)
        s(m.Sandstone, 137, 90, 71)
        s(m.Slate, 63, 127, 107)
        s(m.Snow, 195, 199, 218)
        s(m.WoodPlanks, 139, 109, 79)
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

        local base = Items[item.Name]
        for _, v in InventoryManager.GetInventory(plr) do
            if v.Base.Slot == base.Slot then
                return "SlotInUse"
            end
        end
        
        InventoryManager.NewItem(base, item.Item, participant)

        return
    end,

    ClearAllEquipment = function(participant)
        InventoryManager.ClearInventory(participant.Player)
    end,

    CheckForUpdate = function(round, timeDelay)
        if not game:GetService("RunService"):IsStudio() and game.PlaceId ~= 9648179685 then
            local newVersion: ProfileService.Profile & {Data: {Version: string}} = ProfileStore:ViewProfileAsync("Version")

            if newVersion then
                if newVersion.Data.Version ~= script:GetAttribute("Version") then
                    RestartServer(timeDelay)
                    return true
                end
            end
        end
        return false
    end,

    SendMessage = function(message: string, severity: Types.MessageSeverity, messageType: Types.MessageType, recipients: true | {Types.Participant})
        -- If isGlobal = true, then recipients is empty. The adapter is expected to send this message to all connected players (Players:GetPlayers()).
        -- Sends a private server message to each recipient.
        -- The message can be further processed here, such as using rich text to change text colour depending on severity.

        local remote = remotes.SendMessage
        
        if severity ~= "info" then
            local fontColour = ""
            if severity == "error" then
                fontColour = "#ff0000"
            elseif severity == "warn" then
                fontColour = "#ffff00"
            end
            message = `<font color='{fontColour}'>{message}</font>`
        end

        if recipients == true or (recipients[1] and recipients[1].Round.Participants == recipients) then
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

        local sendVictors: Types.Victor | Types.ClientParticipant = victors
        if victors.Kind == "Participant" then
            sendVictors = victors:ViewPartialParticipant()
        end
        for _, v in recipients do
            remote:FireClient(v.Player, highlights, events, scores, sendVictors)
        end
    end,

    GetKarma = function(plr)
        -- This is only used when first adding the Participant to the round, Participant.Karma is used for the duration of the round.
        -- SetKarma() is used when the round ends.

        local profile = ProfileManager.GetProfile(plr)

        if not profile then
            return 1000
        end
        return profile.Karma
    end,

    SetKarma = function(plr, karma)
        ProfileManager.UpdateProfile(plr, "Karma", karma)
    end,

    OnCharacterLoad = function(participant)
        local root = participant.Character.PrimaryPart
        if not root then
            return
        end

        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://"..deathsounds[math.random(1, #deathsounds)]
        sound.Name = "DeathSound"
        sound.Parent = root

        local scale = participant.Round.Map:FindFirstChild("Scale") :: NumberValue
        if scale then
            participant.Character:ScaleTo(scale.Value)
        end

        for _, v in participant.Character:GetDescendants() do
            if v:IsA("BasePart") then
                v.CollisionGroup = "PlayerCharacterParts"
            end
        end

        local magnetoAttachment = Instance.new("Attachment")
        magnetoAttachment.Name = "MagnetoAttachment"
        magnetoAttachment.CFrame = CFrame.new(0, 0, -6)
        magnetoAttachment.Parent = participant.Character:FindFirstChild("Head")

        local hum = participant.Character:FindFirstChildOfClass("Humanoid")
        if not hum then
            return
        end

        -- local startHeight = nil
        -- hum.StateChanged:Connect(function(oldState, newState)
        --     if newState == Enum.HumanoidStateType.Freefall then
        --         startHeight = root.Position.Y
        --     elseif oldState == Enum.HumanoidStateType.Freefall and startHeight then
        --         local magnitude = startHeight - root.Position.Y

        --         if magnitude <= 15 then
        --             return
        --         end

        --         local damage = (0.5 * (magnitude - 15) ^ 1.5) * 80 / workspace.Gravity
        --         participant:TakeDamage(damage, nil, "Fall")
        --     end
        -- end)
    end,

    SendSlayVote = function(to, target)
        local remote = remotes.SlayVote
        remote:FireClient(to.Player, target.Player)
    end,

    CalculateDamageModifier = CalculateDamageModifier,

    LoadBound = function(round, bound)
        if bound.Name == "KillBound" then
            bound.CanTouch = true
            bound.CanCollide = false
            bound.Touched:Connect(function(part)
                local char = part.Parent :: Model
                if not Players:GetPlayerFromCharacter(char) then
                    return
                end

                local participant = round:GetParticipant(char.Name)
                if not participant then
                    return
                end
                participant:TakeDamage(math.huge, nil, bound:GetAttribute("KillMethod") or "Suicide", nil, true)
            end)
        end
    end,

    LoadWeaponSpawn = function(round, weaponSpawn)
        local item = InventoryManager.Items[weaponSpawn]
        if item then -- If we don't check this we end up connecting to the touched event multiple times. Looks odd but checking here is correct.
            return
        end

        local ammo = InventoryManager.AmmoBoxes[weaponSpawn]
        if not ammo and weaponSpawn.Name:split("_")[2] == "Ammo" then
            InventoryManager.NewAmmoBox(weaponSpawn)
        end

        weaponSpawn.Touched:Connect(function(part)
            InventoryManager.OnWeaponTouched(weaponSpawn, round, part)
        end)
    end,

    LoadProp = function(round, prop)
        local object = prop.PropInstance
        if not object:IsA("BasePart") then
            return
        end

        local oldOnBreak = prop.OnBreak
        prop.OnBreak = function(self)
            if self.PropInstance:IsA("BasePart") then
                local material = self.PropInstance:GetAttribute("MaterialOverride") or self.PropInstance.Material.Name
                local soundPart = Instance.new("Part")
                soundPart.CanCollide = false
                soundPart.CanTouch = false
                soundPart.CanQuery = false
                soundPart.Anchored = true
                soundPart.Transparency = 1
                soundPart.Position = self.PropInstance.Position

                local sound = Instance.new("Sound")
                Random.new():Shuffle(hitSounds[material] or plasticSounds)
                sound.SoundId = "rbxassetid://"..(hitSounds[material] or plasticSounds)[1]
                sound.Volume = 1
                sound.Parent = soundPart
                soundPart.Parent = workspace.Projectiles

                sound.Ended:Once(function()
                    soundPart:Destroy()
                end)
                sound:Play()

                ActionItems.Execute(prop.PropInstance, prop.Attacker :: any)
            end
            oldOnBreak(self)
        end

        if object.Anchored then
            return
        end
        
        object.Touched:Connect(function(part)
            if not part.Parent then -- I would rather assert() here but actually this can fail in legitimate cases
                return
            end
            local energy = 0.5 * object.AssemblyMass * (object.AssemblyLinearVelocity.Magnitude ^ 2)
            if energy < 2000 then
                return
            end

            local activeHolder = object:FindFirstChild("ActiveHolder") :: NumberValue?
            if activeHolder and Players:GetPlayerByUserId(activeHolder.Value) then
                return
            end

            local lastHolder = object:FindFirstChild("LastHolder") :: NumberValue?
            local char = part:FindFirstAncestorOfClass("Model")
            local lastHolderPlr
            local lastHolderParticipant
            if lastHolder then
                lastHolderPlr = Players:GetPlayerByUserId(lastHolder.Value)
                if lastHolderPlr then
                    lastHolderParticipant = round:GetParticipant(lastHolderPlr.Name)
                end
            end

            if lastHolder and (lastHolderPlr == Players:GetPlayerFromCharacter(char :: Model)) then
                return
            end

            local damage = (energy - 2000) / 1000
            if prop:HasHealth() then
                prop:TakeDamage(damage, lastHolderParticipant)
            end

            local windows = round.Map:FindFirstChild("Windows")
            if windows and windows:IsAncestorOf(part) then
                return ShatterGlass(part, object.AssemblyLinearVelocity / 100)
            end
            
            if not char then
                return
            end
            
            local participant = round:GetParticipant(char.Name)
            if not participant then
                return
            end

            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then
                return
            end

            if lastHolder and lastHolder.Value ~= nil then
                participant:TakeDamage(damage, lastHolderParticipant, "Crush") -- only do damage if the prop was flung by someone
            end
        end)
    end,

    OnCorpseResult = function(searcher, corpse)
        remotes.CorpseSearched:FireClient(searcher.Player, corpse.Player.Name)
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
            if equipment[i].Base.CanDrop then
                InventoryManager.Drop(plr, equipment[i], char:GetPivot().Position)
            else
                InventoryManager.RemoveEquipment(plr, equipment[i])
            end
        end

        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Physics)
            hum.EvaluateStateMachine = false
        end
        if root then
            root.CanCollide = false
            root.CanTouch = false
            root.CanQuery = false
        end

        char:Destroy()

        clone:SetAttribute("IsCorpse", true)
        clone.Name = "__Unidentified"

        local joints = ServerStorage.RagdollJoints:Clone()
        for _, v in joints:GetChildren() do
            assert(v:IsA("Constraint"))

            local part = clone:FindFirstChild(ragdollConstraints[v.Name]) :: BasePart
            v.Attachment1 = part:FindFirstChild(v.Name.."RigAttachment", true) :: Attachment

            local att = v.Attachment1 :: Attachment
            att.Name = v.Name.."RigAttach" -- If an attachment ends with "RigAttachment", roblox automatically creates Motor6Ds. Not good.

            v.Attachment0 = clone:FindFirstChild(v.Name.."RigAttachment", true) :: Attachment
            att = v.Attachment0 :: Attachment
            att.Name = v.Name.."RigAttach"

            v.Parent = part
        end

        clone.Parent = workspace
        for _, v in clone:GetDescendants() do
            if v:IsA("JointInstance") or v:IsA("BaseScript") or v:IsA("Fire") then
                v:Destroy()
            elseif v:IsA("BasePart") then
                v.CollisionGroup = "Corpses"
            elseif v.Name == "DeathSound" and v:IsA("Sound") then
                v:Play()
            end
        end

        task.spawn(function()
            while clone.Parent do
                for _, v in clone:GetDescendants() do
                    if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                        v.CanCollide = true
                    end
                end
                task.wait()
            end
        end)

        if root then
            root:SetNetworkOwner()
        end

        victim.Character = clone
        victim.Player.Character = nil
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
                text ..= " fell to their death"
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
                local name = API.StringWithDeterminer(weapon.Name)
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
            elseif weapon == "Explosion" then
                text ..= " was blown up"
                if attacker then
                    text ..= ` by {attackerName}`
                end
            elseif weapon == "Burn" then
                text ..= " was burned"
                if attacker then
                    text ..= ` by {attackerName}`
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
                if v.Data.Winners.Kind == "Participant" then
                    event.Text = v.Data.Winners.Role.VictoryText :: string
                else
                    event.Text = v.Data.Winners.VictoryText :: string
                end
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
                event.Text = `{v.Data.Participant.FormattedName} found {v.Data.CreditsFound} credits on the body of {v.Data.Corpse.FormattedName}.`
            else
                event.Text = `{v.Data.Participant.FormattedName} found the body of {v.Data.Corpse.FormattedName}.`
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