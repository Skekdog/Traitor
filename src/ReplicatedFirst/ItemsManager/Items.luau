local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ItemTypes = require(script.Parent.ItemTypes)
local Types = require(script.Parent.Parent.RoundHandler.Types)

local projectiles = ReplicatedStorage.Projectiles
local models = ReplicatedStorage.WeaponModels
local weaponSounds = ReplicatedStorage.WeaponSounds
local firedSounds = weaponSounds.Fired
local reloadSounds = weaponSounds.Reload

local bullet = projectiles.Bullet :: PVInstance

local function burn(attacker: Types.Participant?, part: BasePart, callback: (fire: Fire, burnSound: Sound) -> ()): ()
    if not attacker then
        return
    end

    local fire = Instance.new("Fire")
    fire.Size = 10
    fire.Parent = part

    local burnSound = weaponSounds.FlareBurn:Clone()
    burnSound.Parent = part :: any

    task.spawn(callback, fire, burnSound)
end

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
    print("stopped controlling prop")
end

return ({
    Grenade = {
        Kind = "Weapon",
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
            Kind = "Explosion",
            Radius = 17,
            Pressure = 1000,
            Damage = 0,
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
        Kind = "Weapon",
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
        Kind = "Weapon",
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
        Kind = "Weapon",
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
        Kind = "Weapon",
        Name = "Pistol",
        Description = "Pew",

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
        Kind = "Weapon",
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
        end
    },
    ["Flare Gun"] = {
        Kind = "Weapon",
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

        MultiUse = {
            FireTime = 0.25,
            ReloadTime = 1,
            MaxReserve = 0,
            MagazineSize = 6,
        },

        Model = models["Flare Gun"],
        FiredSound = firedSounds["Flare Gun"],

        ProjectileInfo = {
            Base = projectiles.Flare :: PVInstance,
            Speed = 140
        },

        AimInfo = {
            FOV = 60,
            SpreadMultiplier = 0.3
        },

        BeforeHitParticipant = function(attacker: Types.Participant?, target: Types.Participant, dead: boolean?, hitPartName: string)
            local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
            if not humanoid then
                return
            end

            local endTime = workspace:GetServerTimeNow() + 10
            burn(attacker, target.Character.PrimaryPart :: BasePart,function(fire, burnSound)
                while (endTime > workspace:GetServerTimeNow()) and (humanoid.Health > 0) and humanoid.Parent do
                    burnSound:Play()
                    target:TakeDamage(1, attacker, "Burn", false, true)
                    task.wait(0.25)
                end
                burnSound:Destroy()
                fire:Destroy()
            end)
            return
        end,

        BeforeHitCorpse = function(attacker, part)
            local endTime = workspace:GetServerTimeNow() + 10
            if not part.Parent then
                return
            end
            local root = part.Parent:FindFirstChild("HumanoidRootPart") :: BasePart
            burn(attacker, (root or part :: any), function(fire, burnSound)
                while (endTime > workspace:GetServerTimeNow()) and part.Parent do
                    burnSound:Play()
                    task.wait(0.25)
                end
                burnSound:Destroy()
                fire:Destroy()

                if part.Parent then
                    part.Parent:Destroy()
                end
            end)
        end
    },
    SMG = {
        Kind = "Weapon" :: any,
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
            AmmoType = "SMG" :: any
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
        Kind = "Weapon",
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
        Kind = "Weapon",
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
        Kind = "Weapon",
        Name = "Flashbang",
        Description = "Blinds and deafens anyone in its radius. Can be disarmed by shooting it.",

        Slot = 7,
        CanDrop = true,

        Damage = 0,

        FalloffStart = 0,
        FalloffEnd = 0,
        FalloffMultiplier = 1,

        ExplosionInfo = {
            Kind = "Explosion",
            Radius = 17,
            Pressure = 0,
            Damage = 0,
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
            return ReplicatedStorage.ServerClient.Flashbang:FireClient(victim.Player)
        end
    },
    ["Silenced Pistol"] ={
        Kind = "Weapon",
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
            return
        end
    },
    XM1014 = {
        Kind = "Weapon" :: any,
        Name = "XM1014" :: any,
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
            AmmoType = "Shotgun" :: any,
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
        Kind = "Weapon",
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
        Kind = "Weapon",
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
    },
    BAR = {
        Kind = "Weapon",
        Name = "BAR",
        Description = "Heavy automatic rifle",

        Slot = 3,
        CanDrop = true,

        Damage = {
            Head = 75,
            Body = 40,
            Limb = 25
        },

        Spread = 0.75,
        Recoil = 0.7,

        FalloffStart = 50,
        FalloffEnd = 120,
        FalloffMultiplier = 0.3,

        AimInfo = {
            FOV = 65,
            SpreadMultiplier = 0.2
        },

        MultiUse = {
            FireTime = 0.1,
            ReloadTime = 2.5,
            MagazineSize = 20,
            MaxReserve = 100,
            AmmoType = "Assault Rifle"
        },

        Model = models.BAR,
        FiredSound = firedSounds.BAR,
        ReloadSound = reloadSounds.BAR,

        ProjectileInfo = {
            Base = bullet,
            Speed = 120
        }
    },
    ["Magneto Stick"] = {
        Kind = "Item",
        Name = "Magneto Stick",
        Description = "Haha props",
        Slot = 5,
        CanDrop = false,

        Model = models["Magneto Stick"],
        AlternateFire = function(participant: Types.Participant, cameraRayInfo: Ray)
            local char = participant.Character
            if not char then
                return
            end

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
            rayParams.RespectCanCollide = true
            rayParams.CollisionGroup = "Bounds"

            local result = workspace:Raycast(head.Position, cameraRayInfo.Direction * 10, rayParams)
            if not result then
                return
            end

            local object = result.Instance :: BasePart

            if (props and not props:IsAncestorOf(object)) and (weaponSpawns and not weaponSpawns:IsAncestorOf(object)) then
                return print("not a prop")
            end

            if object:GetAttribute("NoGrab") then
                return print("no grab")
            end

            if alreadyControlled == object then
                return print("already controlled")
            end

            if object.AssemblyMass == math.huge then -- anchored props have inf assemblymass
                return print("anchored")
            end

            if (object.AssemblyMass > 50) or (object.Size.X * object.Size.Y * object.Size.Z > 50) then -- Mostly arbitrarily chosen by looking at Skyscraper and Mesa Monocraft props
                return print("too big")
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
                return print("Already controlling prop")
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
            print("primary fire", plr, cameraRayInfo)
        end,
        OnUnequip = function(plr: Player)
            local userId = plr.UserId
            local prop = controlledProps[userId]
            if prop then
                stopControllingProp(prop, userId)
            end
        end
    },
    ["Newton Launcher"] = {
        Kind = "Item",
        Slot = 8,
        Name = "Newton Launcher",
        Description = "Haha props",
        CanDrop = true,
        Model = models["Newton Launcher"],
        PrimaryFire = function(participant: Types.Participant, cameraRayInfo: Ray)
            local char = participant.Character

            local roundId = ServerStorage:GetAttribute("RoundID")
            if not roundId then
                return
            end

            local rayParams = RaycastParams.new()
            rayParams.CollisionGroup = "Bounds"
            rayParams.IgnoreWater = true
            rayParams.RespectCanCollide = true
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            rayParams.FilterDescendantsInstances = {char}
            local result = workspace:Raycast(char:GetPivot().Position, cameraRayInfo.Direction * 1000, rayParams)

            if not result then
                return
            end

            local object = result.Instance
            local model = object:FindFirstAncestorOfClass("Model")
            
            local map = participant.Round.Map
            local weaponSpawns = map:FindFirstChild("WeaponSpawns")
            local props = map:FindFirstChild("Props")

            if not ((weaponSpawns and object:IsDescendantOf(weaponSpawns)) or (props and object:IsDescendantOf(props)) or (model and Players:GetPlayerFromCharacter(model))) then
                return
            end

            local force = Instance.new("BodyForce")
            force.Force = cameraRayInfo.Direction * 10000 + Vector3.new(0, 5000, 0)
            force.Parent = object

            task.delay(0.5, function()
                force:Destroy()
            end)
        end
    }
} :: any) :: {[string]: ItemTypes.ItemDefinition | ItemTypes.WeaponDefinition}