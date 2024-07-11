local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemTypes = require(script.Parent.ItemTypes)
local Types = require(script.Parent.Parent.RoundHandler.Types)

local projectiles = ReplicatedStorage:WaitForChild("Projectiles") :: typeof(ReplicatedStorage.Projectiles)
local models = ReplicatedStorage.WeaponModels
local weaponSounds = ReplicatedStorage.WeaponSounds
local firedSounds = weaponSounds.Fired
local reloadSounds = weaponSounds.Reload

local bullet = projectiles:WaitForChild("Bullet") :: PVInstance -- Somehow this ended up not loading despite Waiting for Projectiles?



local controlledProps: {[number]: BasePart} = {}

local function stopControllingProp(prop: BasePart, userId: number)
    if not prop:IsDescendantOf(workspace) then
        return
    end
    local alignPos = prop:FindFirstChildOfClass("AlignPosition") :: AlignPosition
    local activeHolder = prop:FindFirstChild("ActiveHolder") :: NumberValue

    alignPos.Attachment1 = nil
    alignPos.Enabled = false
    activeHolder.Value = 0

    local lastHolder = prop:FindFirstChild("LastHolder") :: NumberValue
    local con: RBXScriptConnection
    local resetHolderThread = task.delay(5, function()
        if con.Connected then
            con:Disconnect()
        end
        if not prop:IsDescendantOf(workspace) then
            return
        end
        prop:SetNetworkOwnershipAuto()
        lastHolder.Value = 0
    end)

    lastHolder.Value = userId

    con = lastHolder.Changed:Once(function(newId)
        task.cancel(resetHolderThread)
    end)

    controlledProps[userId] = nil
end

local guns: {[string]: ItemTypes.GunDefinition} = {}
guns.HUGE = {
    Kind = "Gun",
    Name = "HUGE",

    Slot = 3,
    CanDrop = true,

    Recoil = 0.6,
    Spread = 1.5,

    Damage = {
        Head = 15,
        Body = 10,
        Limb = 5,
    },

    FalloffStart = 35,
    FalloffEnd = 80,
    FalloffMultiplier = 0.5,

    AimFOV = 60,
    AimSpreadMultiplier = 0.3,

    FireTime = 0.01,
    ReloadTime = 0,
    MagazineSize = 250,

    ProjectileBase = bullet,
    ProjectileSpeed = 140,

    Model = models:WaitForChild("HUGE"),

    FiredSound = firedSounds.HUGE,
}

guns.Scout = {
    Kind = "Gun",
    Name = "Scout",
    
    Slot = 3,
    CanDrop = true,

    Recoil = 1.5,
    Spread = 0.25,

    FalloffStart = 180,
    FalloffEnd = 300,
    FalloffMultiplier = 0.5,

    AimFOV = 30,
    AimSpreadMultiplier = 0.05,
    HasScope = true,

    Damage = {
        Body = 50,
        Limb = 25,
        Head = 150,
    },

    ProjectileBase = bullet,
    ProjectileSpeed = 250,

    FireTime = 1,
    ReloadTime = 1.5,
    AmmoType = "Scout",

    Model = models:WaitForChild("Scout"),
    FiredSound = firedSounds.Scout,
    ReloadSound = reloadSounds.Scout,
}

guns.Pistol = {
    Kind = "Gun",
    Name = "Pistol",

    Slot = 2,
    CanDrop = true,

    Damage = {
        Head = 60,
        Body = 30,
        Limb = 20,
    },

    Spread = 0.25,
    Recoil = 0.5,

    FalloffStart = 55,
    FalloffEnd = 110,
    FalloffMultiplier = 0.4,

    AimFOV = 70,
    AimSpreadMultiplier = 0.1,

    FireTime = 0.5,
    ReloadTime = 1,
    AmmoType = "Assault Rifle",

    Model = models:WaitForChild("Pistol"),
    FiredSound = firedSounds.Pistol,
    ReloadSound = reloadSounds.Pistol,

    ProjectileBase = bullet,
    ProjectileSpeed = 100,
}

