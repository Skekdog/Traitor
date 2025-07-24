local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Discombobulate = require(ReplicatedStorage.Shared.GameDefinition.Items.Common.Discombobulate)
local CreateEmptyPart = require(ReplicatedStorage.Shared.RoundRule.Common.CreateEmptyPart)
local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)
local Ammo = require(script.Parent.Ammo)
local BallisticVest = require(script.Parent.BallisticVest)
local Binoculars = require(script.Parent.Binoculars)
local Crowbar = require(script.Parent.Crowbar)
local DNAScanner = require(script.Parent.DNAScanner)
local Defuser = require(script.Parent.Defuser)
local Disguiser = require(script.Parent.Disguiser)
local FlareGun = require(script.Parent.FlareGun)
local Knife = require(script.Parent.Knife)
local MagnetoStick = require(script.Parent.MagnetoStick)
local NewtonLauncher = require(script.Parent.NewtonLauncher)
local Poltergeist = require(script.Parent.Poltergeist)
local Radar = require(script.Parent.Radar)
local Teleporter = require(script.Parent.Teleporter)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local function models(name: string): BasePart
    return ReplicatedStorage.Assets:WaitForChild("WeaponModels"):WaitForChild(name) :: BasePart
end

local function interactableModels(name: string): BasePart
	return ReplicatedStorage.Assets:WaitForChild("InteractableModels"):WaitForChild(name) :: BasePart
end

local function weaponSounds(name: string): Sound
    return (ReplicatedStorage.Assets:WaitForChild("WeaponSounds"):WaitForChild(name) :: Sound)
end

local function firedSounds(name: string): Sound
    return (ReplicatedStorage.Assets:WaitForChild("WeaponSounds"):WaitForChild("Fired"):WaitForChild(name) :: Sound)
end

local function reloadSounds(name: string): Sound
    return (ReplicatedStorage.Assets:WaitForChild("WeaponSounds"):WaitForChild("Reload"):WaitForChild(name) :: Sound)
end

local function projectiles(name: string): BasePart
    return ReplicatedStorage.Assets:WaitForChild("Projectiles"):WaitForChild(name) :: BasePart
end

local function modify(base: Types.AnyItemDefinition, name: string, edit: {[string]: any}): Types.AnyItemDefinition
    local new = table.clone(base)
    for i, v in edit do
        new[i] = v
    end

    new.Name = name

    if base.Model then
        new.Model = base.Model:Clone()
        new.Model.Name = name
        new.Model.Parent = ReplicatedStorage.Assets.WeaponModels
    end

    return new
end

local bullet = projectiles("Bullet")

local flashbangEqualiser = Instance.new("EqualizerSoundEffect")
flashbangEqualiser.Name = "FlashbangEffect"
flashbangEqualiser.HighGain = -8
flashbangEqualiser.LowGain = 10
flashbangEqualiser.MidGain = -20
flashbangEqualiser.Enabled = true

local flashbangTweenStart = TweenInfo.new(0.15)
local flashbangTweenFinish = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 4)

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

        local sound = weaponSounds("GoldenGunHit"):Clone()
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

local guns: {[string]: Types.GunWeaponDefinition} = {}
guns.HUGE = {
    Kind = "Gun" :: "Gun",
    Name = "HUGE",

    Slot = 3,
    CanDrop = true,
    
    Spread = 0.04,
    HasMuzzleFlash = true,

    Damage = {
        Head = 15,
        Body = 10,
        Limb = 5,
    },

    AimFOV = 60,
    AimSpreadMultiplier = 0.3,

    AttackInterval = 0.01,
    ReloadTime = 0,
    MagazineSize = 250,

    Projectile = bullet,
    ProjectileSpeed = 140,

    Model = models("HUGE"),
    HoldAnimation = "rbxassetid://12498608892",
    AimAnimation = "rbxassetid://18691844030",

    AttackSound = firedSounds("HUGE"),

    RecoilX = 1,
    RecoilY = 2,

    AmmoType = Ammo.HUGE,
}

