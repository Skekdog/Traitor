local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local WeaponsManager = require(script.Parent)

local projectiles = ServerStorage.Projectiles
local models = ReplicatedStorage.WeaponModels
local firedSounds = ReplicatedStorage.WeaponSounds.Fired
local reloadSounds = ReplicatedStorage.WeaponSounds.Reload

local bullet = projectiles.Bullet :: PVInstance

local weapons: {[string]: WeaponsManager.Weapon} = {
    Grenade = {
        Name = "Grenade",
        Description = "Kaboom",

        ProjectileInfo = {
            Base = projectiles.Grenade :: PVInstance,
            Speed = 500
        },
        Slot = 7,
        CanDrop = true,

        Damage = 150,

        FalloffStart = 5,
        FalloffEnd = 17,
        FalloffMultiplier = 0.1,

        ExplosionInfo = {
            Radius = 17,
            Pressure = 1000,
        },
        FuseTime = 5,

        MultiUse = false,
        AimInfo = false,

        Recoil = 10,
        Spread = 0.25,

        Model = models.Grenade,
        FiredSound = firedSounds.Grenade,
    },
    Crowbar = {
        Name = "Crowbar",
        Description = "Make Freeman Proud",

        Slot = 1,
        CanDrop = false,

        Damage = 20,
        FalloffStart = 7,
        FalloffEnd = 7,
        FalloffMultiplier = 0,

        AimInfo = false,
        Recoil = 5,
        Spread = 0,

        MultiUse = {
            FireTime = 0.35,
            ReloadTime = 0,
            MaxReserve = 0,
            MagazineSize = math.huge,
        },
        Model = models.Crowbar,
        FiredSound = firedSounds.Crowbar,

        ProjectileInfo = false
    },
    HUGE = {
        Name = "HUGE",
        Description = "Boolet",

        Slot = 3,
        CanDrop = true,

        Recoil = 0.6,
        Spread = 1.5,

        Damage = {
            Head = 25,
            Limb = 5,
            Body = 10
        },

        FalloffStart = 35,
        FalloffEnd = 80,
        FalloffMultiplier = 0.5,

        AimInfo = {
            FOV = 60,
            SpreadMultiplier = 0.3
        },

        MultiUse = {
            FireTime = 0.01,
            ReloadTime = 0,
            MaxReserve = 0,
            MagazineSize = 250,
        },

        ProjectileInfo = {
            Base = bullet,
            Speed = 140
        },

        Model = models.HUGE,
        FiredSound = firedSounds.HUGE,
    },
    Scout = {
        Name = "Scout",
        Description = "It's a good job",

        Slot = 3,
        CanDrop = true,

        Recoil = 1.5,
        Spread = 0.25,

        FalloffStart = 178,
        FalloffEnd = 300,
        FalloffMultiplier = 0.5,

        Damage = {
            Body = 50,
            Limb = 25,
            Head = 130,
        },

        AimInfo = {
            SpreadMultiplier = 0.05,
            HasScope = true,
            FOV = 30,
        },
        
        ProjectileInfo = {
            Base = bullet,
            Speed = 250
        },

        MultiUse = {
            FireTime = 1,
            ReloadTime = 1.5,
            MaxReserve = 10,
            MagazineSize = 5,
            AmmoType = "Scout"
        },

        Model = models.Scout,
        FiredSound = firedSounds.Scout,
        ReloadSound = reloadSounds.Scout,
    },
    Pistol = {
        Name = "Pistol",
        Description = "Pew",

        Slot = 3,
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

        AimInfo = {
            FOV = 70,
            SpreadMultiplier = 0.1,
        },

        MultiUse = {
            FireTime = 0.6,
            ReloadTime = 1,
            MaxReserve = 60,
            MagazineSize = 20,
            AmmoType = "Assault Rifle"
        },

        Model = models.Pistol,
        FiredSound = firedSounds.Pistol,
        ReloadSound = reloadSounds.Pistol,

        ProjectileInfo = {
            Base = bullet,
            Speed = 100
        }
    },
    ["Golden Gun"] = {
        Name = "Golden Gun",
        Description = "One shot. Don't fumble it.",

        Slot = 7,
        CanDrop = true,

        Damage = 0,

        FalloffStart = 0,
        FalloffEnd = 0,
        FalloffMultiplier = 1,

        AimInfo = {
            FOV = 50,
            SpreadMultiplier = 1,
        },

        Spread = 0,
        Recoil = 5,

        MultiUse = false,
        ProjectileInfo = {
            Base = projectiles.GoldenBullet :: PVInstance,
            Speed = 250
        },

        Model = models["Golden Gun"],
        FiredSound = firedSounds["Golden Gun"],

        BeforeHitParticipant = function(attacker, target, dead, hitPartName)
            if not attacker then
                return
            end

            if not attacker:IsDamageJustifiedAgainst(target) then
                return attacker:Kill(attacker, attacker.Round:GetEquipment("Golden Gun"), hitPartName == "Head", true)
            end

            local char = target.Character
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

                local sound = ReplicatedStorage.WeaponSounds.GoldenGunHit:Clone()
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

            target:Kill(attacker, attacker.Round:GetEquipment("Golden Gun"), hitPartName == "Head")
            return true
        end
    },
    SMG = {
        Name = "SMG",
        Description = "pew pew pew",

        Slot = 3,
        CanDrop = true,

        Damage = {
            Head = 25,
            Body = 20,
            Limb = 15
        },

        FalloffStart = 35,
        FalloffEnd = 80,
        FalloffMultiplier = 0.5,

        Spread = 1,
        Recoil = 0.3,

        MultiUse = {
            FireTime = 0.05,
            ReloadTime = 1,
            MagazineSize = 30,
            MaxReserve = 60,
            AmmoType = "SMG"
        },

        Model = models.SMG,
        FiredSound = firedSounds.SMG,
        ReloadSound = reloadSounds.SMG,

        ProjectileInfo = {
            Base = bullet,
            Speed = 140
        },

        AimInfo = {
            FOV = 60,
            SpreadMultiplier = 0.3
        }
    },
    AWP = {
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

        AimInfo = {
            HasScope = true,
            ScopeRequired = true,
            FOV = 10,
            SpreadMultiplier = 0.05
        },

        Spread = 0.25,
        Recoil = 2,

        MultiUse = {
            FireTime = 2,
            ReloadTime = 0,
            MaxReserve = 0,
            MagazineSize = 4,
        },

        Model = models.AWP,
        FiredSound = firedSounds.AWP,

        ProjectileInfo = {
            Base = bullet,
            Speed = 300
        }
    },
    ["Assault Rifle"] = {
        Name = "Assault Rifle",
        Description = "pew pew",

        Slot = 3,
        CanDrop = true,

        Spread = 0.5,
        Recoil = 0.3,

        Damage = {
            Head = 60,
            Body = 30,
            Limb = 20,
        },

        MultiUse = {
            FireTime = 0.15,
            ReloadTime = 1.5,
            MaxReserve = 60,
            MagazineSize = 20,
            AmmoType = "Assault Rifle"
        },

        AimInfo = {
            FOV = 50,
            SpreadMultiplier = 0.25
        },

        Model = models["Assault Rifle"],
        FiredSound = firedSounds["Assault Rifle"],
        ReloadSound = reloadSounds["Assault Rifle"],

        FalloffStart = 75,
        FalloffEnd = 125,
        FalloffMultiplier = 0.5,

        ProjectileInfo = {
            Base = bullet,
            Speed = 150,
        }
    },
    Flashbang = {
        Name = "Flashbang",
        Description = "Blinds and deafens anyone in its radius. Can be disarmed by shooting it.",

        Slot = 7,
        CanDrop = true,

        Damage = 0,

        FalloffStart = 0,
        FalloffEnd = 0,
        FalloffMultiplier = 1,

        ExplosionInfo = {
            Radius = 17,
            Pressure = 0,
        },
        FuseTime = 3,

        AimInfo = false,
        Recoil = -1,
        Spread = 0,

        MultiUse = false,
        ProjectileInfo = {
            Base = projectiles.Flashbang :: PVInstance,
            Speed = 80,
        },

        Model = models.Flashbang,
        FiredSound = firedSounds.Flashbang,

        BeforeHitParticipant = function(_, victim)
            ReplicatedStorage.ServerClient.Flashbang:FireClient(victim.Player)
        end
    },
    ["Silenced Pistol"] ={
        Name = "Silenced Pistol",
        Description = "A Pistol that has been modified to make far less noise. People killed with silenced weapons will not scream.",

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

        AimInfo = {
            FOV = 70,
            SpreadMultiplier = 0.1,
        },

        MultiUse = {
            FireTime = 0.6,
            ReloadTime = 1,
            MaxReserve = 60,
            MagazineSize = 20,
            AmmoType = "Assault Rifle"
        },

        Model = models["Silenced Pistol"],
        FiredSound = firedSounds["Silenced Pistol"],
        ReloadSound = reloadSounds["Silenced Pistol"],

        ProjectileInfo = {
            Base = projectiles.SilencedBullet :: PVInstance,
            Speed = 100
        },

        BeforeHitParticipant = function(_, victim)
            local root = victim.Character:FindFirstChild("HumanoidRootPart")
            if not root then
                return
            end

            local deathSound = root:FindFirstChild("DeathSound") :: Sound
            if deathSound then
                deathSound.Volume = 0
            end
        end
    },
    XM1014 = {
        Name = "XM1014",
        Description = "bang",

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

        AimInfo = {
            FOV = 50,
            SpreadMultiplier = 0.7
        },

        Spread = 1.5,
        Recoil = 1.2,

        MultiUse = {
            FireTime = 0.8,
            ReloadTime = 1.5,
            MaxReserve = 16,
            AmmoType = "Shotgun",
            MagazineSize = 8
        },
        BulletsPerShot = 6,

        ProjectileInfo = {
            Base = bullet,
            Speed = 150
        },

        Model = models.XM1014,
        FiredSound = firedSounds.XM1014,
        ReloadSound = reloadSounds.XM1014,
    },
    Glock = {
        Name = "Glock",
        Description = "pew pew",

        Slot = 2,
        CanDrop = true,

        Damage = {
            Head = 20,
            Limb = 10,
            Body = 15,
        },

        FalloffStart = 45,
        FalloffEnd = 100,
        FalloffMultiplier = 0.2,

        AimInfo = {
            SpreadMultiplier = 0.1,
            FOV = 70
        },

        Recoil = 0.5,
        Spread = 0.35,

        MultiUse = {
            FireTime = 0.1,
            ReloadTime = 1,
            MaxReserve = 60,
            MagazineSize = 20,
            AmmoType = "Assault Rifle"
        },

        ProjectileInfo = {
            Base = bullet,
            Speed = 190
        },

        Model = models.Glock,
        FiredSound = firedSounds.Glock,
        ReloadSound = reloadSounds.Glock,
    },
    Deagle = {
        Name = "Deagle",
        Description = "Bang",

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

        AimInfo = {
            FOV = 50,
            SpreadMultiplier = 0.1
        },

        Recoil = 0.5,
        Spread = 0.25,

        MultiUse = {
            FireTime = 0.5,
            ReloadTime = 1.2,
            MaxReserve = 32,
            MagazineSize = 8,
            AmmoType = "Deagle"
        },

        ProjectileInfo = {
            Base = bullet,
            Speed = 190
        },

        Model = models.Deagle,
        FiredSound = firedSounds.Deagle,
        ReloadSound = reloadSounds.Deagle,
    }
}

return weapons