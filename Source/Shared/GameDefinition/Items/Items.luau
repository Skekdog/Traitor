local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local MakeGolden = require(ReplicatedStorage.API.MakeGolden)
local Discombobulate = require(ReplicatedStorage.Shared.GameDefinition.Items.Common.Discombobulate)
local ItemGroups = require(ReplicatedStorage.Shared.GameDefinition.Items.Common.ItemGroups)
local ItemKillHighlights = require(ReplicatedStorage.Shared.GameDefinition.Items.Common.ItemKillHighlights)
local CreateEmptyPart = require(ReplicatedStorage.Shared.RoundRule.Common.CreateEmptyPart)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)
local Ammo = require(script.Parent.Ammo)
local BallisticVest = require(script.Parent.BallisticVest)
local Binoculars = require(script.Parent.Binoculars)
local Crowbar = require(script.Parent.Crowbar)
local DNAScanner = require(script.Parent.DNAScanner)
local Defuser = require(script.Parent.Defuser)
local Disguiser = require(script.Parent.Disguiser)
local FlareGun = require(script.Parent.FlareGun)
local FreezeGrenade = require(script.Parent.FreezeGrenade)
local IncendiaryGrenade = require(script.Parent.IncendiaryGrenade)
local Jetpack = require(script.Parent.Jetpack)
local Knife = require(script.Parent.Knife)
local MagnetoStick = require(script.Parent.MagnetoStick)
local MelonLauncher = require(script.Parent.MelonLauncher)
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
        new.Model = base.Model:Clone();
        (new.Model :: PVInstance).Name = name;
        (new.Model :: PVInstance).Parent = ReplicatedStorage.Assets.WeaponModels
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

local guns: {[string]: Types.GunWeaponDefinition} = {}
guns.HUGE = {
    Kind = "Gun" :: "Gun",
    Name = "HUGE",

    ItemGroup = ItemGroups.Primary,
    CanDrop = true,

    Spread = 0.1,
    HasMuzzleFlash = true,

    Damage = {
        Head = 10,
        Body = 5,
        Limb = 2,
    },

    AimFOV = 60,
    AimSpreadMultiplier = 0.9,

    AttackInterval = 0.01,
    ReloadTime = 0,
    MagazineSize = 250,

    Projectile = bullet,
    ProjectileSpeed = 280,

    ImpulseForce = 1,

    Model = models("HUGE"),
    HoldAnimation = "rbxassetid://12498608892",
    AimAnimation = "rbxassetid://18691844030",

    AttackSound = firedSounds("HUGE"),

    RecoilX = 1.5,
    RecoilY = 2.5,

    AmmoType = Ammo.HUGE,

    BeforeHitParticipant = ItemKillHighlights(
        {
            Title = "A HUGE Spread",
            Description = "%s was in tune with their HUGE, somehow managing to make their bullets hit %d people.",
            Priority = 1,
            Threshold = 2,
        },
        {
            Title = "A Patient Para",
            Description = "%s just kept firing, and saw their HUGE patience rewarded with %d kills.",
            Priority = 3,
            Threshold = 4,
        }
    )
}

guns.Scout = {
    Kind = "Gun" :: "Gun",
    Name = "Scout",

    ItemGroup = ItemGroups.Primary,
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

    ImpulseForce = 20,

    AttackInterval = 1,
    ReloadTime = 1.5,
    AmmoType = Ammo.Rifle,

    Model = models("Scout"),
    HoldAnimation = "rbxassetid://10247529531",
    AimAnimation = "rbxassetid://18691492037",
    AttackSound = firedSounds("Scout"),
    ReloadSound = reloadSounds("Scout"),

    BeforeHitParticipant = ItemKillHighlights(
        {
            Title = "Point and Click",
            Description = "%s shows all you need for %d kills is a rifle and a steady hand.",
            Priority = 1,
            Threshold = 2,
        },
        {
            Title = "I Can See Your Head From Here",
            Description = "%s knows their rifle. Now %d other people know the rifle too.",
            Priority = 3,
            Threshold = 4,
        }
    ),

    RecoilX = 0.5,
    RecoilY = 1.5,
}