guns.Scout = {
    Kind = "Gun" :: "Gun",
    Name = "Scout",
    
    Slot = 3,
    CanDrop = true,

    Spread = 0,
    HasMuzzleFlash = true,

    AimFOV = 30,
    AimSpreadMultiplier = 0.05,
    HasScope = true,

    Damage = {
        Body = 50,
        Limb = 25,
        Head = 150,
    },

    Projectile = bullet,
    ProjectileSpeed = 250,

    AttackInterval = 1,
    ReloadTime = 1.5,
    AmmoType = Ammo.Rifle,

    Model = models("Scout"),
    HoldAnimation = "rbxassetid://10247529531",
    AimAnimation = "rbxassetid://18691492037",
    AttackSound = firedSounds("Scout"),
    ReloadSound = reloadSounds("Scout"),

    RecoilX = 0.5,
    RecoilY = 1.5,
}

guns.Pistol = {
    Kind = "Gun" :: "Gun",
    Name = "Pistol",
    DisplayName = "Five-Seven",

    Slot = 2,
    CanDrop = true,

    Damage = {
        Head = 60,
        Body = 30,
        Limb = 20,
    },

    Spread = 0.01,
    HasMuzzleFlash = true,

    AimFOV = 70,
    AimSpreadMultiplier = 0.1,

    AttackInterval = 0.5,
    ReloadTime = 1,
    AmmoType = Ammo["9mm"],

    Model = models("Pistol"),
    HoldAnimation = "rbxassetid://9253211833",
    AimAnimation = "rbxassetid://18691552315",
    AttackSound = firedSounds("Pistol"),
    ReloadSound = reloadSounds("Pistol"),

    Projectile = bullet,
    ProjectileSpeed = 100,

    RecoilX = 0.2,
    RecoilY = 1.0,
}

guns["Golden Gun"] = {
    Kind = "Gun" :: "Gun",
    Name = "Golden Gun",
    Description = "Instantly kills any enemy. Not recommended for use against friendlies.",
    Icon = "rbxassetid://10282780102",
    CreditCost = 1,
    MaxStock = 1,

    Slot = 7,
    CanDrop = true,

    HasMuzzleFlash = true,

    Damage = {
        Head = 0,
        Body = 0,
        Limb = 0,
    },

    AmmoType = Ammo["Golden Bullet"],

    Spread = 0,

    LaserColor = Color3.fromRGB(47, 47, 255),
    
    MagazineSize = 1,

    Projectile = projectiles("GoldenBullet"),
    ProjectileSpeed = 250,

    Model = models("Golden Gun"),
    HoldAnimation = "rbxassetid://9253211833",
    AimAnimation = "rbxassetid://18691552315",
    AttackSound = firedSounds("Golden Gun"),

    AttackInterval = 0.5,
    ReloadTime = 0,

    AimFOV = 70,
    AimSpreadMultiplier = 0,

    BeforeHitProp = function(item: Types.ItemBeforeHit, _, target: Types.Prop, params: Types.DamageParams): boolean
        assert(item.Kind == "Gun")
        if target.Kind ~= "MapProp" then
            return false
        end
        
        local attacker = params.Attacker
        target:TryTakeDamage({
            Amount = math.huge,
            Attacker = attacker,
            Source = item,

            Origin = params.Origin,
            HitPosition = params.HitPosition,
            HitPart = params.HitPart,
        })
        return false
    end,

    BeforeHitParticipant = function(item: Types.ItemBeforeHit, _, target: Types.Participant, params: Types.DamageParams): boolean
        assert(item.Kind == "Gun")
        local attacker = params.Attacker
        assert(attacker)

        if attacker:IsDamageJustifiedAgainstParticipant(target) then
            makeGolden(target)
            target:TryTakeDamage({
                Amount = math.huge,
                Attacker = attacker,
                Source = item,
                IsHeadshot = false,

                Origin = params.Origin,
                HitPosition = params.HitPosition,
                HitPart = params.HitPart,
            })
        else
            makeGolden(attacker)
            attacker:TryTakeDamage({
                Amount = math.huge,
                Attacker = attacker,
                Source = item,
                IsHeadshot = false,

                Origin = params.Origin,
            })
        end

        return false
    end,

    RecoilX = 0.0,
    RecoilY = 0.0,
}