guns["Golden Gun"] = {
    Kind = "Gun",
    Name = "Golden Gun",
    Description = "One shot. Don't fumble it.",

    Slot = 7,
    CanDrop = true,

    Damage = 0,
    FalloffStart = 0,
    FalloffEnd = 0,
    FalloffMultiplier = 1,

    Spread = 0,
    Recoil = 5,

    MagazineSize = 1,

    ProjectileBase = projectiles:WaitForChild("GoldenBullet"),
    ProjectileSpeed = 250,

    Model = models["Golden Gun"],
    FiredSound = firedSounds["Golden Gun"],

    FireTime = 0.5,
    ReloadTime = 0,

    AimFOV = 70,
    AimSpreadMultiplier = 0,

    BeforeHitProp = function(attacker, target)
        if target:HasHealth() then
            target:TakeDamage(math.huge, attacker)
        end
        return true
    end,

    BeforeHitParticipant = function(attacker, target, dead, hitPartName)
        if not attacker then
            return
        end

        local function makeGolden(victim: Types.Participant)
            local char = victim.Character
            local root = char:FindFirstChild("HumanoidRootPart")
            local bodyColors = char:FindFirstChildOfClass("BodyColors")
            if bodyColors then
                bodyColors:Destroy()
            end

            if root then
                local deathSound = root:FindFirstChild("DeathSound") :: Sound?
                if deathSound then
                    deathSound:Destroy()
                end

                local sound = weaponSounds.GoldenGunHit:Clone()
                sound.Name = "DeathSound"
                sound.Parent = root :: any
            end
            for _, v in char:GetChildren() do
                if v:IsA("BasePart") then
                    v.Material = Enum.Material.Metal
                    v.BrickColor = BrickColor.new("Gold")
                end
            end

            local shirt = char:FindFirstChildOfClass("Shirt")
            if shirt then
                shirt:Destroy()
            end

            local pants = char:FindFirstChildOfClass("Pants")
            if pants then
                pants:Destroy()
            end
        end

        if attacker:IsDamageJustifiedAgainst(target) then
            makeGolden(target)
            target:TakeDamage(math.huge, attacker, attacker.Round:GetEquipment("Golden Gun"), hitPartName == "Head")
        else
            makeGolden(attacker)
            attacker:TakeDamage(math.huge, attacker, attacker.Round:GetEquipment("Golden Gun"), hitPartName == "Head", true)
        end

        return true
    end,
}

local function burn(attacker: Types.Participant?, target: Types.Participant | Types.Prop?, part: BasePart): ()
    if not attacker then
        return
    end

    local fire = Instance.new("Fire")
    fire.Size = 10
    fire.Parent = part

    local burnSound = weaponSounds.FlareBurn:Clone()
    burnSound.Parent = part :: any

    local endTime = workspace:GetServerTimeNow() + 10
    task.spawn(function()
        while true do
            if workspace:GetServerTimeNow() > endTime then
                break
            end
            if target and (target :: any):HasHealth() and (target :: any):GetHealth() < 0 then
                break
            end
            if not part:IsDescendantOf(workspace) then
                break
            end

            burnSound:Play()

            if target and (target :: any):HasHealth() then
                (target :: any):TakeDamage(1, attacker, "Burn", false, true)
            end

            task.wait(0.25)
        end

        burnSound:Destroy()
        fire:Destroy()

        local model = part:FindFirstAncestorOfClass("Model")
        if not target and model then
            model:Destroy()
        end
    end)
end

guns["Flare Gun"] = {
    Kind = "Gun",
    Name = "Flare Gun",
    Description = "Ouch fire hot.",

    Slot = 8,
    CanDrop = true,

    Damage = {
        Head = 15,
        Body = 10,
        Limb = 5,
    },

    FalloffStart = 35,
    FalloffEnd = 80,
    FalloffMultiplier = 0.5,

    Spread = 1,
    Recoil = 0.3,

    FireTime = 0.25,
    ReloadTime = 0,
    MagazineSize = 6,

    Model = models["Flare Gun"],
    FiredSound = firedSounds["Flare Gun"],

    ProjectileBase = projectiles:WaitForChild("Flare"),
    ProjectileSpeed = 140,

    AimFOV = 60,
    AimSpreadMultiplier = 0.3,

    BeforeHitParticipant = function(attacker: Types.Participant?, target: Types.Participant, dead: boolean?, hitPartName: string)
        burn(attacker, target, target.Character.PrimaryPart :: BasePart)
        return
    end,

    BeforeHitProp = function(attacker, target, willDestroy, partName)
        if willDestroy then
            return
        end

        local part = target.PropInstance:FindFirstChild(partName, true) or target.PropInstance
        if not part or not part:IsA("BasePart") then
            return
        end

        burn(attacker, target, part)
        return
    end,

    BeforeHitCorpse = function(attacker, part)
        if not part.Parent then
            return
        end

        local root = part.Parent:FindFirstChild("HumanoidRootPart")
        if not root or not root:IsA("BasePart") then
            return
        end

        burn(attacker, nil, root)
    end,
}