guns.Pistol = {
    Kind = "Gun" :: "Gun",
    Name = "Pistol",
    DisplayName = "Five-Seven",

    ItemGroup = ItemGroups.Secondary,
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

    ImpulseForce = 5,

    Model = models("Pistol"),
    HoldAnimation = "rbxassetid://9253211833",
    AimAnimation = "rbxassetid://18691552315",
    AttackSound = firedSounds("Pistol"),
    ReloadSound = reloadSounds("Pistol"),

    BeforeHitParticipant = ItemKillHighlights(
        {
            Title = "Persistent Little Bugger",
            Description = "%s scored %d kills using the pistol. Then they went on to hug someone to death.",
            Priority = 1,
            Threshold = 2,
        },
        {
            Title = "Small Caliber Slaughter",
            Description = "%s killed a small army of %d with a pistol. Presumably installed a tiny shotgun inside the barrel.",
            Priority = 3,
            Threshold = 4,
        }
    ),

    Projectile = bullet,
    ProjectileSpeed = 250,

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

    ItemGroup = ItemGroups.RoleWeapon,
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

    ImpulseForce = 50, -- :troll:

    Model = models("Golden Gun"),
    HoldAnimation = "rbxassetid://9253211833",
    AimAnimation = "rbxassetid://18691552315",
    AttackSound = firedSounds("Golden Gun"),

    AttackInterval = 0.5,
    ReloadTime = 0,

    AimFOV = 70,
    AimSpreadMultiplier = 0,

    BeforeHitProp = function(item: Types.ItemBeforeHit, _, target: Types.Prop | Types.Interactable, params: Types.DamageParams): boolean
        assert(item.Kind == "Gun")
        if target.Kind ~= "Prop" then
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
            MakeGolden(target)
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
            MakeGolden(attacker)
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

    ItemGroup = ItemGroups.Primary,
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
    ProjectileSpeed = 280,

    ImpulseForce = 1,

    AimFOV = 60,
    AimSpreadMultiplier = 0.3,

    RecoilX = 0.5,
    RecoilY = 1,

    BeforeHitParticipant = ItemKillHighlights(
        {
            Title = "Pray and Slay",
            Description = "%s killed %d people with the M11, but won't say how much ammo they needed.",
            Priority = 1,
            Threshold = 2,
        },
        {
            Title = "Mac and Cheese",
            Description = "%s wonders what would happen if they could wield two M11s. %d times two?",
            Priority = 3,
            Threshold = 4,
        }
    ),
}

guns.AWP = {
    Kind = "Gun" :: "Gun",
    Name = "AWP",
    Description = "A high-powered sniper rifle. Must be scoped in to shoot.",
    Icon = "rbxassetid://4772214897",
    MaxStock = 1,

    IsEvilItem = true,

    ItemGroup = ItemGroups.RoleWeapon,
    CreditCost = 1,
    CanDrop = true,

    Damage = {
        Head = 300,
        Body = 100,
        Limb = 65,
    },

    ImpulseForce = 50,

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
    ProjectileSpeed = 600,

    RecoilX = 0.8,
    RecoilY = 2.5,

    BeforeHitParticipant = ItemKillHighlights(
		{
			Title = "Good Job",
			Description = "%s killed 1 person with an AWP.",
			Priority = 2,
			Threshold = 1,
		},
        {
			Title = "Good Job",
			Description = "%s killed %d people with an AWP.",
			Priority = 3,
			Threshold = 2,
		},
		{
			Title = "Challenging Work",
			Description = "%s killed %d people with an AWP. Possibly out of doors.",
			Priority = 4,
			Threshold = 3,
		}
	)
}

guns["Assault Rifle"] = {
    Kind = "Gun" :: "Gun",
    Name = "Assault Rifle",
    DisplayName = "M4A1",

    ItemGroup = ItemGroups.Primary,
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
    ProjectileSpeed = 250,

    ImpulseForce = 5,

    RecoilX = 0.6,
    RecoilY = 1.5,

    BeforeHitParticipant = ItemKillHighlights(
        {
            Title = "Putt Putt Putt",
            Description = "%s picked off %d people with the M4A1.",
            Priority = 1,
            Threshold = 2,
        },
        {
            Title = "Mid-range Madness",
            Description = "%s knows how to take down targets with the M4A1, scoring %d kills.",
            Priority = 3,
            Threshold = 4,
        }
    ),
}

