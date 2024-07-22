local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local GetRound = require(script.Parent.GetRound)
local HitSounds = require(script.Parent.HitSounds)
local CalculateDamageModifier = require(script.Parent.Parent.ReplicatedFirst.CalculateDamageModifier)
local PlayAnimation = require(script.Parent.PlayAnimation)
local PlayPositionalSound = require(script.Parent.PlayPositionalSound)
local InventoryManager = require(ReplicatedFirst.InventoryManager)
local ShatterGlass = require(ReplicatedFirst.ShatterGlass)
local ItemTypes = require(ReplicatedFirst.ItemsManager.ItemTypes)
local Types = require(ReplicatedFirst.RoundHandler.Types)
local API = require(ReplicatedFirst.API)

local module = {}

local function calculateDamage(attacker: Types.Participant?, weapon: ItemTypes.WeaponDefinition | ItemTypes.ExplosionInfo, part: BasePart, distance: number): number
    local function isOf(name: string, match: boolean?): boolean?
        local accessoryWeld = part:FindFirstChild("AccessoryWeld") :: Weld
        if accessoryWeld and accessoryWeld.Part1 and accessoryWeld.Part1.Name == name then
            if accessoryWeld.Part1.Name == name or (match and (accessoryWeld.Part1.Name:match(name) ~= nil)) then
                return true
            end
        end
        return (part.Name == name) or (part:FindFirstAncestor(name) ~= nil) or (match and (part.Name:match(name) ~= nil))
    end

    local damageData = if weapon.Kind == "Grenade" then weapon.ExplosionInfo.Damage else weapon.Damage
    local damage: number
    if type(damageData) == "table" then
        if isOf("Head") then
            damage = damageData.Head
        elseif isOf("HumanoidRootPart") or isOf("Torso", true) then
            damage = damageData.Body
        else
            damage = damageData.Limb
        end
    else
        damage = damageData
    end

    if weapon.Kind == "Gun" or weapon.Kind == "Explosion" then
        local start = weapon.FalloffStart or 0
        if distance >= start then
            local multiplier = API.LerpNumber(1, (weapon.FalloffMultiplier or 0), (distance - start) / (weapon.FalloffEnd or (weapon :: ItemTypes.ExplosionInfo).Radius))
            if multiplier < 0 then
                multiplier = 0
            end
            damage *= multiplier
        end
    end

    if attacker then
        damage *= CalculateDamageModifier(attacker.Karma)
    end

    return damage
end

type Entity = Types.Participant | Types.Prop
local function onEntityHit(round: Types.Round, weapon: ItemTypes.WeaponDefinition | ItemTypes.ExplosionInfo, attacker: Types.Participant?, entity: Entity, part: BasePart, distance: number, direction: Vector3): ()
    local damage = calculateDamage(attacker, weapon, part, distance)

    local sameTeam: boolean?
    if entity.Kind == "Participant" then
        if attacker then
            sameTeam = round:IsRoleAlliedWith(attacker.Role, entity.Role)
        end
    else
        if weapon.BeforeHitProp then
            if weapon.BeforeHitProp(attacker, entity, if entity:HasHealth() then entity:GetHealth() - damage <= 0 else false, part.Name) then
                return
            end
        end
        if not entity:HasHealth() then
            return
        end
    end

    local canDamage = if sameTeam then round.Gamemode.FriendlyFire else true
    if canDamage then
        local willDie = (entity :: any):GetHealth() - damage <= 0
        if entity.Kind == "Participant" then
            if willDie then
                local force
                if weapon.Kind == "Gun" then
                    force = weapon.ProjectileSpeed
                elseif weapon.Kind == "Explosion" then
                    force = (weapon :: ItemTypes.ExplosionInfo).Pressure
                elseif weapon.Kind == "Grenade" then
                    force = weapon.ExplosionInfo.Pressure
                else
                    force = 1
                end
                part:ApplyImpulse(-direction * force)
            end

            if weapon.BeforeHitParticipant then
                if weapon.BeforeHitParticipant(attacker, entity, willDie, part.Name) then
                    return
                end
            end
            
            -- Would be nicer to use a local for weapon.Kind == "Explosion" but type checker does not reduce correctly then. Here I am writing it out a third time instead :)
            entity:TakeDamage(damage, attacker, if weapon.Kind == "Explosion" then "Explosion" else round:GetEquipment(weapon.Name), part.Name == "Head" and weapon.Kind ~= "Explosion")

            if attacker then
                local karmaDiff = damage * 1.5
                karmaDiff *= if attacker:IsDamageJustifiedAgainst(entity) then 1 else -1
                attacker.Karma += karmaDiff
            end
        else
            entity:TakeDamage(damage, attacker)
        end
    end
end

