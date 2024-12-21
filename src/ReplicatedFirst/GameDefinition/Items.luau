local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ammo = require(script.Parent.Ammo)
local Types = require(script.Parent.Parent.RoundRule.Types)

local function models(name: string): BasePart
    return ReplicatedStorage:WaitForChild("WeaponModels"):WaitForChild(name) :: BasePart
end

local function weaponSounds(name: string): string
    return (ReplicatedStorage:WaitForChild("WeaponSounds"):WaitForChild(name) :: Sound).SoundId
end

local function firedSounds(name: string): string
    return (ReplicatedStorage:WaitForChild("WeaponSounds"):WaitForChild("Fired"):WaitForChild(name) :: Sound).SoundId
end

local function reloadSounds(name: string): string
    return (ReplicatedStorage:WaitForChild("WeaponSounds"):WaitForChild("Reload"):WaitForChild(name) :: Sound).SoundId
end

local function projectiles(name: string): BasePart
    return ReplicatedStorage:WaitForChild("Projectiles"):WaitForChild(name) :: BasePart
end

local bullet = projectiles("Bullet")

local guns: {[string]: Types.GunWeaponDefinition} = {}
guns.HUGE = {
    Kind = "Gun" :: "Gun",
    Name = "HUGE",

    Slot = 3,
    CanDrop = true,
    
    Spread = 2,

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

    Model = models("HUGE"),
    HoldAnimation = "12498608892",
    AimAnimation = "18691844030",

    FiredSound = firedSounds("HUGE"),
    ReloadSound = "",

    RecoilX = 1,
    RecoilY = 2,

    AmmoType = Ammo.HUGE,
}

guns.Scout = {
    Kind = "Gun" :: "Gun",
    Name = "Scout",
    
    Slot = 3,
    CanDrop = true,

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
    AmmoType = Ammo.Rifle,

    Model = models("Scout"),
    HoldAnimation = "10247529531",
    AimAnimation = "18691492037",
    FiredSound = firedSounds("Scout"),
    ReloadSound = reloadSounds("Scout"),

    RecoilX = 0.5,
    RecoilY = 1.5,
}

guns.Pistol = {
    Kind = "Gun" :: "Gun",
    Name = "Pistol",

    Slot = 2,
    CanDrop = true,

    Damage = {
        Head = 60,
        Body = 30,
        Limb = 20,
    },

    Spread = 0.25,

    FalloffStart = 55,
    FalloffEnd = 110,
    FalloffMultiplier = 0.4,

    AimFOV = 70,
    AimSpreadMultiplier = 0.1,

    FireTime = 0.5,
    ReloadTime = 1,
    AmmoType = Ammo["9mm"],

    Model = models("Pistol"),
    HoldAnimation = "9253211833",
    AimAnimation = "18691552315",
    FiredSound = firedSounds("Pistol"),
    ReloadSound = reloadSounds("Pistol"),

    ProjectileBase = bullet,
    ProjectileSpeed = 100,

    RecoilX = 0.2,
    RecoilY = 1.0,
}

guns["Golden Gun"] = {
    Kind = "Gun" :: "Gun",
    Name = "Golden Gun",
    Description = "One shot. Don't fumble it.",

    Slot = 7,
    CanDrop = true,

    Damage = {
        Head = 0,
        Body = 0,
        Limb = 0,
    },
    FalloffStart = 0,
    FalloffEnd = 0,
    FalloffMultiplier = 1,

    AmmoType = Ammo["Golden Bullet"],
    ReloadSound = "",

    Spread = 0,

    LaserColour = Color3.fromRGB(47, 47, 255),
    
    MagazineSize = 1,

    ProjectileBase = projectiles("GoldenBullet"),
    ProjectileSpeed = 250,

    Model = models("Golden Gun"),
    HoldAnimation = "9253211833",
    AimAnimation = "18691552315",
    FiredSound = firedSounds("Golden Gun"),

    FireTime = 0.5,
    ReloadTime = 0,

    AimFOV = 70,
    AimSpreadMultiplier = 0,

    BeforeHitProp = function(weapon: Types.GunWeapon, attacker: Types.Participant, target: Types.Prop)
        target:TryTakeDamage({
            Amount = math.huge,
            Attacker = attacker,
            Source = "Shot",
        })
        return true
    end,

    BeforeHitParticipant = function(weapon: Types.GunWeapon, attacker: Types.Participant, target: Types.Participant)
        if not attacker then
            return
        end

        local function makeGolden(victim: Types.Participant)
            local char = assert(victim:GetCharacter(), "Participant has no character")
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

                local sound = Instance.new("Sound")
                sound.SoundId = weaponSounds("GoldenGunHit")
                sound.Name = "DeathSound"
                sound.Parent = root
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

        if attacker:IsDamageJustifiedAgainstParticipant(target) then
            makeGolden(target)
            target:TryTakeDamage({
                Amount = math.huge,
                Attacker = attacker,
                Source = "Shot",
                IsHeadshot = false,
            })
        else
            makeGolden(attacker)
            attacker:TryTakeDamage({
                Amount = math.huge,
                Attacker = attacker,
                Source = "Shot",
                IsHeadshot = false,
            })
        end

        return true
    end,

    RecoilX = 0.0,
    RecoilY = 0.0,
}

