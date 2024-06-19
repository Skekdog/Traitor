local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local ItemTypes = require(script.Parent.ItemsManager.ItemTypes)
local Types = require(ReplicatedFirst.RoundHandler.Types)
local RoundHandler = require(script.Parent.RoundHandler.RoundHandler)
local API = require(ReplicatedFirst.API)
local Adapters = require(ServerScriptService.Adapters)

local module = {}

local function calculateDamage(attacker: Types.Participant?, weapon: ItemTypes.WeaponDefinition | ItemTypes.ExplosionInfo, partName: string, distance: number): number
    local damage: number
    if type(weapon.Damage) == "table" then
        if partName == "Head" then
            damage = weapon.Damage.Head
        elseif partName == "HumanoidRootPart" or partName:match("Torso") then
            damage = weapon.Damage.Body
        else
            damage = weapon.Damage.Limb
        end
    else
        damage = weapon.Damage
    end

    local start = weapon.FalloffStart or 0
    if distance >= start then
        damage *= API.LerpNumber(1, (weapon.FalloffMultiplier or 0), (distance - start) / (weapon.FalloffEnd or (weapon :: ItemTypes.ExplosionInfo).Radius))
    end

    if attacker then
        damage *= Adapters.CalculateDamageModifier(attacker.Karma)
    end

    return damage
end

type Entity = Types.Participant | Types.Prop
local function onEntityHit(round: Types.Round, weapon: ItemTypes.WeaponDefinition | ItemTypes.ExplosionInfo, attacker: Types.Participant?, entity: Entity, partName: string, distance: number): ()
    local damage = calculateDamage(attacker, weapon, partName, distance)

    local hum: Humanoid?
    local sameTeam: boolean?
    if entity.Kind == "Participant" then
        hum = entity.Character:FindFirstChildOfClass("Humanoid")
        if not hum then
            return
        end

        if attacker then
            sameTeam = round:IsRoleAlliedWith(attacker.Role, entity.Role)
        end
    else
        hum = entity.Humanoid
    end

    local canDamage = if sameTeam then round.Gamemode.FriendlyFire else true
    if canDamage and hum then
        local willDie = (hum.Health - damage) <= 0
        if entity.Kind == "Participant" then
            if weapon.BeforeHitParticipant then
                if weapon.BeforeHitParticipant(attacker, entity, willDie, partName) then
                    return
                end
            end
            if willDie then
                local death = (entity.Character.PrimaryPart :: BasePart):FindFirstChild("DeathSound", true) :: Sound?
                if death and partName == "Head" then
                    death.Volume = 0
                end
                if weapon.Kind == "Explosion" then
                    entity:Kill(attacker, "Explosion", false, false)
                else
                    entity:Kill(attacker, round:GetEquipment(weapon.Name), partName == "Head", false)
                end
            elseif attacker and not attacker:HasSelfDefenseAgainst(entity) then
                entity:AddSelfDefense(attacker, 15)
            end

            if attacker then
                local karmaDiff = damage * 1.5
                karmaDiff *= if attacker:IsDamageJustifiedAgainst(entity) then 1 else -1
                attacker.Karma += karmaDiff
            end
        elseif willDie and not entity.PropInstance:GetAttribute("Destroyed") then
            entity.PropInstance:SetAttribute("Destroyed", true)
            entity:OnBreak()
            entity.PropInstance:Destroy()
        end
        
        hum.Health -= damage
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

local function shatterGlass(glass: BasePart)
    local fragmentSize = 1
    local fragments = {}

    local glassCFrame = glass.CFrame
    local glassSize = glass.Size
    local glassColor = glass.Color

    local random = Random.new()

    local function createFragment(position, size)
        local fragment = Instance.new("WedgePart")
        fragment.Size = size
        fragment.Anchored = false
        fragment.Color = glassColor
        fragment.Position = position
        fragment.Orientation = Vector3.new(math.random() * 360, math.random() * 360, math.random() * 360)
        fragment.Transparency = 0.8
        
        fragment.CanQuery = false
        fragment.CanTouch = false
        fragment.CastShadow = false
        
        fragment.Parent = workspace.Projectiles

        table.insert(fragments, fragment)
    end

    local halfSizeX = glassSize.X / 2
    local halfSizeZ = glassSize.Z / 2

    for x = -halfSizeX, halfSizeX, fragmentSize do
        for z = -halfSizeZ, halfSizeZ, fragmentSize do
            local localPosition = Vector3.new(x, 0, z)
            local worldPosition = glassCFrame:PointToWorldSpace(localPosition)
            local fragmentDimensions = Vector3.new(
                random:NextNumber(fragmentSize / 2, fragmentSize),
                glassSize.Y,
                glassSize.Z
            )
            createFragment(worldPosition, fragmentDimensions)
        end
    end

    glass:Destroy()

    task.delay(5, function()
        for _, v in fragments do
            v:Destroy()
        end
        table.clear(fragments)
    end)
end

