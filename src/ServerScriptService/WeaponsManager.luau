local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local GetRound = require(script.Parent.GetRound)
local CalculateDamageModifier = require(script.Parent.Parent.ReplicatedFirst.CalculateDamageModifier)
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

    local damage: number
    if type(weapon.Damage) == "table" then
        if isOf("Head") then
            damage = weapon.Damage.Head
        elseif isOf("HumanoidRootPart") or isOf("Torso", true) then
            damage = weapon.Damage.Body
        else
            damage = weapon.Damage.Limb
        end
    else
        damage = weapon.Damage
    end

    local start = weapon.FalloffStart or 0
    if distance >= start then
        local multiplier = API.LerpNumber(1, (weapon.FalloffMultiplier or 0), (distance - start) / (weapon.FalloffEnd or (weapon :: ItemTypes.ExplosionInfo).Radius))
        if multiplier < 0 then
            multiplier = 0
        end
        damage *= multiplier
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
    elseif not entity:HasHealth() then
        return
    end

    local canDamage = if sameTeam then round.Gamemode.FriendlyFire else true
    if canDamage then
        if entity.Kind == "Participant" then
            local health = (entity :: any):GetHealth() :: number
            local willDie = health - damage <= 0

            if willDie then
                local force
                if weapon.Kind ~= "Explosion" and weapon.ProjectileInfo then
                    force = weapon.ProjectileInfo.Speed
                elseif weapon.Kind == "Explosion" then
                    force = (weapon :: ItemTypes.ExplosionInfo).Pressure
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
            return ShatterGlass(part, (rayResult.Position - origin).Unit * if weapon.ProjectileInfo then math.max(weapon.ProjectileInfo.Speed / 50, 3) else 3)
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
    elseif not model or not model:GetAttribute("IsCorpse") then
        ReplicatedStorage.ServerClient.MakeBulletHole:FireAllClients(part, rayResult.Position, rayResult.Normal)

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
    local participantsHit = {}

    explosion.Hit:Connect(function(hit, distance)
        local entity: Entity
        if props and hit:IsDescendantOf(props) then
            local prop = findPropAncestor(hit, props)
            if not prop then
                return
            end
            entity = round:GetProp(prop)
            if table.find(propsHit, entity) then
                return
            end
            table.insert(propsHit, entity)
        elseif windows and hit:IsDescendantOf(windows) then
            return ShatterGlass(hit, (hit.Position - position).Unit * explosionInfo.Pressure / distance)
        elseif hit.Parent and hit.Parent:IsA("Model") and hit.Parent:FindFirstChildOfClass("Humanoid") then
            local participant = round:GetParticipant(hit.Parent.Name)
            if not participant or table.find(participantsHit, participant) then
                return
            end
            entity = participant
            table.insert(participantsHit, participant)
        else
            return
        end
        onEntityHit(round, explosionInfo, attacker, entity, hit, (hit.Position - position).Magnitude, (hit.Position - position).Unit)
    end)

    explosion.Parent = workspace.Projectiles
end

function module.Shoot(player: Player, weapon: ItemTypes.Weapon, cameraRayInfo: Ray): ()
    if weapon.Reloading then
        return
    end

    local char = player.Character
    if not char then
        return
    end

    if weapon.LastFireTime + (if weapon.Base.MultiUse then weapon.Base.MultiUse.FireTime else 0) > workspace:GetServerTimeNow() then
        return
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

    if weapon.CurrentAmmo <= 0 then
        local sound = ReplicatedStorage.WeaponSounds.EmptyClip:Clone()
        sound.Parent = char.PrimaryPart
        return sound:Destroy()
    end

    weapon.CurrentAmmo -= 1
    InventoryManager.UpdateAmmo(player)
    
    weapon.LastFireTime = workspace:GetServerTimeNow()

    local firedSound = weapon.Base.FiredSound:Clone()
    firedSound.Parent = char.PrimaryPart
    firedSound.Ended:Once(function()
        firedSound:Destroy()
    end)
    firedSound:Play()

    local head = char:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then
        return
    end
    local origin = head.Position

    local random = Random.new()
    local spread = math.rad(weapon.Base.Spread)

    local function nextSpread(): number
        return random:NextNumber(-spread, spread)
    end
    
    --todo: should this be on the client instead?
    local function tweenProjectile(targetPosition: Vector3): ()
        local projectileInfo = weapon.Base.ProjectileInfo
        if projectileInfo then
            assert(typeof(projectileInfo) ~= "boolean") -- projectileInfo gets reduced to true... from a type of false | ProjectileInfo...

            local projectile = projectileInfo.Base
            ReplicatedStorage.ServerClient.TweenProjectile:FireAllClients(projectile, origin, targetPosition, projectileInfo.Speed)
        end
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    rayParams.RespectCanCollide = false
    rayParams.FilterDescendantsInstances = {char, workspace.Projectiles}
    rayParams.CollisionGroup = "Raycasts"

    for _ = 1, weapon.Base.BulletsPerShot or 1 do
        local spreadVector = Vector3.new(nextSpread(), nextSpread(), nextSpread())
        local target = (cameraRayInfo.Direction + spreadVector) * 10000

        local result = workspace:Raycast(origin, target, rayParams)
        if not result then
            return tweenProjectile(target)
        end

        tweenProjectile(result.Position)

        onPartHit(round, weapon.Base, attacker, result, origin)
    end
end

return module