guns["Flare Gun"] = FlareGun

guns.SMG = {
    Kind = "Gun" :: "Gun",
    Name = "SMG",
    DisplayName = "M11",

    Slot = 3,
    CanDrop = true,
    
    Damage = {
        Head = 25,
        Body = 20,
        Limb = 15,
    },

    Spread = 0.02,
    HasMuzzleFlash = true,
    
    AttackInterval = 0.05,
    ReloadTime = 1,
    AmmoType = Ammo.SMG1,

    Model = models("SMG"),
    HoldAnimation = "rbxassetid://12481091962",
    AimAnimation = "rbxassetid://18691799004",
    AttackSound = firedSounds("SMG"),
    ReloadSound = reloadSounds("SMG"),

    Projectile = bullet,
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
    Icon = "rbxassetid://4772214897",
    MaxStock = 1,
    
    IsBadGuyItem = true,
    
    Slot = 7,
    CreditCost = 1,
    CanDrop = true,

    Damage = {
        Head = 300,
        Body = 100,
        Limb = 65,
    },

    AmmoType = Ammo.AWP,

    HasMuzzleFlash = true,

    AimFOV = 10,
    AimSpreadMultiplier = 0.05,
    ScopeRequired = true,
    HasScope = true,

    Spread = 0,

    AttackInterval = 2,
    ReloadTime = 0,
    MagazineSize = 4,

    Model = models("AWP"),
    HoldAnimation = "rbxassetid://10247529531",
    AimAnimation = "rbxassetid://18691492037",
    AttackSound = firedSounds("AWP"),

    Projectile = bullet,
    ProjectileSpeed = 300,

    RecoilX = 0.8,
    RecoilY = 2.5,
}

guns["Assault Rifle"] = {
    Kind = "Gun" :: "Gun",
    Name = "Assault Rifle",
    DisplayName = "M4A1",

    Slot = 3,
    CanDrop = true,

    Spread = 0.015,

    Damage = {
        Head = 60,
        Body = 30,
        Limb = 20,
    },

    AttackInterval = 0.15,
    ReloadTime = 1.5,
    AmmoType = Ammo["9mm"],

    HasMuzzleFlash = true,

    AimFOV = 50,
    AimSpreadMultiplier = 0.25,

    Model = models("Assault Rifle"),
    HoldAnimation = "rbxassetid://10247380824",
    AimAnimation = "rbxassetid://18691831450",
    AttackSound = firedSounds("Assault Rifle"),
    ReloadSound = reloadSounds("Assault Rifle"),

    Projectile = bullet,
    ProjectileSpeed = 150,

    RecoilX = 0.6,
    RecoilY = 1.5,
}