guns.SMG = {
    Kind = "Gun",
    Name = "SMG",

    Slot = 3,
    CanDrop = true,
    
    Damage = {
        Head = 25,
        Body = 20,
        Limb = 15,
    },

    FalloffStart = 35,
    FalloffEnd = 80,
    FalloffMultiplier = 0.5,

    Spread = 1,
    Recoil = 0.3,

    FireTime = 0.05,
    ReloadTime = 1,
    AmmoType = "SMG",

    Model = models:WaitForChild("SMG"),
    FiredSound = firedSounds:WaitForChild("SMG"),
    ReloadSound = reloadSounds.SMG,

    ProjectileBase = bullet,
    ProjectileSpeed = 140,

    AimFOV = 60,
    AimSpreadMultiplier = 0.3,
}

guns.AWP = {
    Kind = "Gun",
    Name = "AWP",
    Description = "A high-powered sniper rifle. Must be scoped in to shoot.",
    
    Slot = 7,
    CanDrop = true,

    Damage = {
        Head = 300,
        Body = 100,
        Limb = 65,
    },

    FalloffStart = 200,
    FalloffEnd = 400,
    FalloffMultiplier = 0.5,

    AimFOV = 10,
    AimSpreadMultiplier = 0.05,
    ScopeRequired = true,
    HasScope = true,

    Spread = 0.25,
    Recoil = 2,

    FireTime = 2,
    ReloadTime = 0,
    MagazineSize = 4,

    Model = models:WaitForChild("AWP"),
    FiredSound = firedSounds.AWP,

    ProjectileBase = bullet,
    ProjectileSpeed = 300,
}

guns["Assault Rifle"] = {
    Kind = "Gun",
    Name = "Assault Rifle",

    Slot = 3,
    CanDrop = true,

    Spread = 0.5,
    Recoil = 0.3,

    Damage = {
        Head = 60,
        Body = 30,
        Limb = 20,
    },

    FireTime = 0.15,
    ReloadTime = 1.5,
    AmmoType = "Assault Rifle",

    AimFOV = 50,
    AimSpreadMultiplier = 0.25,

    Model = models["Assault Rifle"],
    FiredSound = firedSounds["Assault Rifle"],
    ReloadSound = reloadSounds["Assault Rifle"],

    FalloffStart = 75,
    FalloffEnd = 125,
    FalloffMultiplier = 0.5,

    ProjectileBase = bullet,
    ProjectileSpeed = 150,
}

guns["Silenced Pistol"] = {
    Kind = "Gun",
    Name = "Silenced Pistol",
    Description = "A Pistol that has had a suppressor fitted to it, making it much quieter. People killed with silenced weapons will not scream.",

    Slot = 7,
    CanDrop = true,

    Damage = {
        Head = 60,
        Body = 30,
        Limb = 20,
    },

    Spread = 0.25,
    Recoil = 0.5,

    FalloffStart = 55,
    FalloffEnd = 110,
    FalloffMultiplier = 0.4,
    
    AimFOV = 70,
    AimSpreadMultiplier = 0.1,

    FireTime = 0.5,
    ReloadTime = 1,
    AmmoType = "Assault Rifle",

    Model = models["Silenced Pistol"],
    FiredSound = firedSounds["Silenced Pistol"],
    ReloadSound = reloadSounds["Silenced Pistol"],

    ProjectileBase = projectiles:WaitForChild("SilencedBullet"),
    ProjectileSpeed = 100,

    BeforeHitParticipant = function(_, victim)
        local root = victim.Character:FindFirstChild("HumanoidRootPart")
        if not root then
            return
        end

        local deathSound = root:FindFirstChild("DeathSound") :: Sound
        if deathSound then
            deathSound.Volume = 0
        end
        return
    end,
}

guns.XM1014 = {
    Kind = "Gun",
    Name = "XM1014",

    Slot = 3,
    CanDrop = true,

    Damage = {
        Head = 30,
        Body = 18,
        Limb = 10,
    },

    FalloffStart = 25,
    FalloffEnd = 30,
    FalloffMultiplier = 0.5,

    AimFOV = 50,
    AimSpreadMultiplier = 0.7,

    Spread = 1.5,
    Recoil = 1.2,

    FireTime = 0.8,
    ReloadTime = 1.5,
    AmmoType = "Shotgun",

    BulletsPerShot = 6,

    ProjectileBase = bullet,
    ProjectileSpeed = 150,

    Model = models:WaitForChild("XM1014"),
    FiredSound = firedSounds.XM1014,
    ReloadSound = reloadSounds.XM1014,
}

