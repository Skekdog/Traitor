local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ItemTypes = require(script.Parent.ItemTypes)
local CreateEmptyPart = require(script.Parent.CreateEmptyPart)
local Types = require(script.Parent.RoundHandler.Types)

local function projectiles(name: string): BasePart
    return ReplicatedStorage:WaitForChild("Projectiles"):WaitForChild(name) :: BasePart
end

local bullet = projectiles("Bullet")

local function models(name: string): MeshPart
    return ReplicatedStorage:WaitForChild("WeaponModels"):WaitForChild(name) :: MeshPart
end

local function weaponSounds(name: string): Sound
    return ReplicatedStorage:WaitForChild("WeaponSounds"):WaitForChild(name) :: Sound
end

local function firedSounds(name: string): Sound
    return ReplicatedStorage:WaitForChild("WeaponSounds"):WaitForChild("Fired"):WaitForChild(name) :: Sound
end

local function reloadSounds(name: string): Sound
    return ReplicatedStorage:WaitForChild("WeaponSounds"):WaitForChild("Reload"):WaitForChild(name) :: Sound
end

local serverClient = ReplicatedStorage:WaitForChild("ServerClient")

local guns: {[string]: ItemTypes.GunDefinition} = {}
guns.HUGE = {
    Kind = "Gun",
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
    HoldAnimation = 12498608892,

    FiredSound = firedSounds("HUGE"),

    RecoilX = 0.8,
    RecoilY = 1.2,
}

guns.Scout = {
    Kind = "Gun",
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
    AmmoType = "Scout",

    Model = models("Scout"),
    HoldAnimation = 10247529531,
    FiredSound = firedSounds("Scout"),
    ReloadSound = reloadSounds("Scout"),

    RecoilX = 0.5,
    RecoilY = 1.5,
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

    FalloffStart = 55,
    FalloffEnd = 110,
    FalloffMultiplier = 0.4,

    AimFOV = 70,
    AimSpreadMultiplier = 0.1,

    FireTime = 0.5,
    ReloadTime = 1,
    AmmoType = "Assault Rifle",

    Model = models("Pistol"),
    HoldAnimation = 9253211833,
    FiredSound = firedSounds("Pistol"),
    ReloadSound = reloadSounds("Pistol"),

    ProjectileBase = bullet,
    ProjectileSpeed = 100,

    RecoilX = 0.2,
    RecoilY = 1.0,
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

    LaserColour = Color3.fromRGB(47, 47, 255),
    
    MagazineSize = 1,

    ProjectileBase = projectiles("GoldenBullet"),
    ProjectileSpeed = 250,

    Model = models("Golden Gun"),
    HoldAnimation = 9253211833,
    FiredSound = firedSounds("Golden Gun"),

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

        if attacker:IsDamageJustifiedAgainst(target) then
            makeGolden(target)
            target:TakeDamage(math.huge, attacker, attacker.Round:GetEquipment("Golden Gun"), hitPartName == "Head")
        else
            makeGolden(attacker)
            attacker:TakeDamage(math.huge, attacker, attacker.Round:GetEquipment("Golden Gun"), hitPartName == "Head", true)
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

    local burnSound = weaponSounds("FlareBurn"):Clone()
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
    
    FireTime = 0.25,
    ReloadTime = 0,
    MagazineSize = 6,

    Model = models("Flare Gun"),
    HoldAnimation = 11411819299,
    FiredSound = firedSounds("Flare Gun"),

    ProjectileBase = projectiles("Flare"),
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

    RecoilX = 0.8,
    RecoilY = 1.2,
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
    
    FireTime = 0.05,
    ReloadTime = 1,
    AmmoType = "SMG",

    Model = models("SMG"),
    HoldAnimation = 12481091962,
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

    FireTime = 2,
    ReloadTime = 0,
    MagazineSize = 4,

    Model = models("AWP"),
    HoldAnimation = 10247529531,
    FiredSound = firedSounds("AWP"),

    ProjectileBase = bullet,
    ProjectileSpeed = 300,

    RecoilX = 0.8,
    RecoilY = 2.5,
}

