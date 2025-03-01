local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CreateEmptyPart = require(ReplicatedStorage.RoundRule.Common.CreateEmptyPart)
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

local function modify(base: Types.AnyItemDefinition, name: string, edit: {[string]: any}): Types.AnyItemDefinition
    local new = table.clone(base)
    for i, v in edit do
        new[i] = v
    end

    new.Name = name

    if base.Model then
        new.Model = base.Model:Clone()
        new.Model.Name = name
        new.Model.Parent = ReplicatedStorage.WeaponModels
    end

    return new
end

local bullet = projectiles("Bullet")

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

local function burn(attacker: Types.Participant, target: Types.Participant | Types.Prop): ()
    local part: BasePart
    if target.Kind == "Participant" then
        local character = target:GetCharacter()
        if not character then
            return
        end

        local root = character.PrimaryPart
        if not root then
            return
        end

        part = root
    elseif target.Kind == "MapProp" or target.Kind == "AmmoProp" or target.Kind == "ItemProp" then
        part = target.Model
    elseif target.Kind == "CorpseProp" then
        local root = target.Model.PrimaryPart
        if not root then
            return
        end

        part = root
    end

    local fire = Instance.new("Fire")
    fire.Size = 10
    fire.Parent = part

    local burnSound = Instance.new("Sound")
    burnSound.SoundId = weaponSounds("FlareBurn")
    burnSound.Parent = part

    if target.Kind == "MapProp" then
        part:SetAttribute("Burning", true)
    elseif target.Kind == "CorpseProp" then
        target.Model:SetAttribute("Burning", true)
    end

    local endTime = workspace:GetServerTimeNow() + 10
    task.spawn(function()
        while true do
            if workspace:GetServerTimeNow() > endTime then
                break
            end

            task.wait(0.25)

            if target.Kind ~= "Participant" and target.Kind ~= "MapProp" then
                continue
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
        end
        
        if target.Kind == "MapProp" then
            part:SetAttribute("Burning", false)
        end

        burnSound:Destroy()
        fire:Destroy()

        if target.Kind == "CorpseProp" then
            target.Model:Destroy()
        end
    end)
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
    ReloadSound = "",

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

    BeforeHitProp = function(item: Types.AnyWeapon, target: Types.Prop, params: Types.DamageParams): boolean
        if target.Kind ~= "MapProp" then
            return false
        end
        
        local attacker = params.Attacker
        target:TryTakeDamage({
            Amount = math.huge,
            Attacker = attacker,
            Source = item,
        })
        return false
    end,

    BeforeHitParticipant = function(item: Types.AnyWeapon, target: Types.Participant, params: Types.DamageParams): boolean
        local attacker = params.Attacker
        assert(attacker)

        if attacker:IsDamageJustifiedAgainstParticipant(target) then
            makeGolden(target)
            target:TryTakeDamage({
                Amount = math.huge,
                Attacker = attacker,
                Source = item,
                IsHeadshot = false,
            })
        else
            makeGolden(attacker)
            attacker:TryTakeDamage({
                Amount = math.huge,
                Attacker = attacker,
                Source = item,
                IsHeadshot = false,
            })
        end

        return false
    end,

    RecoilX = 0.0,
    RecoilY = 0.0,
}