guns.Glock = {
    Kind = "Gun",
    Name = "Glock",

    Slot = 2,
    CanDrop = true,

    Damage = {
        Head = 20,
        Body = 15,
        Limb = 10,
    },

    FalloffStart = 45,
    FalloffEnd = 100,
    FalloffMultiplier = 0.2,

    AimFOV = 70,
    AimSpreadMultiplier = 0.1,

    Recoil = 0.5,
    Spread = 0.35,

    FireTime = 0.1,
    ReloadTime = 1,
    AmmoType = "Assault Rifle",

    Model = models:WaitForChild("Glock"),
    FiredSound = firedSounds.Glock,
    ReloadSound = reloadSounds.Glock,

    ProjectileBase = bullet,
    ProjectileSpeed = 190,
}

guns.Deagle = {
    Kind = "Gun",
    Name = "Deagle",

    Slot = 2,
    CanDrop = true,

    Damage = {
        Head = 100,
        Body = 40,
        Limb = 20,
    },

    FalloffStart = 100,
    FalloffEnd = 200,
    FalloffMultiplier = 0.8,

    AimFOV = 50,
    AimSpreadMultiplier = 0.1,

    Recoil = 0.5,
    Spread = 0.25,

    FireTime = 0.5,
    ReloadTime = 1.2,
    AmmoType = "Deagle",

    ProjectileBase = bullet,
    ProjectileSpeed = 190,

    Model = models:WaitForChild("Deagle"),
    FiredSound = firedSounds.Deagle,
    ReloadSound = reloadSounds.Deagle,
}

guns.BAR = {
    Kind = "Gun",
    Name = "BAR",

    Slot = 3,
    CanDrop = true,

    Damage = {
        Head = 75,
        Body = 40,
        Limb = 25,
    },

    Spread = 0.75,
    Recoil = 0.7,

    FalloffStart = 50,
    FalloffEnd = 120,
    FalloffMultiplier = 0.3,

    FireTime = 0.1,
    ReloadTime = 2.5,
    AmmoType = "Assault Rifle",

    Model = models:WaitForChild("BAR"),
    FiredSound = firedSounds.BAR,
    ReloadSound = reloadSounds.BAR,

    ProjectileBase = bullet,
    ProjectileSpeed = 120,

    AimFOV = 65,
    AimSpreadMultiplier = 0.2,
}

local grenades: {[string]: ItemTypes.GrenadeDefinition} = {}
grenades.Grenade = {
    Kind = "Grenade",
    Name = "Grenade",
    Description = "Explodes in a good radius after 5 seconds.",

    Slot = 7,
    CanDrop = true,

    Model = models:WaitForChild("Grenade"),
    
    ExplosionInfo = {
        Kind = "Explosion",
        Radius = 17,
        Pressure = 20000,
        Damage = 200,

        FalloffStart = 5,
        FalloffEnd = 17,
        FalloffMultiplier = 0,
    },

    Fuse = 5,

    ProjectileBase = models:WaitForChild("Grenade"),
    ProjectileForce = 0.5,
    Spread = 0.25,

    FiredSound = firedSounds.Grenade,
}

grenades.Flashbang = {
    Kind = "Grenade",
    Name = "Flashbang",
    Description = "Explodes in a good radius after 3 seconds, blinding and deafening anyone in range.",

    Slot = 7,
    CanDrop = true,

    Model = models:WaitForChild("Flashbang"),

    ExplosionInfo = {
        Kind = "Explosion",
        Radius = 15,
        Pressure = 10000,
        Damage = 0,

        BeforeHitParticipant = function(attacker, target, dead, hitPartName)
            return ReplicatedStorage.ServerClient.Flashbang:FireClient(target.Player)
        end,
    },

    Fuse = 3,

    ProjectileBase = models:WaitForChild("Flashbang"),
    ProjectileForce = 100,
    Spread = 0.25,

    FiredSound = firedSounds.Grenade,
}

local melees: {[string]: ItemTypes.MeleeDefinition} = {}
melees.Crowbar = {
    Kind = "Melee",
    Name = "Crowbar",
    
    Slot = 1,
    CanDrop = false,

    Model = models:WaitForChild("Crowbar"),

    MaxDistance = 7,
    Damage = 20,
    FireTime = 0.3,
    FiredSound = firedSounds.Crowbar,
}