guns["Silenced Pistol"] = {
    Kind = "Gun" :: "Gun",
    Name = "Silenced Pistol",
    Description = "A Five-Seven that has had a suppressor fitted to it, making it much quieter. People killed with silenced weapons will not scream.",
    Icon = "rbxassetid://299432421",
    CreditCost = 1,
    MaxStock = 3,

    IsBadGuyItem = true,

    Slot = 7,
    CanDrop = true,

    Damage = {
        Head = 60,
        Body = 30,
        Limb = 20,
    },

    Spread = 0.01,

    HasMuzzleFlash = false,
    
    AimFOV = 70,
    AimSpreadMultiplier = 0.1,

    AttackInterval = 0.5,
    ReloadTime = 1,
    AmmoType = Ammo["9mm"],

    Model = models("Silenced Pistol"),
    HoldAnimation = "rbxassetid://9253211833",
    AimAnimation = "rbxassetid://18691552315",
    AttackSound = firedSounds("Silenced Pistol"),
    ReloadSound = reloadSounds("Silenced Pistol"),

    Projectile = projectiles("SilencedBullet"),
    ProjectileSpeed = 100,

    BeforeHitParticipant = function(_, _, victim: Types.Participant, params: Types.DamageParams): boolean
        local willDie = params.Amount >= victim:GetHealth()
        if not willDie then
            return true
        end

        local root = assert(victim:GetCharacter(), "Participant has no character").PrimaryPart
        if not root then
            return true
        end

        local deathSound = root:FindFirstChild("DeathSound")
        if deathSound and deathSound:IsA("Sound") then
            deathSound.Volume = 0
        end

        return true
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

    HasMuzzleFlash = true,

    AimFOV = 50,
    AimSpreadMultiplier = 0.7,

    Spread = 0.03,

    AttackInterval = 0.8,
    ReloadTime = 1.5,
    AmmoType = Ammo.Shotgun,

    BulletsPerShot = 6,

    Projectile = bullet,
    ProjectileSpeed = 150,

    Model = models("XM1014"),
    HoldAnimation = "rbxassetid://11436160569",
    AimAnimation = "rbxassetid://18691725191",
    AttackSound = firedSounds("XM1014"),
    ReloadSound = reloadSounds("XM1014"),

    RecoilX = 1.0,
    RecoilY = 2.0,
}

guns.Glock = {
    Kind = "Gun" :: "Gun",
    Name = "Glock",
    DisplayName = "G18",

    Slot = 2,
    CanDrop = true,

    Damage = {
        Head = 20,
        Body = 15,
        Limb = 10,
    },

    HasMuzzleFlash = true,

    AimFOV = 70,
    AimSpreadMultiplier = 0.1,

    Spread = 0.01,

    AttackInterval = 0.1,
    ReloadTime = 1,
    AmmoType = Ammo["9mm"],

    Model = models("Glock"),
    HoldAnimation = "rbxassetid://9253211833",
    AimAnimation = "rbxassetid://18691552315",
    AttackSound = firedSounds("Glock"),
    ReloadSound = reloadSounds("Glock"),

    Projectile = bullet,
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

    HasMuzzleFlash = true,

    AimFOV = 50,
    AimSpreadMultiplier = 0.1,

    Spread = 0,

    AttackInterval = 0.5,
    ReloadTime = 1.2,
    AmmoType = Ammo.Deagle,

    Projectile = bullet,
    ProjectileSpeed = 190,

    Model = models("Deagle"),
    HoldAnimation = "rbxassetid://9253211833",
    AimAnimation = "rbxassetid://18691552315",
    AttackSound = firedSounds("Deagle"),
    ReloadSound = reloadSounds("Deagle"),

    RecoilX = 0.3,
    RecoilY = 1.2,
}

guns.UMP = {
    Kind = "Gun" :: "Gun",
    Name = "UMP",
    Description = "A weak weapon standalone, but loaded with discombobulation. Targets will be disorientated when hit. Uses SMG rounds.",
    Icon = "rbxassetid://8482220999",

    MaxStock = 2,
    CreditCost = 1,
    CanDrop = true,
    Slot = 7,

    HasMuzzleFlash = true,

    Damage = {
        Head = 25,
        Body = 15,
        Limb = 10,
    },

    Spread = 0.01,

    AttackInterval = 0.1,
    ReloadTime = 1.5,
    AmmoType = Ammo["SMG1"],

    Model = models("UMP"),
    HoldAnimation = "rbxassetid://10247380824",
    AimAnimation = "rbxassetid://18691831450",
    AttackSound = firedSounds("UMP"),
    ReloadSound = reloadSounds("UMP"),

    Projectile = bullet,
    ProjectileSpeed = 150,

    OnHitClient = Discombobulate,

    RecoilX = 0.75,
    RecoilY = 1.75,
}