local function onPartHit(round: Types.Round, weapon: ItemTypes.WeaponDefinition, attacker: Types.Participant?, rayResult: RaycastResult): ()
    if round:IsRoundPreparing() then
        return
    end
    local part = rayResult.Instance
    local parent = part.Parent
    assert(part:IsA("BasePart") and parent)

    local plr = Players:GetPlayerFromCharacter(parent :: Model)
    if plr then
        local victim = round:GetParticipant(plr.Name)
        if not victim then
            return
        end

        onEntityHit(round, weapon, attacker, victim, part.Name, rayResult.Distance)
    elseif not parent:GetAttribute("IsCorpse") then
        local windows = round.Map:FindFirstChild("Windows")
        if windows then
            if part:IsDescendantOf(windows) then
                shatterGlass(part)
                return
            end
        end

        local impactHole = Instance.new("Part")
        impactHole.Anchored = false
        impactHole.Transparency = 1
        impactHole.Size = Vector3.new(0.5, 0.5, 0.1)
        impactHole.CFrame = CFrame.lookAt(rayResult.Position, rayResult.Position + rayResult.Normal)
        
        impactHole.CanCollide = false
        impactHole.CanTouch = false
        impactHole.CanQuery = false
        
        local impactDecal = Instance.new("Decal")
        impactDecal.Texture = "rbxassetid://130624105"
        impactDecal.Color3 = part.Color
        impactDecal.Parent = impactHole
        
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = part
        weld.Part1 = impactHole
        weld.Parent = rayResult.Instance

        task.delay(5, function()
            if impactHole:IsDescendantOf(workspace) then
                return
            end
            local tween = TweenService:Create(impactDecal, TweenInfo.new(5), {Transparency = 1})
            tween.Completed:Connect(function()
                if not impactHole:IsDescendantOf(workspace) then
                    return
                end
                weld:Destroy()
                impactHole:Destroy()
            end)

            impactHole.Destroying:Once(function()
                if tween.PlaybackState == Enum.PlaybackState.Playing then
                    tween:Cancel()
                end
            end)

            tween:Play()
        end)
        
        impactHole.Parent = part

        local mapProps = round.Map:FindFirstChild("Props") :: Types.PropsStructure?
        if mapProps and part:IsDescendantOf(mapProps) then
            local prop = round._props[findPropAncestor(part, mapProps) :: Types.PropInstance]
            if not prop then
                return
            end
            onEntityHit(round, weapon, attacker, prop, part.Name, rayResult.Distance)
        end
    elseif weapon.BeforeHitCorpse then
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

    local round
    if attacker then
        round = attacker.Round
    else
        local roundId = ServerStorage:GetAttribute("RoundID")
        if not roundId then
            return
        end
        round = RoundHandler.GetRound(roundId)
    end

    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Include
    overlapParams.FilterDescendantsInstances = {workspace}

    local props = round.Map:FindFirstChild("Props")
    local windows = round.Map:FindFirstChild("Windows")

    local propsHit = {}
    local participantsHit = {}
    for _, v in workspace:GetPartBoundsInRadius(position, explosionInfo.Radius, overlapParams) do
        local entity: Entity
        if props and v:IsDescendantOf(props) then
            local prop = findPropAncestor(v, props)
            if not prop then
                continue
            end
            entity = round:GetProp(prop)
            if table.find(propsHit, entity) then
                continue
            end
            table.insert(propsHit, entity)
        elseif windows and v:IsDescendantOf(windows) then
            shatterGlass(v)
            continue
        elseif v.Parent and v.Parent:IsA("Model") and v.Parent:FindFirstChildOfClass("Humanoid") then
            local participant = round:GetParticipant(v.Parent.Name)
            if not participant or table.find(participantsHit, participant) then
                continue
            end
            entity = participant
            table.insert(participantsHit, participant)
        else
            continue
        end
        onEntityHit(round, explosionInfo, attacker, entity, v.Name, (v.Position - position).Magnitude)
    end

    explosion.Parent = workspace.Projectiles
end

function module.Shoot(player: Player, weapon: ItemTypes.Weapon, cameraRayInfo: Ray): ()
    local char = player.Character
    if not char then
        return
    end

    if weapon.CurrentAmmo <= 0 then
        return
    end

    if weapon.LastFireTime + (if weapon.Base.MultiUse then weapon.Base.MultiUse.FireTime else 0) > workspace:GetServerTimeNow() then
        return
    end

    local roundId = ServerStorage:GetAttribute("RoundID")
    local round = RoundHandler.GetRound(roundId)
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

    weapon.CurrentAmmo -= 1
    weapon.LastFireTime = workspace:GetServerTimeNow()

    local firedSound = weapon.Base.FiredSound:Clone()
    firedSound.Parent = char.PrimaryPart
    firedSound.Ended:Once(function()
        firedSound:Destroy()
    end)
    firedSound:Play()

    local origin = char:GetPivot().Position

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

            local projectile = projectileInfo.Base:Clone()
            projectile:PivotTo(CFrame.lookAt(origin, targetPosition))

            local tween = TweenService:Create(projectile, TweenInfo.new((origin - targetPosition).Magnitude / projectileInfo.Speed), {Position = targetPosition})

            tween.Completed:Once(function()
                projectile:Destroy()
            end)

            tween:Play()

            projectile.Parent = workspace.Projectiles
        end
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    rayParams.RespectCanCollide = true
    rayParams.FilterDescendantsInstances = {char, workspace.Projectiles}
    rayParams.CollisionGroup = "Bounds"

    for _ = 1, weapon.Base.BulletsPerShot or 1 do
        local spreadVector = Vector3.new(nextSpread(), nextSpread(), nextSpread())
        local target = (cameraRayInfo.Direction + spreadVector) * 10000

        local result = workspace:Raycast(origin, target, rayParams)
        if not result then
            return tweenProjectile(target)
        end

        tweenProjectile(result.Position)

        onPartHit(round, weapon.Base, attacker, result)
    end
end

return module