local items: {[string]: ItemTypes.ItemDefinition} = {}
items["Magneto Stick"] = {
    Kind = "Item",
    Name = "Magneto Stick",
    Description = "Haha props",
    Slot = 5,
    CanDrop = false,

    Model = models["Magneto Stick"],
    AlternateFire = function(participant: Types.Participant, cameraRayInfo: Ray)
        local char = participant.Character

        local head = char:FindFirstChild("Head")
        if not head or not head:IsA("BasePart") then
            return
        end

        local root = char.PrimaryPart
        if not root then
            return
        end

        local map = ReplicatedStorage.RoundHandler.MapFolder.Value
        if not map then
            return
        end

        local props = map:FindFirstChild("Props")
        local weaponSpawns = map:FindFirstChild("WeaponSpawns")
        if not props and not weaponSpawns then
            return
        end

        local userId = participant.Player.UserId
        local alreadyControlled = controlledProps[userId]
        if alreadyControlled then
            if alreadyControlled.Parent then
                stopControllingProp(alreadyControlled, userId)
            else
                controlledProps[userId] = nil
            end
        end

        local rayParams = RaycastParams.new()
        rayParams.IgnoreWater = true
        rayParams.RespectCanCollide = false
        rayParams.CollisionGroup = "Raycasts"
        rayParams.FilterType = Enum.RaycastFilterType.Include
        rayParams.FilterDescendantsInstances = {workspace.Corpses, workspace.Characters, participant.Round.Map :: Types.MapStructureCast}

        local result = workspace:Raycast(head.Position, cameraRayInfo.Direction * 10, rayParams)
        if not result then
            return
        end

        local object = result.Instance :: BasePart
        local model = object:FindFirstAncestorOfClass("Model")

        if (props and not props:IsAncestorOf(object)) and (weaponSpawns and not weaponSpawns:IsAncestorOf(object)) and (model and not model:IsDescendantOf(workspace.Corpses)) then
            return
        end

        if object:GetAttribute("NoGrab") then
            return
        end

        if alreadyControlled == object then
            return
        end

        if object.AssemblyMass == math.huge then -- anchored props have inf assemblymass
            return
        end

        if (object.AssemblyMass > 50) or (object.Size.X * object.Size.Y * object.Size.Z > 50) then -- Mostly arbitrarily chosen by looking at Skyscraper and Mesa Monocraft props
            return
        end

        local alignPos = object:FindFirstChildOfClass("AlignPosition") or Instance.new("AlignPosition")
        if not alignPos.Parent then
            alignPos.Responsiveness = 200
            alignPos.MaxVelocity = 40
            alignPos.MaxForce = 10000
            alignPos.ApplyAtCenterOfMass = true
            alignPos.Mode = Enum.PositionAlignmentMode.TwoAttachment

            local attachPoint = Instance.new("Attachment")
            attachPoint.Name = "AttachPoint"

            alignPos.Attachment0 = attachPoint

            attachPoint.Parent = object
            alignPos.Parent = object
        end

        local activeHolder = object:FindFirstChild("ActiveHolder") :: NumberValue or Instance.new("NumberValue")
        if activeHolder.Parent and Players:GetPlayerByUserId(activeHolder.Value) then
            if activeHolder.Value == userId then
                stopControllingProp(object, userId)
            end
            return
        elseif not activeHolder.Parent then
            activeHolder.Name = "ActiveHolder"
            activeHolder.Parent = object
        end

        activeHolder.Value = userId

        local lastHolder = object:FindFirstChild("LastHolder") :: NumberValue or Instance.new("NumberValue")
        if not lastHolder.Parent then
            lastHolder.Name = "LastHolder"
            lastHolder.Parent = object
        end

        controlledProps[userId] = object
        object:SetNetworkOwner(participant.Player)
        alignPos.Attachment1 = head:FindFirstChild("MagnetoAttachment") :: Attachment?
        alignPos.Enabled = true
    end,
    PrimaryFire = function(plr: Types.Participant, cameraRayInfo: Ray)
        
    end,
    OnUnequip = function(plr: Player)
        local userId = plr.UserId
        local prop = controlledProps[userId]
        if prop then
            stopControllingProp(prop, userId)
        end
    end
}

local combinedItems: {[string]: ItemTypes.ItemDefinition | ItemTypes.WeaponDefinition} = {}
for _, v in items do
    combinedItems[v.Name] = v
end
for _, v in guns do
    combinedItems[v.Name] = v
end
for _, v in grenades do
    combinedItems[v.Name] = v
end
for _, v in melees do
    combinedItems[v.Name] = v
end

return combinedItems