guns["Flare Gun"] = {
    Kind = "Gun" :: "Gun",
    Name = "Flare Gun",
    Description = "Will set things it hits on fire. Can be used to burn corpses, preventing others from discovering them.",
    Icon = "rbxassetid://444145395",
    CreditCost = 1,
    MaxStock = 1,

    Slot = 8,
    CanDrop = true,

    Damage = {
        Head = 15,
        Body = 10,
        Limb = 5,
    },

    AmmoType = Ammo.Flare,
    ReloadSound = "",

    HasMuzzleFlash = true,

    Spread = 0.015,
    
    AttackInterval = 0.25,
    ReloadTime = 0,
    MagazineSize = 6,

    Model = models("Flare Gun"),
    HoldAnimation = "rbxassetid://9253211833",
    AimAnimation = "rbxassetid://18691552315",
    AttackSound = firedSounds("Flare Gun"),

    Projectile = projectiles("Flare"),
    ProjectileSpeed = 140,

    AimFOV = 60,
    AimSpreadMultiplier = 0.3,

    BeforeHitParticipant = function(_, target: Types.Participant, params: Types.DamageParams): boolean
        local attacker = params.Attacker
        assert(attacker)
        burn(attacker, target)
        return true
    end,

    BeforeHitProp = function(_, target: Types.Prop, params: Types.DamageParams): boolean
        local attacker = params.Attacker
        assert(attacker)

        burn(attacker, target)
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
    
    Slot = 7,
    CreditCost = 1,
    CanDrop = true,

    Damage = {
        Head = 300,
        Body = 100,
        Limb = 65,
    },

    AmmoType = Ammo.AWP,
    ReloadSound = "",

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
    Description = "A Pistol that has had a suppressor fitted to it, making it much quieter. People killed with silenced weapons will not scream.",
    Icon = "rbxassetid://299432421",
    CreditCost = 1,
    MaxStock = 3,

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

    BeforeHitParticipant = function(_, victim: Types.Participant, params: Types.DamageParams): boolean
        local willDie = params.Amount >= victim:GetHealth()
        if not willDie then
            return true
        end

        local root = assert(victim:GetCharacter(), "Participant has no character").PrimaryPart
        if not root then
            return true
        end

        local deathSound = root:FindFirstChild("DeathSound") :: Sound?
        if deathSound then
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

guns.BAR = {
    Kind = "Gun" :: "Gun",
    Name = "BAR",
    Description = "A powerful mid-range rifle. Slow to reload.",
    Icon = "rbxassetid://10243797417",
    MaxStock = 3,

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

local grenades: {[string]: Types.GrenadeWeaponDefinition} = {}
grenades.Grenade = {
    Kind = "Grenade" :: "Grenade",
    Name = "Grenade",
    Description = "Explodes in a good radius after 5 seconds.",
    Icon = "rbxassetid://8096856961",
    CreditCost = 2,
    MaxStock = 2,

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

        BeforeHitParticipant = function(_, target: Types.Participant): boolean
            ReplicatedStorage.ServerClient.Flashbang:FireClient(target.Player)
            return true
        end,
    },

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

                    local sound = ReplicatedStorage.WeaponSounds.FlareBurn:Clone()
                    sound.PlayOnRemove = true
                    sound.Parent = v
                    sound:Destroy()
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

        BeforeHitParticipant = function(_, target: Types.Participant): boolean
            ReplicatedStorage.ServerClient.Discombobulate:FireClient(target.Player)
            return true
        end,
    },

    FuseTime = 3,

    ProjectileForce = 60,

    AttackSound = firedSounds("Grenade"),
}

local melees: {[string]: Types.MeleeWeaponDefinition} = {}
melees.Crowbar = {
    Kind = "Melee" :: "Melee",
    Name = "Crowbar",
    
    Slot = 1,
    CanDrop = false,

    DamageKind = "Bludgeon" :: "Bludgeon",

    Model = models("Crowbar"),
    HoldAnimation = "rbxassetid://10247423634",
    AttackAnimation = "rbxassetid://13269497293",

    MaxDistance = 7,
    Damage = 20,
    AttackInterval = 0.3,
    AttackSound = firedSounds("Crowbar"),
}

local items: {[string]: Types.ItemDefinition} = {}
items["Magneto Stick"] = {
    Kind = "Item" :: "Item",
    Name = "Magneto Stick",
    Slot = 5,
    CanDrop = false,

    Model = models("Magneto Stick"),
    HoldAnimation = "rbxassetid://10247423634",

    PrimaryHint = "Push Prop",
    AlternateHint = "Grab Prop",
}

items["DNA Scanner"] = {
    Kind = "Item" :: "Item",
    Name = "DNA Scanner",
    Slot = 9,
    CanDrop = true,

    Model = models("DNA Scanner"),
    HoldAnimation = "rbxassetid://10247423634",

    PrimaryHint = "Scan Identified Body",
}

local radarPoint = ReplicatedStorage:WaitForChild("RadarPoint")
items.Radar = {
    Kind = "Item" :: "Item",
    Description = "Reveals the location of all living players every 30 seconds.",
    CreditCost = 1,
    MaxStock = 1,
    Icon = "rbxassetid://62159372",
    Name = "Radar",

    HeartbeatClient = function(item: Types.Item)
        local lastScan: number = item.Extras.LastScan or 0

        local timeNow = workspace:GetServerTimeNow()
        if timeNow - lastScan < 30 then
            return
        end

        item.Extras.LastScan = timeNow

        workspace.RadarPoints:ClearAllChildren()

        for _, v in Players:GetPlayers() do
            local char = v.Character
            if not char or v == Players.LocalPlayer then
                continue
            end

            local root = char.PrimaryPart
            local hum = char:FindFirstChildOfClass("Humanoid")

            if not root or not hum or hum.Health <= 0 then
                continue
            end

            local clone = radarPoint:Clone()
            clone:PivotTo(root.CFrame)
            clone.RadarPoint.TextLabel.Text = tostring(math.round(v:DistanceFromCharacter(root.Position)))
            clone.RadarPoint.Enabled = true
            clone.Parent = workspace.RadarPoints
        end
    end
}

items["Ballistic Vest"] = {
    Kind = "Item" :: "Item",
    Name = "Ballistic Vest",
    Description = "Absorbs a limited amount of damage to the torso. Not visible to others.",
    Icon = "rbxassetid://395920626",

    CreditCost = 1,

    OnPurchase = function(item: Types.Item, participant: Types.Participant)
        participant.Extras.BallisticVest = 60
    end,
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