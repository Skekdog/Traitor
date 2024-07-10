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
end

local weapons: {[string]: ItemTypes.WeaponDefinition} = {
    Grenade = {
        Kind = "Weapon",
        Name = "Grenade",
        Description = "Kaboom",

        ProjectileInfo = {
            Base = projectiles:WaitForChild("Grenade") :: PVInstance,
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

        Model = models:WaitForChild("Grenade"),
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
        },
        Model = models:WaitForChild("Crowbar"),
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
            MagazineSize = 250,
        },

        ProjectileInfo = {
            Base = bullet,
            Speed = 140
        },

        Model = models:WaitForChild("HUGE"),
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
            AmmoType = "Scout"
        },

        Model = models:WaitForChild("Scout"),
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
            AmmoType = "Assault Rifle"
        },

        Model = models:WaitForChild("Pistol"),
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
            Base = projectiles:WaitForChild("GoldenBullet") :: PVInstance,
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
            MagazineSize = 6,
        },

        Model = models["Flare Gun"],
        FiredSound = firedSounds["Flare Gun"],

        ProjectileInfo = {
            Base = projectiles:WaitForChild("Flare") :: PVInstance,
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
            AmmoType = "SMG"
        },

        Model = models:WaitForChild("SMG"),
        FiredSound = firedSounds:WaitForChild("SMG"),
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
            MagazineSize = 4,
        },

        Model = models:WaitForChild("AWP"),
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
            Base = projectiles:WaitForChild("Flashbang") :: PVInstance,
            Speed = 80,
        },

        Model = models:WaitForChild("Flashbang"),
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
            AmmoType = "Assault Rifle"
        },

        Model = models["Silenced Pistol"],
        FiredSound = firedSounds["Silenced Pistol"],
        ReloadSound = reloadSounds["Silenced Pistol"],

        ProjectileInfo = {
            Base = projectiles:WaitForChild("SilencedBullet") :: PVInstance,
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
            AmmoType = "Shotgun",
        },
        BulletsPerShot = 6,

        ProjectileInfo = {
            Base = bullet,
            Speed = 150
        },

        Model = models:WaitForChild("XM1014"),
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
            AmmoType = "Assault Rifle"
        },

        ProjectileInfo = {
            Base = bullet,
            Speed = 190
        },

        Model = models:WaitForChild("Glock"),
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
            AmmoType = "Deagle"
        },

        ProjectileInfo = {
            Base = bullet,
            Speed = 190
        },

        Model = models:WaitForChild("Deagle"),
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
            AmmoType = "Assault Rifle"
        },

        Model = models:WaitForChild("BAR"),
        FiredSound = firedSounds.BAR,
        ReloadSound = reloadSounds.BAR,

        ProjectileInfo = {
            Base = bullet,
            Speed = 120
        }
    },
}

local items: {[string]: ItemTypes.ItemDefinition} = {
    ["Magneto Stick"] = {
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
    },
}

local combinedItems: {[string]: ItemTypes.ItemDefinition | ItemTypes.WeaponDefinition} = {}
for _, v in items do
    combinedItems[v.Name] = v
end
for _, v in weapons do
    combinedItems[v.Name] = v
end

return combinedItems