local function burn(attacker: Types.Participant?, target: Types.Participant | Types.Prop?, part: BasePart): ()
    if not attacker then
        return
    end

    local fire = Instance.new("Fire")
    fire.Size = 10
    fire.Parent = part

    local burnSound = Instance.new("Sound")
    burnSound.SoundId = weaponSounds("FlareBurn")
    burnSound.Parent = part

    local model = part:FindFirstAncestorOfClass("Model")
    if target and target.Kind == "Prop" then
        assert(model)
        model:SetAttribute("Burning", true)
    end

    if model and model:IsDescendantOf(workspace.Corpses) then
        model:SetAttribute("Burning", true)
    end

    local endTime = workspace:GetServerTimeNow() + 10
    task.spawn(function()
        while true do
            if workspace:GetServerTimeNow() > endTime then
                break
            end

            local health: number? = if target then (target :: Types.Participant):GetHealth() else nil
            if health and health < 0 then
                break
            end
            if not part:IsDescendantOf(workspace) then
                break
            end

            burnSound:Play()

            if health then
                (target :: Types.Participant):TryTakeDamage({
                    Amount = 1,
                    Attacker = attacker,
                    Source = "Burn"
                })
            end

            task.wait(0.25)
        end
        
        if target and target.Kind == "Prop" then
            assert(model)
            model:SetAttribute("Burning", false)
        end

        burnSound:Destroy()
        fire:Destroy()

        if not target and model then
            model:Destroy()
        end
    end)
end

guns["Flare Gun"] = {
    Kind = "Gun" :: "Gun",
    Name = "Flare Gun",
    Description = "Ouch fire hot.",

    Slot = 8,
    CanDrop = true,

    Damage = {
        Head = 15,
        Body = 10,
        Limb = 5,
    },

    AmmoType = Ammo.Flare,
    ReloadSound = "",

    FalloffStart = 35,
    FalloffEnd = 80,
    FalloffMultiplier = 0.5,

    Spread = 1,
    
    FireTime = 0.25,
    ReloadTime = 0,
    MagazineSize = 6,

    Model = models("Flare Gun"),
    HoldAnimation = "9253211833",
    AimAnimation = "18691552315",
    FiredSound = firedSounds("Flare Gun"),

    ProjectileBase = projectiles("Flare"),
    ProjectileSpeed = 140,

    AimFOV = 60,
    AimSpreadMultiplier = 0.3,

    BeforeHitParticipant = function(weapon: Types.GunWeapon, attacker: Types.Participant, target: Types.Participant)
        burn(attacker, target, assert(target:GetCharacter(), "Participant has no character").PrimaryPart :: BasePart)
        return true
    end,

    BeforeHitProp = function(weapon: Types.GunWeapon, attacker: Types.Participant, target: Types.Prop)
        local part = target.Model
        if not part or not part:IsA("BasePart") then
            return false
        end

        burn(attacker, target, part)
        return true
    end,

    BeforeHitCorpse = function(weapon: Types.GunWeapon, attacker: Types.Participant, part: BasePart)
        if not part.Parent then
            return false
        end

        local root = part.Parent:FindFirstChild("HumanoidRootPart")
        if not root or not root:IsA("BasePart") then
            return false
        end

        burn(attacker, nil, root)
        return true
    end,

    RecoilX = 0.8,
    RecoilY = 1.2,
}

guns.SMG = {
    Kind = "Gun" :: "Gun",
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
    
    FireTime = 0.05,
    ReloadTime = 1,
    AmmoType = Ammo.SMG1,

    Model = models("SMG"),
    HoldAnimation = "12481091962",
    AimAnimation = "18691799004",
    FiredSound = firedSounds("SMG"),
    ReloadSound = reloadSounds("SMG"),

    ProjectileBase = bullet,
    ProjectileSpeed = 140,

    AimFOV = 60,
    AimSpreadMultiplier = 0.3,

    RecoilX = 0.5,
    RecoilY = 1,
}

guns.AWP = {
    Kind = "Gun" :: "Gun",
    Name = "AWP",
    Description = "A high-powered sniper rifle. Must be scoped in to shoot.",
    
    Slot = 7,
    CanDrop = true,

    Damage = {
        Head = 300,
        Body = 100,
        Limb = 65,
    },

    AmmoType = Ammo.AWP,
    ReloadSound = "",

    FalloffStart = 200,
    FalloffEnd = 400,
    FalloffMultiplier = 0.5,

    AimFOV = 10,
    AimSpreadMultiplier = 0.05,
    ScopeRequired = true,
    HasScope = true,

    Spread = 0.25,

    FireTime = 2,
    ReloadTime = 0,
    MagazineSize = 4,

    Model = models("AWP"),
    HoldAnimation = "10247529531",
    AimAnimation = "18691492037",
    FiredSound = firedSounds("AWP"),

    ProjectileBase = bullet,
    ProjectileSpeed = 300,

    RecoilX = 0.8,
    RecoilY = 2.5,
}