guns["Assault Rifle"] = {
    Kind = "Gun",
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
    AmmoType = "Assault Rifle",

    AimFOV = 50,
    AimSpreadMultiplier = 0.25,

    Model = models("Assault Rifle"),
    HoldAnimation = 10247380824,
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

    FalloffStart = 55,
    FalloffEnd = 110,
    FalloffMultiplier = 0.4,
    
    AimFOV = 70,
    AimSpreadMultiplier = 0.1,

    FireTime = 0.5,
    ReloadTime = 1,
    AmmoType = "Assault Rifle",

    Model = models("Silenced Pistol"),
    HoldAnimation = 9253211833,
    FiredSound = firedSounds("Silenced Pistol"),
    ReloadSound = reloadSounds("Silenced Pistol"),

    ProjectileBase = projectiles("SilencedBullet"),
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

    RecoilX = 0.2,
    RecoilY = 1.0,
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

    FireTime = 0.8,
    ReloadTime = 1.5,
    AmmoType = "Shotgun",

    BulletsPerShot = 6,

    ProjectileBase = bullet,
    ProjectileSpeed = 150,

    Model = models("XM1014"),
    HoldAnimation = 11436160569,
    FiredSound = firedSounds("XM1014"),
    ReloadSound = reloadSounds("XM1014"),

    RecoilX = 1.0,
    RecoilY = 2.0,
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

    Spread = 0.35,

    FireTime = 0.1,
    ReloadTime = 1,
    AmmoType = "Assault Rifle",

    Model = models("Glock"),
    HoldAnimation = 9253211833,
    FiredSound = firedSounds("Glock"),
    ReloadSound = reloadSounds("Glock"),

    ProjectileBase = bullet,
    ProjectileSpeed = 190,

    RecoilX = 0.2,
    RecoilY = 0.8,
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

    Spread = 0.25,

    FireTime = 0.5,
    ReloadTime = 1.2,
    AmmoType = "Deagle",

    ProjectileBase = bullet,
    ProjectileSpeed = 190,

    Model = models("Deagle"),
    HoldAnimation = 9253211833,
    FiredSound = firedSounds("Deagle"),
    ReloadSound = reloadSounds("Deagle"),

    RecoilX = 0.3,
    RecoilY = 1.2,
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

    FalloffStart = 50,
    FalloffEnd = 120,
    FalloffMultiplier = 0.3,

    FireTime = 0.1,
    ReloadTime = 2.5,
    AmmoType = "Assault Rifle",

    Model = models("BAR"),
    HoldAnimation = 11418976539,
    FiredSound = firedSounds("BAR"),
    ReloadSound = reloadSounds("BAR"),

    ProjectileBase = bullet,
    ProjectileSpeed = 120,

    AimFOV = 65,
    AimSpreadMultiplier = 0.2,

    RecoilX = 0.6,
    RecoilY = 1.8,
}

local grenades: {[string]: ItemTypes.GrenadeDefinition} = {}
grenades.Grenade = {
    Kind = "Grenade",
    Name = "Grenade",
    Description = "Explodes in a good radius after 5 seconds.",

    Slot = 7,
    CanDrop = true,

    Model = models("Grenade"),
    HoldAnimation = 12498620263,
    
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

    ProjectileForce = 0.75,
    Spread = 0.25,

    FiredSound = firedSounds("Grenade"),
}

grenades.Flashbang = {
    Kind = "Grenade",
    Name = "Flashbang",
    Description = "Explodes in a good radius after 3 seconds, blinding and deafening anyone in range.",

    Slot = 7,
    CanDrop = true,

    Model = models("Flashbang"),
    HoldAnimation = 12498620263,

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

    ProjectileForce = 60,
    Spread = 0.25,

    FiredSound = firedSounds("Grenade"),
}

grenades["Incendiary Grenade"] = {
    Kind = "Grenade",
    Name = "Incendiary Grenade",

    Slot = 4,
    CanDrop = true,

    Model = models("Incendiary Grenade"),
    HoldAnimation = 12498620263,

    ExplosionInfo = {
        Kind = "Explosion",
        Radius = 15,
        Pressure = 10000,
        Damage = 10,

        OnExplode = function(self, position, attacker)
            if not attacker then
                return
            end

            local firePart = CreateEmptyPart(CFrame.new(position), nil, false, true, true)
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
                        if not participant or not participant.Character then
                            continue
                        end

                        participant:TakeDamage(4, nil, "Burn")
                    end
                    task.wait(0.05)
                end
            end)

            local fire = Instance.new("Fire")
            fire.Size = 40
            fire.Parent = firePart

            task.delay(30, firePart.Destroy, firePart)
        end
    },

    Fuse = 3,

    ProjectileForce = 2.5,
    Spread = 0.25,

    FiredSound = firedSounds("Grenade"),
}

