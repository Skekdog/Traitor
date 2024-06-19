local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local ItemTypes = require(ReplicatedFirst.ItemsManager.ItemTypes)
local Types = require(ReplicatedFirst.RoundHandler.Types)
local RoundHandler = require(ReplicatedFirst.RoundHandler.RoundHandler)
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
            entity.Attacker = attacker
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

local function createWedgeFragment(size: Vector3, cframe: CFrame, parent: BasePart)
    local wedge = Instance.new("WedgePart")
    wedge.Size = size
    wedge.CFrame = cframe
    wedge.Anchored = false
    wedge.Color = parent.Color
    wedge.Transparency = parent.Transparency
    wedge.CanTouch = false
    wedge.CanQuery = false
    wedge.Parent = workspace.Projectiles

    wedge:ApplyImpulse((if math.random() >= 0.5 then 1 else -1) * Vector3.one)

    return wedge
end

-- Function to shatter the glass part into a grid of wedge fragments
local function shatterGlass(glass: BasePart)
    local cols = math.max(1, math.floor(glass.Size.X / 3))
    local rows = math.max(1, math.floor(glass.Size.Y / 3))

    local glassSize = glass.Size
    local glassCFrame = glass.CFrame

    -- Calculate the size of each fragment
    local fragmentWidth = glassSize.X / cols
    local fragmentHeight = glassSize.Y / rows
    local fragmentDepth = glassSize.Z / 2  -- Depth of the wedge (half of glass thickness)

    local fragments = {}

    -- Loop through the grid and create fragments
    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            -- Calculate the position for the fragment
            local posX = (col * fragmentWidth) - (glassSize.X / 2) + (fragmentWidth / 2)
            local posY = (row * fragmentHeight) - (glassSize.Y / 2) + (fragmentHeight / 2)
            local posZ = 0

            -- Create the first fragment
            local fragmentCFrame1 = glassCFrame * CFrame.new(posX, posY, posZ) * CFrame.Angles(0, math.rad(-90), 0)

            -- Create the second fragment
            local fragmentCFrame2 = fragmentCFrame1 * CFrame.Angles(0, math.rad(180), math.rad(180))

            -- Create the wedge fragments
            table.insert(fragments, createWedgeFragment(Vector3.new(fragmentDepth, fragmentHeight, fragmentWidth), fragmentCFrame1, glass))
            table.insert(fragments, createWedgeFragment(Vector3.new(fragmentDepth, fragmentHeight, fragmentWidth), fragmentCFrame2, glass))
        end
    end

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://2978605361"
    sound.PlayOnRemove = true
    sound.RollOffMaxDistance = 200
    sound.RollOffMinDistance = 10
    sound.Parent = glass

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
            shatterGlass(hit)
            return
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
        onEntityHit(round, explosionInfo, attacker, entity, hit.Name, (hit.Position - position).Magnitude)
    end)

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