guns["Assault Rifle"] = {
    Kind = "Gun" :: "Gun",
    Name = "Assault Rifle",

    Slot = 3,
    CanDrop = true,

    Spread = 0.5,

    Damage = {
        Head = 60,
        Body = 30,
        Limb = 20,
    },

    FireTime = 0.15,
    ReloadTime = 1.5,
    AmmoType = Ammo["9mm"],

    AimFOV = 50,
    AimSpreadMultiplier = 0.25,

    Model = models("Assault Rifle"),
    HoldAnimation = "10247380824",
    AimAnimation = "18691831450",
    FiredSound = firedSounds("Assault Rifle"),
    ReloadSound = reloadSounds("Assault Rifle"),

    FalloffStart = 75,
    FalloffEnd = 125,
    FalloffMultiplier = 0.5,

    ProjectileBase = bullet,
    ProjectileSpeed = 150,

    RecoilX = 0.6,
    RecoilY = 1.5,
}

guns["Silenced Pistol"] = {
    Kind = "Gun" :: "Gun",
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

    FalloffStart = 55,
    FalloffEnd = 110,
    FalloffMultiplier = 0.4,
    
    AimFOV = 70,
    AimSpreadMultiplier = 0.1,

    FireTime = 0.5,
    ReloadTime = 1,
    AmmoType = Ammo["9mm"],

    Model = models("Silenced Pistol"),
    HoldAnimation = "9253211833",
    AimAnimation = "18691552315",
    FiredSound = firedSounds("Silenced Pistol"),
    ReloadSound = reloadSounds("Silenced Pistol"),

    ProjectileBase = projectiles("SilencedBullet"),
    ProjectileSpeed = 100,

    BeforeHitParticipant = function(_, victim: Types.Participant)
        local root = assert(victim:GetCharacter(), "Participant has no character").PrimaryPart
        if not root then
            return
        end

        local deathSound = root:FindFirstChild("DeathSound") :: Sound?
        if deathSound then
            deathSound.Volume = 0
        end
        return
    end,

    RecoilX = 0.2,
    RecoilY = 1.0,
}

guns.XM1014 = {
    Kind = "Gun" :: "Gun",
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

    FireTime = 0.8,
    ReloadTime = 1.5,
    AmmoType = Ammo.Shotgun,

    BulletsPerShot = 6,

    ProjectileBase = bullet,
    ProjectileSpeed = 150,

    Model = models("XM1014"),
    HoldAnimation = "11436160569",
    AimAnimation = "18691725191",
    FiredSound = firedSounds("XM1014"),
    ReloadSound = reloadSounds("XM1014"),

    RecoilX = 1.0,
    RecoilY = 2.0,
}

guns.Glock = {
    Kind = "Gun" :: "Gun",
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

    Spread = 0.35,

    FireTime = 0.1,
    ReloadTime = 1,
    AmmoType = Ammo["9mm"],

    Model = models("Glock"),
    HoldAnimation = "9253211833",
    AimAnimation = "18691552315",
    FiredSound = firedSounds("Glock"),
    ReloadSound = reloadSounds("Glock"),

    ProjectileBase = bullet,
    ProjectileSpeed = 190,

    RecoilX = 0.2,
    RecoilY = 0.8,
}

guns.Deagle = {
    Kind = "Gun" :: "Gun",
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

    Spread = 0.25,

    FireTime = 0.5,
    ReloadTime = 1.2,
    AmmoType = Ammo.Deagle,

    ProjectileBase = bullet,
    ProjectileSpeed = 190,

    Model = models("Deagle"),
    HoldAnimation = "9253211833",
    AimAnimation = "18691552315",
    FiredSound = firedSounds("Deagle"),
    ReloadSound = reloadSounds("Deagle"),

    RecoilX = 0.3,
    RecoilY = 1.2,
}

guns.BAR = {
    Kind = "Gun" :: "Gun",
    Name = "BAR",

    Slot = 3,
    CanDrop = true,

    Damage = {
        Head = 75,
        Body = 40,
        Limb = 25,
    },

    Spread = 0.75,

    FalloffStart = 50,
    FalloffEnd = 120,
    FalloffMultiplier = 0.3,

    FireTime = 0.1,
    ReloadTime = 2.5,
    AmmoType = Ammo["9mm"],

    Model = models("BAR"),
    HoldAnimation = "10247380824",
    AimAnimation = "18691831450",
    FiredSound = firedSounds("BAR"),
    ReloadSound = reloadSounds("BAR"),

    ProjectileBase = bullet,
    ProjectileSpeed = 120,

    AimFOV = 65,
    AimSpreadMultiplier = 0.2,

    RecoilX = 0.6,
    RecoilY = 1.8,
}

local allItems: {[string]: Types.AnyItemDefinition} = {}

for i, v in guns do
    allItems[i] = v
end

return allItems