grenades["Smoke Grenade"] = {
    Kind = "Grenade",
    Name = "Smoke Grenade",

    Slot = 4,
    CanDrop = true,

    Model = models("Smoke Grenade"),
    HoldAnimation = 12498620263,

    ExplosionInfo = {
        Kind = "Explosion",
        Radius = 15,
        Pressure = 10000,
        Damage = 0,

        OnExplode = function(self, position)
            local smoke = Instance.new("Smoke")
            smoke.Size = 20
            smoke.Opacity = 1
            smoke.RiseVelocity = 5
            
            local smokePart = CreateEmptyPart(CFrame.new(position))
            smoke.Parent = smokePart
            smokePart.Parent = workspace.Projectiles

            task.delay(30, smokePart.Destroy, smokePart)
        end,
    },

    Fuse = 3,

    ProjectileBase = models("Smoke Grenade"),
    ProjectileForce = 2.5,
    Spread = 0.25,

    FiredSound = firedSounds("Grenade"),
}

grenades["Discombobulator"] = {
    Kind = "Grenade",
    Name = "Discombobulator",

    Slot = 4,
    CanDrop = true,

    Model = models("Discombobulator"),
    HoldAnimation = 12498620263,

    ExplosionInfo = {
        Kind = "Explosion",
        Radius = 15,
        Pressure = 10000,
        Damage = 0,

        BeforeHitParticipant = function(attacker, target, dead, hitPartName)
            return ReplicatedStorage.ServerClient.Discombobulate:FireClient(target.Player)
        end,
    },

    Fuse = 3,

    ProjectileForce = 2.5,
    Spread = 0.25,

    FiredSound = firedSounds("Grenade"),
}

local melees: {[string]: ItemTypes.MeleeDefinition} = {}
melees.Crowbar = {
    Kind = "Melee",
    Name = "Crowbar",
    
    Slot = 1,
    CanDrop = false,

    Model = models("Crowbar"),
    HoldAnimation = 10247423634,
    HitAnimation = 13269497293,

    MaxDistance = 7,
    Damage = 20,
    FireTime = 0.3,
    FiredSound = firedSounds("Crowbar"),
}

local items: {[string]: ItemTypes.ItemDefinition} = {}
items["Magneto Stick"] = {
    Kind = "Item",
    Name = "Magneto Stick",
    Description = "Haha props",
    Slot = 5,
    CanDrop = false,

    Model = models("Magneto Stick"),
    HoldAnimation = 10247423634,

    ToggledAlt = true,
    AlternateFire = function(participant: Types.Participant, cameraRayInfo: Ray)
        require(ServerScriptService.MagnetoStick).AlternateFire(participant, cameraRayInfo)
    end,

    PrimaryFire = function(participant: Types.Participant, cameraRayInfo: Ray)
        require(ServerScriptService.MagnetoStick).PrimaryFire(participant, cameraRayInfo)
    end,
    
    OnUnequip = function(plr: Player)
        require(ServerScriptService.MagnetoStick).OnUnequip(plr)
    end
}

items["DNA Scanner"] = {
    Kind = "Item",
    Name = "DNA Scanner",
    
    Slot = 9,
    CanDrop = true,

    Model = models("DNA Scanner"),

    Toggled = true,

    PrimaryFire = function(participant, cameraRay)
        local head = participant.Character:FindFirstChild("Head")
        if not head or not head:IsA("BasePart") then
            return
        end

        local params = RaycastParams.new()
        params.CollisionGroup = "CorpseRaycasts"
        params.RespectCanCollide = false
        params.FilterDescendantsInstances = {workspace.Corpses}
        params.FilterType = Enum.RaycastFilterType.Include

        local result = workspace:Raycast(head.Position, cameraRay.Direction * 10)
        if not result then
            return
        end

        local model = result.Instance:FindFirstAncestorOfClass("Model")
        if not model or not model:IsDescendantOf(workspace.Corpses) or model:GetAttribute("Unidentified") then
            return
        end

        local victim = participant.Round:GetParticipant(model.Name)
        if not victim then
            return
        end

        local attacker = victim.KilledByParticipant
        if not attacker or not victim.DNAExpiry or victim.DNAExpiry < workspace:GetServerTimeNow() then
            return
        end

        serverClient.AcquireDNASample:FireClient(participant.Player, model, attacker.Player.Name)
    end,

    OnEquipClient = function()
        local UIManager = require(script.Parent.UIManager)
        local scannerUi = UIManager.WaitForUI("DNAScanner")
        scannerUi:ToggleVisible(true)
    end,

    OnUnequipClient = function()
        local UIManager = require(script.Parent.UIManager)
        local scannerUi = UIManager.WaitForUI("DNAScanner")
        scannerUi:ToggleVisible(false)
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