local function findPropAncestor(prop: Instance, propsFolder: Folder): Types.PropInstance?
    if prop == propsFolder then
        return
    end
    assert(prop.Parent)
    if prop.Parent == propsFolder then
        return prop :: Types.PropInstance
    else
        return findPropAncestor(prop.Parent, propsFolder)
    end
end

local function onPartHit(round: Types.Round, weapon: ItemTypes.WeaponDefinition, attacker: Types.Participant?, rayResult: RaycastResult, origin: Vector3): ()
    local part = rayResult.Instance :: BasePart
    local windows = round.Map:FindFirstChild("Windows")

    if windows then
        if part:IsDescendantOf(windows) then
            return ShatterGlass(part, (rayResult.Position - origin).Unit * if weapon.Kind == "Gun" then math.max(weapon.ProjectileSpeed / 50, 3) else 3)
        end
    end

    if round:IsRoundPreparing() then
        return
    end
    
    local model = part:FindFirstAncestorOfClass("Model")

    local plr = Players:GetPlayerFromCharacter(model :: Model)
    if plr then
        local victim = round:GetParticipant(plr.Name)
        if not victim then
            return
        end

        onEntityHit(round, weapon, attacker, victim, part, rayResult.Distance, (rayResult.Position - origin).Unit)
    elseif not model or not model:IsDescendantOf(workspace.Corpses) then
        ReplicatedStorage.ServerClient.MakeBulletHole:FireAllClients(part, rayResult.Position, rayResult.Normal)

        if weapon.Kind == "Melee" then
            local material = part:GetAttribute("MaterialOverride") or rayResult.Material
            PlayPositionalSound(HitSounds[material] or HitSounds.Default, rayResult.Position)
        end

        local mapProps = round.Map:FindFirstChild("Props") :: Types.PropsStructure?
        if mapProps and part:IsDescendantOf(mapProps) then
            local prop = round._props[findPropAncestor(part, mapProps) :: Types.PropInstance]
            if not prop then
                return
            end
            onEntityHit(round, weapon, attacker, prop, part, rayResult.Distance, (rayResult.Position - origin).Unit)
        end
    elseif model and weapon.BeforeHitCorpse then
        weapon.BeforeHitCorpse(attacker, part)
    end
end

-- WeaponTypes.WeaponDefinition may be nil if it is e.g. an explosive barrel
function module.CreateExplosion(position: Vector3, explosionInfo: ItemTypes.ExplosionInfo, attacker: Types.Participant?, weapon: ItemTypes.WeaponDefinition?): ()
    local explosion = Instance.new("Explosion")
    explosion.BlastRadius = explosionInfo.Radius
    explosion.BlastPressure = explosionInfo.Pressure
    explosion.DestroyJointRadiusPercent = 0
    explosion.ExplosionType = Enum.ExplosionType.NoCraters
    explosion.Position = position

    local soundPart = Instance.new("Part")
    soundPart.Transparency = 1
    soundPart.Anchored = true
    soundPart.CanCollide = false
    soundPart.CanTouch = false
    soundPart.CanQuery = false
	soundPart.Position = position
	soundPart.Parent = workspace.Projectiles
    
	local sound = ServerStorage.Explosion:Clone()
	sound.Parent = soundPart :: any
	sound.Ended:Connect(function()
		soundPart:Destroy()
	end)
    sound:Play()

    local round: Types.Round?
    if attacker then
        round = attacker.Round
    else
        round = GetRound()
    end

    if not round then
        return
    end

    local props = round.Map:FindFirstChild("Props")
    local windows = round.Map:FindFirstChild("Windows")

    local propsHit = {}
    local participantsHit: {Types.Participant} = {}

    local sendWeapon:  Types.Equipment | Types.DeathType = (if weapon then round:GetEquipment(weapon.Name) or "Explosion" else "Explosion")  :: Types.Equipment | Types.DeathType
    local ignoreKarma = if typeof(sendWeapon) == "table" then sendWeapon.NoGuilt else false
    
    for _, part in workspace:GetPartBoundsInRadius(position, explosionInfo.Radius) do
        local distance = (position - part.Position).Magnitude
        if props and part:IsDescendantOf(props) then
            local prop = findPropAncestor(part, props)
            if not prop then
                continue
            end
            local roundProp = round:GetProp(prop)
            if table.find(propsHit, roundProp) then
                continue
            end
            table.insert(propsHit, roundProp)
            onEntityHit(round, explosionInfo, attacker, roundProp, part, distance, (part.Position - position).Unit)
        elseif windows and part:IsDescendantOf(windows) then
            ShatterGlass(part, (part.Position - position).Unit * explosionInfo.Pressure / distance)
        elseif part.Parent and part.Parent:IsA("Model") and part.Parent:FindFirstChildOfClass("Humanoid") then
            local participant = round:GetParticipant(part.Parent.Name)
            if not participant or table.find(participantsHit, participant) or not participant.Character then
                continue
            end

            table.insert(participantsHit, participant)

            participant:TakeDamage(calculateDamage(attacker, explosionInfo, part, distance), attacker, sendWeapon, false, ignoreKarma)

            if explosionInfo.BeforeHitParticipant then
                explosionInfo.BeforeHitParticipant(attacker, participant, false, part.Name)
            end
        end
    end

    if explosionInfo.OnExplode then
        explosionInfo.OnExplode(explosionInfo, position, attacker)
    end

    explosion.Parent = workspace.Projectiles
