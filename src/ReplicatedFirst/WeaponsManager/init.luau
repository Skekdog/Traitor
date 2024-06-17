local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Types = require(ReplicatedFirst.RoundHandler.Types)
local RoundHandler = require(script.Parent.RoundHandler.RoundHandler)
local WeaponsTypes = require(script.WeaponsTypes)
local API = require(ReplicatedFirst.API)
local Adapters = require(ServerScriptService.Adapters)

local module = {}

local function calculateDamage(attacker: Types.Participant?, weapon: WeaponsTypes.Weapon, partName: string, distance: number): number
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

    if distance >= weapon.FalloffStart then
        damage *= API.LerpNumber(1, weapon.FalloffMultiplier, (distance - weapon.FalloffStart) / weapon.FalloffEnd)
    end

    if attacker then
        damage *= Adapters.CalculateDamageModifier(attacker.Karma)
    end

    return damage
end

local function onEntityHit(round: Types.Round, weapon: WeaponsTypes.Weapon, attacker: Types.Participant?, entity: WeaponsTypes.Entity, partName: string, distance: number): ()
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
                entity:Kill(attacker, round:GetEquipment(weapon.Name), partName == "Head", false)
            elseif attacker and not attacker:HasSelfDefenseAgainst(entity) then
                entity:AddSelfDefense(attacker, 15)
            end

            if attacker then
                local karmaDiff = damage * 1.5
                karmaDiff *= if attacker:IsDamageJustifiedAgainst(entity) then 1 else -1
                attacker.Karma += karmaDiff
            end
        elseif willDie then
            entity.OnBreak(entity)
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

local function onPartHit(round: Types.Round, weapon: WeaponsTypes.Weapon, attacker: Types.Participant?, rayResult: RaycastResult): ()
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
    else
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
            if not impactHole.Parent then
                return
            end
            local tween = TweenService:Create(impactDecal, TweenInfo.new(5), {Transparency = 1})
            tween.Completed:Connect(function()
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
            local prop = round:GetProp(findPropAncestor(part, mapProps) :: Types.PropInstance)
            onEntityHit(round, weapon, attacker, prop, part.Name, rayResult.Distance)
        end
    end
end

-- WeaponsTypes.Weapon may be nil if it is e.g. an explosive barrel
function module.CreateExplosion(position: Vector3, explosionInfo: WeaponsTypes.ExplosionInfo, attacker: Types.Participant?, weapon: WeaponsTypes.Weapon?): ()
    local explosion = Instance.new("Explosion")
    explosion.BlastRadius = explosionInfo.Radius
    explosion.BlastPressure = explosionInfo.Pressure
    explosion.DestroyJointRadiusPercent = 0
    explosion.ExplosionType = Enum.ExplosionType.NoCraters

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

    explosion.Parent = workspace
end

function module.Shoot(player: Player, weapon: WeaponsTypes.Weapon, cameraRayInfo: Ray): ()
    local char = player.Character
    if not char then
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

    local firedSound = weapon.FiredSound:Clone()
    firedSound.Parent = char.PrimaryPart
    firedSound.Ended:Once(function()
        firedSound:Destroy()
    end)
    firedSound:Play()

    local origin = char:GetPivot().Position

    local random = Random.new()
    local spread = math.rad(weapon.Spread)

    local function nextSpread(): number
        return random:NextNumber(-spread, spread)
    end
    
    --todo: should this be on the client instead?
    local function tweenProjectile(targetPosition: Vector3): ()
        local projectileInfo = weapon.ProjectileInfo
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

    for _ = 1, weapon.BulletsPerShot or 1 do
        local spreadVector = Vector3.new(nextSpread(), nextSpread(), nextSpread())
        local target = (cameraRayInfo.Direction + spreadVector) * 10000

        local result = workspace:Raycast(origin, target, rayParams)
        if not result then
            return tweenProjectile(target)
        end

        tweenProjectile(result.Position)

        onPartHit(round, weapon, attacker, result)
    end
end

return module