guns.BAR = {
    Kind = "Gun" :: "Gun",
    Name = "BAR",
    Description = "A powerful mid-range rifle. Slow to reload.",
    Icon = "rbxassetid://10243797417",
    MaxStock = 3,

    IsBadGuyItem = true,

    Slot = 3,
    CreditCost = 1,
    CanDrop = true,

    HasMuzzleFlash = true,

    Damage = {
        Head = 75,
        Body = 40,
        Limb = 25,
    },

    Spread = 0.02,

    AttackInterval = 0.1,
    ReloadTime = 2.5,
    AmmoType = Ammo["9mm"],

    Model = models("BAR"),
    HoldAnimation = "rbxassetid://10247380824",
    AimAnimation = "rbxassetid://18691831450",
    AttackSound = firedSounds("BAR"),
    ReloadSound = reloadSounds("BAR"),

    Projectile = bullet,
    ProjectileSpeed = 120,

    AimFOV = 65,
    AimSpreadMultiplier = 0.2,

    RecoilX = 0.6,
    RecoilY = 1.8,
}

guns["Newton Launcher"] = NewtonLauncher.Item
guns["Poltergeist"] = Poltergeist

local grenades: {[string]: Types.GrenadeWeaponDefinition} = {}
grenades.Grenade = {
    Kind = "Grenade" :: "Grenade",
    Name = "Grenade",
    Description = "Explodes in a good radius after 5 seconds.",
    Icon = "rbxassetid://8096856961",
    CreditCost = 2,
    MaxStock = 2,

    IsBadGuyItem = true,

    Slot = 7,
    CanDrop = true,

    Projectile = projectiles("Grenade"),
    Model = models("Grenade"),
    HoldAnimation = "rbxassetid://12498620263",

    ExplosionInfo = {
        Damage = 200,
        FalloffBegin = 5,
        FalloffEnd = 17,
        Pressure = 50000,
        VisualRadius = 17,
    },

    FuseTime = 5,

    ProjectileForce = 0.75,

    AttackSound = firedSounds("Grenade"),
}

grenades.Flashbang = {
    Kind = "Grenade" :: "Grenade",
    Name = "Flashbang",
    Description = "Explodes in a good radius after 3 seconds, blinding and deafening anyone in range.",
    Icon = "rbxassetid://10753198321",
    MaxStock = 2,

    Slot = 8,
    CreditCost = 1,
    CanDrop = true,

    Projectile = projectiles("Flashbang"),
    Model = models("Flashbang"),
    HoldAnimation = "rbxassetid://12498620263",

    ExplosionInfo = {
        Damage = 0,
        FalloffBegin = 0,
        FalloffEnd = 15,
        Pressure = 10000,
        VisualRadius = 15,
    },

    OnHitClient = function()
        local correction = Instance.new("ColorCorrectionEffect")
        local blur = Instance.new("BlurEffect")

        correction.Name = "FlashbangCorrection"
        blur.Name = "FlashbangBlur"

        correction:SetAttribute("IgnoreLighting", true)
        blur:SetAttribute("IgnoreLighting", true)

        blur.Parent = Lighting
        correction.Parent = Lighting

        local equaliser = Instance.fromExisting(flashbangEqualiser)
        equaliser.Parent = SoundService:FindFirstChild("AllSounds")

        local tween = TweenService:Create(correction, flashbangTweenStart, {Brightness = 0.8})
        tween.Completed:Once(function()
            local endTween = TweenService:Create(correction, flashbangTweenFinish, {Brightness = 0})
            endTween.Completed:Once(function()
                blur:Destroy()
                correction:Destroy()
                equaliser:Destroy()
            end)
            endTween:Play()
            TweenService:Create(blur, flashbangTweenFinish, {Size = 0}):Play()
        end)
        tween:Play()
        TweenService:Create(blur, flashbangTweenStart, {Size = 48}):Play()

        PlaySound("rbxassetid://223471024", nil, nil)
    end,

    FuseTime = 3,

    ProjectileForce = 30,

    AttackSound = firedSounds("Grenade"),
}