guns["Silenced Pistol"] = {
    Kind = "Gun" :: "Gun",
    Name = "Silenced Pistol",
    Description = "A Five-Seven that has had a suppressor fitted to it, making it much quieter. People killed with silenced weapons will not scream.",
    Icon = "rbxassetid://299432421",
    CreditCost = 1,
    MaxStock = 3,

    IsEvilItem = true,

    ItemGroup = ItemGroups.RoleWeapon,
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
    ProjectileSpeed = 250,

    ImpulseForce = 5,

    IsSilent = true,
    BeforeHitParticipant = ItemKillHighlights(
        {
            Title = "Be Quiet",
            Description = "%s shut %d people up with the silenced pistol.",
            Priority = 2,
            Threshold = 2,
        },
        {
            Title = "Silenced Assassin",
            Description = "%s killed %d people who did not hear themselves die.",
            Priority = 4,
            Threshold = 4,
        }
    ),

    RecoilX = 0.2,
    RecoilY = 1.0,
}

guns.XM1014 = {
    Kind = "Gun" :: "Gun",
    Name = "XM1014",

    ItemGroup = ItemGroups.Primary,
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
    ProjectileSpeed = 220,

    ImpulseForce = 4,

    Model = models("XM1014"),
    HoldAnimation = "rbxassetid://11436160569",
    AimAnimation = "rbxassetid://18691725191",
    AttackSound = firedSounds("XM1014"),
    ReloadSound = reloadSounds("XM1014"),

    BeforeHitParticipant = ItemKillHighlights(
        {
            Title = "Easy Mode",
            Description = "%s applies the buckshot where it hurts, murdering %d targets.",
            Priority = 1,
            Threshold = 2,
        },
        {
            Title = "A Thousand Little Pellets",
            Description = "%s didn't really like their buckshot, so they gave it all away. %d recipients did not live to enjoy it.",
            Priority = 3,
            Threshold = 4,
        }
    ),

    RecoilX = 1.0,
    RecoilY = 2.0,
}

guns.Glock = {
    Kind = "Gun" :: "Gun",
    Name = "Glock",
    DisplayName = "G18",

    ItemGroup = ItemGroups.Secondary,
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
    ProjectileSpeed = 280,

    ImpulseForce = 3,

    RecoilX = 0.2,
    RecoilY = 0.8,
}

guns.Deagle = {
    Kind = "Gun" :: "Gun",
    Name = "Deagle",

    ItemGroup = ItemGroups.Secondary,
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
    ProjectileSpeed = 450,

    ImpulseForce = 15,

    Model = models("Deagle"),
    HoldAnimation = "rbxassetid://9253211833",
    AimAnimation = "rbxassetid://18691552315",
    AttackSound = firedSounds("Deagle"),
    ReloadSound = reloadSounds("Deagle"),

    RecoilX = 0.3,
    RecoilY = 1.2,

    BeforeHitParticipant = ItemKillHighlights(
        {
            Title = "It's Like A Tiny Rifle",
            Description = "%s is getting the hang of the Desert Eagle and killed %d people.",
            Priority = 1,
            Threshold = 2,
        },
        {
            Title = "Eagle Master",
            Description = "%s blew away %d people with the deagle.",
            Priority = 3,
            Threshold = 4,
        }
    ),
}

guns.UMP = {
    Kind = "Gun" :: "Gun",
    Name = "UMP",
    Description = "A weak weapon standalone, but loaded with discombobulation. Targets will be disorientated when hit. Uses SMG rounds.",
    Icon = "rbxassetid://8482220999",

    MaxStock = 2,
    CreditCost = 1,
    CanDrop = true,
    ItemGroup = ItemGroups.RoleWeapon,

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
    ProjectileSpeed = 250,

    ImpulseForce = 5,

    OnHitClient = Discombobulate,

    RecoilX = 0.75,
    RecoilY = 1.75,
}

guns.MelonLauncher = MelonLauncher.Item