end

function module.Shoot(player: Player, weapon: ItemTypes.Weapon, cameraRayInfo: Ray): true?
    if weapon.Kind == "Gun" and weapon.Reloading then
        return
    end

    local char = player.Character
    if not char then
        return
    end

    if weapon.Kind == "Gun" or weapon.Kind == "Melee" then
        if weapon.LastFireTime + (weapon.Base.FireTime) > workspace:GetServerTimeNow() then
            return
        end
    end

    local round = GetRound()
    if not round then
        return
    end

    local attacker = round:GetParticipant(player.Name)
    if not attacker then
        return
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then
        return
    end

    local head = char:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then
        return
    end

    local timeNow = workspace:GetServerTimeNow()
    if weapon.Kind == "Gun" then
        if (weapon.CurrentAmmo <= 0) or (weapon.Base.ScopeRequired and not InventoryManager.IsAiming(player)) then
            if weapon.LastFireAttempt + weapon.Base.FireTime < timeNow then
                weapon.LastFireAttempt = timeNow
                local sound = ReplicatedStorage.WeaponSounds.EmptyClip:Clone()
                sound.Parent = char.PrimaryPart
                sound:Destroy()
            end
            return
        end

        weapon.LastFireAttempt = timeNow

        weapon.CurrentAmmo -= 1
        InventoryManager.UpdateAmmo(player)
    end

    if weapon.Kind == "Gun" or weapon.Kind == "Melee" then
        (weapon :: ItemTypes.GunWeapon).LastFireTime = workspace:GetServerTimeNow()
    end

    if weapon.Kind == "Melee" then
        PlayAnimation(player, weapon.Base.HitAnimation, weapon.Base.Name.."HitAnimation")
    end

    local firedSound = weapon.Base.FiredSound:Clone()
    firedSound.Parent = char.PrimaryPart
    firedSound.Ended:Once(function()
        firedSound:Destroy()
    end)
    firedSound:Play()

    local origin = head.Position

    local random = Random.new()

    local spreadNum = 0
    if weapon.Kind == "Gun" then
        spreadNum = weapon.Base.Spread
        if InventoryManager.IsAiming(player) then
            spreadNum *= weapon.Base.AimSpreadMultiplier
        end
    end
    local spread = math.rad(spreadNum)

    local function nextSpread(): number
        return random:NextNumber(-spread, spread)
    end

    if weapon.Kind == "Grenade" then
        InventoryManager.RemoveEquipment(player, weapon)
        local proj = weapon.Base.Model:Clone();
        proj.CollisionGroup = "Grenades"
        proj:PivotTo(CFrame.new(origin))
        proj.Parent = workspace.Projectiles

        proj:ApplyImpulse(weapon.Base.ProjectileForce * head.CFrame.LookVector)

        task.delay(weapon.Base.Fuse, function()
            if not proj:IsDescendantOf(workspace) then
                return
            end

            module.CreateExplosion(proj.Position, weapon.Base.ExplosionInfo, attacker, weapon.Base)
            proj:Destroy()
        end)
    else
        local function tweenProjectile(targetPosition: Vector3): ()
            if weapon.Kind ~= "Gun" then
                return
            end
            ReplicatedStorage.ServerClient.TweenProjectile:FireAllClients(weapon.Base.ProjectileBase, origin, targetPosition, weapon.Base.ProjectileSpeed)
        end
    
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.IgnoreWater = true
        rayParams.RespectCanCollide = false
        rayParams.FilterDescendantsInstances = {char, workspace.Projectiles}
        rayParams.CollisionGroup = "Raycasts"
    
        local amount = if weapon.Kind == "Gun" then weapon.Base.BulletsPerShot or 1 else 1
        for _ = 1, amount do
            local spreadVector = Vector3.new(nextSpread(), nextSpread(), nextSpread())
            local target = (cameraRayInfo.Direction + spreadVector) * if weapon.Kind == "Melee" then weapon.Base.MaxDistance else 10000
    
            local result = workspace:Raycast(origin, target, rayParams)
            if not result then
                tweenProjectile(target)
                if weapon.Kind == "Melee" then
                    return true
                end
                return
            end
    
            tweenProjectile(result.Position)
    
            onPartHit(round, weapon.Base, attacker, result, origin)
        end
    end

    return true
end

return module