grenades["Incendiary Grenade"] = {
    Kind = "Grenade" :: "Grenade",
    Name = "Incendiary Grenade",

    Slot = 4,
    CanDrop = true,

    Projectile = projectiles("Incendiary Grenade"),
    HoldAnimation = "rbxassetid://12498620263",
    Model = models("Incendiary Grenade"),

    ExplosionInfo = {
        Damage = 10,
        FalloffBegin = 0,
        FalloffEnd = 15,
        Pressure = 10000,
        VisualRadius = 15,
    },

    OnExplode = function(weapon: Types.GrenadeWeapon, attacker: Types.Participant, projectile: BasePart)
        if not attacker then
            return
        end

        local firePart = CreateEmptyPart(CFrame.new(projectile.Position), nil, false, true, true)
        firePart.Size = Vector3.new(15, 1, 15)
        firePart.Parent = workspace.Projectiles

        local overlapParams = OverlapParams.new()
        overlapParams.FilterDescendantsInstances = {workspace.Characters}
        overlapParams.FilterType = Enum.RaycastFilterType.Include
        overlapParams.RespectCanCollide = false

        task.spawn(function()
            while firePart:IsDescendantOf(workspace) do
                local found: {Model} = {}
                for _, v in workspace:GetPartBoundsInBox(firePart.CFrame, firePart.Size, overlapParams) do
                    local model = v:FindFirstAncestorOfClass("Model")
                    if not model or table.find(found, model) then
                        continue
                    end
                    table.insert(found, model)

                    local plr = Players:GetPlayerFromCharacter(model)
                    if not plr then
                        continue
                    end

                    local participant = attacker.Round:GetParticipant(plr.Name)
                    if not participant or not participant:GetCharacter() then
                        continue
                    end

                    PlaySound(ReplicatedStorage.Assets.WeaponSounds.FlareBurn, nil, v, {SoundGroup = SoundService.AllSounds :: SoundGroup})
                    participant:TryTakeDamage({
                        Amount = 1,
                        Source = "Burn",
                    })
                end
                task.wait(0.1)
            end
        end)

        local fire = Instance.new("Fire")
        fire.Size = 40
        fire.Parent = firePart

        task.delay(30, firePart.Destroy, firePart)
    end,

    FuseTime = 3,

    ProjectileForce = 60,

    AttackSound = firedSounds("Grenade"),
}

grenades["Smoke Grenade"] = {
    Kind = "Grenade" :: "Grenade",
    Name = "Smoke Grenade",

    Slot = 4,
    CanDrop = true,

    HoldAnimation = "rbxassetid://12498620263",
    Model = models("Smoke Grenade"),

    ExplosionInfo = {
        Damage = 0,
        FalloffBegin = 0,
        FalloffEnd = 15,
        Pressure = 10000,
        VisualRadius = 15,
    },

    OnExplode = function(weapon: Types.GrenadeWeapon, attacker: Types.Participant, projectile: BasePart)
        local smoke = Instance.new("Smoke")
        smoke.Size = 20
        smoke.Opacity = 1
        smoke.RiseVelocity = 5
        
        local smokePart = CreateEmptyPart(CFrame.new(projectile.Position))
        smoke.Parent = smokePart
        smokePart.Parent = workspace.Projectiles

        task.delay(30, smokePart.Destroy, smokePart)
    end,

    FuseTime = 3,

    Projectile = models("Smoke Grenade"),
    ProjectileForce = 60,

    AttackSound = firedSounds("Grenade"),
}

grenades["Discombobulator"] = {
    Kind = "Grenade" :: "Grenade",
    Name = "Discombobulator",

    Slot = 4,
    CanDrop = true,

    Projectile = projectiles("Discombobulator"),
    HoldAnimation = "rbxassetid://12498620263",
    Model = models("Discombobulator"),

    ExplosionInfo = {
        Damage = 0,
        FalloffBegin = 0,
        FalloffEnd = 15,
        Pressure = 75000,
        VisualRadius = 15,
    },
    
    OnHitClient = Discombobulate,

    FuseTime = 3,

    ProjectileForce = 60,

    AttackSound = firedSounds("Grenade"),
}

local melees: {[string]: Types.MeleeWeaponDefinition} = {}