guns.BAR = {
    Kind = "Gun" :: "Gun",
    Name = "BAR",
    Description = "A powerful mid-range rifle. Slow to reload.",
    Icon = "rbxassetid://10243797417",
    MaxStock = 3,

    IsEvilItem = true,

    ItemGroup = ItemGroups.Primary,
    CreditCost = 1,
    CanDrop = true,

    HasMuzzleFlash = true,
    ImpulseForce = 15,

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
    ProjectileSpeed = 280,

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

    IsEvilItem = true,

    ItemGroup = ItemGroups.RoleWeapon,
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

    ItemGroup = ItemGroups.RoleUtility,
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

grenades["Incendiary Grenade"] = IncendiaryGrenade.Item

grenades.FreezeGrenade = FreezeGrenade.Item

grenades["Smoke Grenade"] = {
    Kind = "Grenade" :: "Grenade",
    Name = "Smoke Grenade",

    ItemGroup = ItemGroups.Grenade,
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
        smoke.Size = 7.5
        smoke.Opacity = 0.75
        smoke.RiseVelocity = 2
        smoke.Color = Color3.fromRGB(127, 127, 127)

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

    ItemGroup = ItemGroups.Grenade,
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

items.Jetpack = Jetpack.Item

items["Ballistic Vest"] = BallisticVest.Item

items.Disguiser = Disguiser.Item

local function createInteractableForItem(item: Types.Item, round: Types.Round): Types.Interactable
    local interactableDefinition = round:GetInteractableDefinition(item.Definition.Name)
    assert(interactableDefinition, "Could not find interactable definition for " .. item.Definition.Name)
    return round:AddInteractable(interactableDefinition, nil, true)
end

local function throwInteractable(item: Types.Item, mode: "Primary" | "Alternate", origin: Vector3, direction: Vector3, participant: Types.Participant): Types.Interactable?
    local round = participant.Round

    local interactable = createInteractableForItem(item, round)
    interactable.Model:RemoveTag("Item")
    interactable.Extras.PlantedBy = participant
    interactable.Extras.Player = participant.Player
    local success = participant:TryThrowAssembly(interactable.Model, 10, round:GetMap().Structure.Dynamic, nil, direction)

    if not success then
        round._interactables[interactable.Model] = nil
        interactable.Model:Destroy()
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
    if not result or not result.Instance:IsDescendantOf(participant.Round:GetMap().Structure.Static) then
        return nil
    end

    local interactable = createInteractableForItem(item, participant.Round)
    interactable.Extras.PlantedBy = participant
    local object = interactable.Model
    object:RemoveTag("Item");
    (object :: Instance).Parent = participant.Round:GetMap().Structure.Dynamic

    GetPrimaryPart(object).CFrame = CFrame.lookAt(result.Position, result.Position + result.Normal)

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = result.Instance :: BasePart
    weld.Part1 = GetPrimaryPart(object)
    weld.Parent = object

    participant:RemoveItem(item)

    return interactable, result, weld
end

items.C4 = {
    Kind = "Item" :: "Item",
    Name = "C4",
    ItemGroup = ItemGroups.RoleWeapon,
    CanDrop = true,

    IsEvilItem = true,

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

        local object = interactable.Model
        assert(object:IsA("BasePart"))

        weld.Enabled = false
        object.CFrame *= CFrame.Angles(math.rad(-90), 0, 0)
		object.CFrame += result.Normal / 4
        weld.Enabled = true
    end
}

items.Visualiser = {
    Kind = "Item" :: "Item",
    Name = "Visualiser",
    ItemGroup = ItemGroups.RoleUtility,
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
    ItemGroup = ItemGroups.RoleUtility,
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
        DNAScanner.AddDNATrace(interactable, participant, nil, "rbxassetid://128627317841330", interactable.Model)
    end,
}

items.HealthStation = {
    Kind = "Item" :: "Item",
    Name = "HealthStation",
    DisplayName = "Health Station",
    ItemGroup = ItemGroups.RoleUtility,
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
    ItemGroup = ItemGroups.RoleUtility,
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

        DNAScanner.AddDNATrace(interactable, participant, nil, "rbxassetid://93284379186217", interactable.Model)
    end,
}

items.Decoy = {
    Kind = "Item" :: "Item",
    Name = "Decoy",
    ItemGroup = ItemGroups.RoleUtility,
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

        local object = interactable.Model
        assert(object:IsA("BasePart"))

        weld.Enabled = false
        object.CFrame *= CFrame.new(0, 0, -object.Size.Z / 2)
        weld.Enabled = true

        interactable.Model:SetAttribute("Player", participant.Player.Name)
        DNAScanner.AddDNATrace(interactable, participant, nil, "rbxassetid://96906503847712", interactable.Model)
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

allItems["Isaac Newton"] = modify(guns["Newton Launcher"], "Isaac Newton", {
    AttackInterval = 0,
})

allItems["Knice"] = require(script.Parent.Knice)

allItems["Meloncholy"] = modify(guns["MelonLauncher"], "Meloncholy", {
    DisplayName = "Meloncholy",
    AmmoType = Ammo.Infinite,
    AttackInterval = 0.5,
})

allItems["Flypack"] = require(script.Parent.Flypack).Item

return allItems