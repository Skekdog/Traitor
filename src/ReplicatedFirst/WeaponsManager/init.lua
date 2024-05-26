--!strict
--todo: Look into FastCast
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Types = require(ReplicatedFirst.RoundHandler.Types)
local API = require(ReplicatedFirst.API)
local Adapters = require(ServerScriptService.Adapters)

type BeforeHitFunction = (attacker: Types.Participant?, target: Types.Participant, willDie: boolean) -> ()
type AimInfo = {
    FOV: number,
    HasScope: boolean?,
    ScopeRequired: boolean?,
    SpreadMultiplier: number,
}
type DamageInfo = number | {
    Head: number,
    Body: number,
    Limb: number,
}
type MultiUseInfo = {
    FireTime: number, -- Delay between firing
    ReloadTime: number,
    MaxReserve: number,
    MagazineSize: number,
    AmmoType: AmmoType?,
}
type ProjectileInfo = {
    Base: PVInstance,
    Speed: number,
}

type Entity = Types.Participant | Types.Prop

export type AmmoType = "Shotgun" | "Scout" | "Assault Rifle" | "SMG" | "Deagle"
export type Weapon = {
    Name: string,
    Description: string,

    Slot: number,
    CanDrop: boolean,

    Damage: DamageInfo,

    FalloffStart: number,
    FalloffEnd: number,
    FalloffMultiplier: number,

    ExplosionInfo: ExplosionInfo?,
    FuseTime: number?,

    AimInfo: AimInfo | false, -- nil if aiming should be disabled

    Recoil: number,
    Spread: number,
    
    MultiUse: MultiUseInfo | false,
    BulletsPerShot: number?,

    ProjectileInfo: ProjectileInfo | false,

    Model: Model,

    BeforeHitParticipant: BeforeHitFunction?,
}

export type ExplosionInfo = {
    Radius: number,
    Pressure: number,
    Damage: number?,
    BeforeHitParticipant: BeforeHitFunction?,
    FalloffStart: number?,
    FalloffEnd: number?,
    FalloffMultiplier: number?,
}

local module = {}

local function calculateDamage(attacker: Types.Participant?, weapon: Weapon, partName: string, distance: number): number
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

local function onEntityHit(round: Types.Round, weapon: Weapon, attacker: Types.Participant?, entity: Entity, partName: string, distance: number): ()
    local damage = calculateDamage(attacker, weapon, partName, distance)

    local hum: Humanoid
    local sameTeam: boolean?
    if entity.Kind == "Participant" then
        hum = entity.Character:FindFirstChildOfClass("Humanoid") :: any
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
    if canDamage then
        local willDie = (hum.Health - damage) <= 0
        if entity.Kind == "Participant" then
            if willDie then
                local death = (entity.Character:FindFirstChild("HumanoidRootPart") :: any):FindFirstChild("DeathSound", true)
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

            if weapon.BeforeHitParticipant then
                weapon.BeforeHitParticipant(attacker, entity, willDie)
            end
        elseif willDie then
            entity.OnBreak(entity)
        end
        
        hum.Health -= damage
    end
end

local function onPartHit(round: Types.Round, weapon: Weapon, attacker: Types.Participant?, rayResult: RaycastResult): ()
    if round:IsRoundPreparing() then
        return
    end
    local part = rayResult.Instance
    local parent = part.Parent
    assert(part:IsA("BasePart") and parent and parent:IsA("Model"))

    local plr = Players:GetPlayerFromCharacter(parent)
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
            local tween = TweenService:Create(impactDecal, TweenInfo.new(5), {Transparency = 1})
            tween.Completed:Connect(function()
                weld:Destroy()
                impactHole:Destroy()
            end)
            tween:Play()
        end)
        
        impactHole.Parent = part

        if round.Map.Props:IsAncestorOf(part) then
            local model: Types.Prop = part:FindFirstAncestorOfClass("Model") :: any
            onEntityHit(round, weapon, attacker, model, part.Name, rayResult.Distance)
        end
    end
end

-- Weapon may be nil if it is e.g. an explosive barrel
function module.CreateExplosion(position: Vector3, explosionInfo: ExplosionInfo, attacker: Types.Participant?, weapon: Weapon?): ()
    local explosion = Instance.new("Explosion")
    explosion.BlastRadius = explosionInfo.Radius
    explosion.BlastPressure = explosionInfo.Pressure
    explosion.DestroyJointRadiusPercent = 0
    explosion.ExplosionType = Enum.ExplosionType.NoCraters

    local soundPart = Instance.new("Part")
	soundPart.Transparency = 1
	soundPart.CanTouch = false
	soundPart.CanCollide = false
	soundPart.CanQuery = false
	soundPart.Anchored = true
	soundPart.Position = position
	soundPart.CastShadow = false
	soundPart.Size = Vector3.zero
	soundPart.Parent = (workspace :: any).Proj.ImpactHoles
    
	local sound = (ServerStorage :: any).ExplosionSound:Clone()
	sound.Parent = soundPart
	sound.Ended:Connect(function()
		soundPart:Destroy()
	end)
    sound:Play()

    explosion.Parent = workspace
end

function module.Shoot(player: Player, weapon: Weapon, cameraRayInfo: Ray): ()
    
end

return module