melees.Crowbar = Crowbar.Item
melees.Knife = Knife

local items: {[string]: Types.ItemDefinition} = {}
items["Magneto Stick"] = MagnetoStick.Item

items.DNAScanner = DNAScanner.Item

items.Teleporter = Teleporter

items.Radar = Radar

items.Defuser = Defuser

items.Binoculars = Binoculars.Item

items["Ballistic Vest"] = BallisticVest.Item

items.Disguiser = Disguiser.Item

local function createInteractableForItem(item: Types.Item, round: Types.Round): Types.Interactable
    local interactableDefinition = round:GetInteractableDefinition(item.Definition.Name)
    assert(interactableDefinition, "Could not find interactable definition for " .. item.Definition.Name)
    return round:AddInteractable(interactableDefinition)
end

local function throwInteractable(item: Types.Item, mode: "Primary" | "Alternate", origin: Vector3, direction: Vector3, participant: Types.Participant): Types.Interactable?
    local round = participant.Round

    local interactable = createInteractableForItem(item, round)
    local success = participant:TryThrowAssembly(interactable.Object, 10, nil, nil, direction, true)

    if not success then
        round._interactables[interactable.Object] = nil
        interactable.Object:Destroy()
        return nil
    end

    participant:RemoveItem(item)

    return interactable
end

local function plantInteractable(item: Types.Item, origin: Vector3, direction: Vector3, participant: Types.Participant): (Types.Interactable?, RaycastResult?, WeldConstraint?)
    local params = RaycastParams.new()
    params.CollisionGroup = "WeaponHitTargets"
    params.FilterDescendantsInstances = {workspace.Characters, workspace.Projectiles}
    params.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(origin, direction * 10, params)
    if not result then
        return nil
    end

    local map = participant.Round:GetMap()

    if not result.Instance:IsDescendantOf(map.StaticMap) then
        return nil
    end

    local interactable = createInteractableForItem(item, participant.Round)
    local object = interactable.Object

    object.CFrame = CFrame.lookAt(result.Position, result.Position + result.Normal)

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = result.Instance :: BasePart
    weld.Part1 = object
    weld.Parent = object

    participant:RemoveItem(item)

    return interactable, result, weld
end

items.C4 = {
    Kind = "Item" :: "Item",
    Name = "C4",
    Slot = 7,
    CanDrop = true,

    IsBadGuyItem = true,

    Description = "Explodes in a massive radius after a set timer.",
    Icon = "rbxassetid://17229908151",

	Model = interactableModels("C4"),
    HoldAnimation = "rbxassetid://92236433436790",

    CreditCost = 1,
    MaxStock = 2,

    PrimaryHint = "Throw C4",
    AlternateHint = "Plant C4",

    PrimaryToggled = true,
    AlternateToggled = true,

    PrimaryFireServer = throwInteractable,
    AlternateFireServer = function(item: Types.Item, mode: "Primary" | "Alternate", origin: Vector3, direction: Vector3, participant: Types.Participant): ()
        local interactable, result, weld = plantInteractable(item, origin, direction, participant)
        if not interactable or not result or not weld then
            return
        end

        local object = interactable.Object

        weld.Enabled = false
        object.CFrame *= CFrame.Angles(math.rad(-90), 0, 0)
		object.CFrame += result.Normal / 4
        weld.Enabled = true
    end
}

items.Visualiser = {
    Kind = "Item" :: "Item",
    Name = "Visualiser",
    Slot = 8,
    CanDrop = true,

    Description = "Recreates the scene of a player's murder, if they were killed by bullets.",
    Icon = "rbxassetid://11817043651",

    CreditCost = 1,
    MaxStock = 1,

    PrimaryToggled = true,
    PrimaryHint = "Deploy Visualiser",
    PrimaryFireServer = function(item: Types.Item, mode: "Primary" | "Alternate", origin: Vector3, direction: Vector3, participant: Types.Participant): ()
        local interactable = throwInteractable(item, mode, origin, direction, participant)
        if not interactable then
            return
        end

        interactable.Extras.Player = participant.Player
    end
}

items.Radio = {
    Kind = "Item" :: "Item",
    Name = "Radio",
    Slot = 8,
    CanDrop = false,

    Description = "Remotely plays a sound to confuse nearby spies.",
    Icon = "rbxassetid://128627317841330",

    CreditCost = 1,
    MaxStock = 1,

    PrimaryToggled = true,
    PrimaryHint = "Deploy Radio",
    PrimaryFireServer = function(item: Types.Item, mode: "Primary" | "Alternate", origin: Vector3, direction: Vector3, participant: Types.Participant): ()
        local interactable = throwInteractable(item, mode, origin, direction, participant)
        if not interactable then
            return
        end

        interactable.Extras.Player = participant.Player
        DNAScanner.AddDNATrace(interactable, participant, nil, "rbxassetid://128627317841330", interactable.Object)
    end,
}

items.HealthStation = {
    Kind = "Item" :: "Item",
    Name = "HealthStation",
    DisplayName = "Health Station",
    Slot = 8,
    CanDrop = true,

    Description = "Can be used by anyone to restore health, with a slow recharge.",
    Icon = "rbxassetid://93284379186217",
    IsPixelIcon = true,

    CreditCost = 1,
    MaxStock = 1,

    PrimaryToggled = true,
    PrimaryHint = "Deploy Health Station",
    PrimaryFireServer = throwInteractable,
}

items.DeathStation = {
    Kind = "Item" :: "Item",
    Name = "DeathStation",
    DisplayName = "Death Station",
    Slot = 8,
    CanDrop = true,

    Description = "Visually mimics a health station. Can be used by good guys to die.",
    Icon = "rbxassetid://109445031317494",
    IsPixelIcon = true,

    CreditCost = 1,
    MaxStock = 1,

    PrimaryToggled = true,
    PrimaryHint = "Deploy Death Station",
    PrimaryFireServer = function(item: Types.Item, mode: "Primary" | "Alternate", origin: Vector3, direction: Vector3, participant: Types.Participant): ()
        local interactable = throwInteractable(item, mode, origin, direction, participant)
        if not interactable then
            return
        end

        interactable.Extras.Owner = participant

        DNAScanner.AddDNATrace(interactable, participant, nil, "rbxassetid://93284379186217", interactable.Object)
    end,
}

items.Decoy = {
    Kind = "Item" :: "Item",
    Name = "Decoy",
    Slot = 8,
    CanDrop = false,

    CreditCost = 1,
    MaxStock = 1,

    Description = "When placed, overrides your shown position on radars. Can be destroyed.",
    Icon = "rbxassetid://96906503847712",

    AlternateToggled = true,
    AlternateHint = "Plant Decoy",

    AlternateFireServer = function(item: Types.Item, mode: "Primary" | "Alternate", origin: Vector3, direction: Vector3, participant: Types.Participant): ()
        local interactable, _, weld = plantInteractable(item, origin, direction, participant)
        if not interactable or not weld then
            return
        end

        local object = interactable.Object
        weld.Enabled = false
        object.CFrame *= CFrame.new(0, 0, -interactable.Object.Size.Z / 2)
        weld.Enabled = true

        interactable.Object:SetAttribute("Player", participant.Player.Name)
        DNAScanner.AddDNATrace(interactable, participant, nil, "rbxassetid://96906503847712", interactable.Object)
    end
}

local allItems: {[string]: Types.AnyItemDefinition} = {}

for i, v in guns do
    allItems[i] = v
end

for i, v in grenades do
    allItems[i] = v
end

for i, v in melees do
    allItems[i] = v
end

for i, v in items do
    allItems[i] = v
end

allItems["Super Shotgun"] = modify(guns.XM1014, "Super Shotgun", {
    AttackInterval = 0,
    AmmoType = Ammo["Super Gun"]
})

allItems["Golden Gone"] = modify(guns["Golden Gun"], "Golden Gone", {
    AttackInterval = 0,
    AmmoType = Ammo["Super Gun"]
})

return allItems