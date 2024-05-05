--!strict
--todo: Look into FastCast
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")
local RoundHandlerTypes = require(ReplicatedFirst.RoundHandlerTypes)
local Adapters = require(ServerScriptService.RoundHandler.Adapters)
local API = require(ReplicatedFirst.API)

type BeforeHitFunction = (attacker: RoundHandlerTypes.Participant?, target: RoundHandlerTypes.Participant, willDie: boolean) -> ()

export type Entity = RoundHandlerTypes.Participant | RoundHandlerTypes.Prop

export type AmmoType = "Assault Rifle" | "SMG" | "Pistol" | "Deagle"
export type Weapon = {
    Name: string,
    Description: string,

    Slot: number,
    CanDrop: boolean?,

    DamageHead: number,
    DamageBody: number,
    DamageLimb: number,

    FalloffStart: number,
    FalloffEnd: number,
    FalloffMultiplier: number,

    ExplosionInfo: ExplosionInfo?,
    FuseTime: number?,

    CanAim: boolean?,
    AimFOV: number,
    AimSensitivityMultiplier: number,

    Recoil: number,
    Spread: number,
    AimSpreadMultiplier: number,

    HasScope: boolean?,
    ScopeRequired: boolean?, -- Required to be scoped in to shoot

    FireTime: number, -- Delay between firing
    BulletsPerShot: number,

    ProjectileBase: PVInstance?,
    ProjectileSpeed: number?,

    ReloadTime: number,
    MaxReserve: number,
    MagazineSize: number,
    AmmoType: AmmoType?,

    BeforeHitParticipant: BeforeHitFunction?,

    Model: Model,
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

local function calculateDamage(attacker: RoundHandlerTypes.Participant?, weapon: Weapon, partName: string, distance: number): number
    local damage
    if partName == "Head" then
        damage = weapon.DamageHead
    elseif partName == "HumanoidRootPart" or partName:match("Torso") then
        damage = weapon.DamageBody
    else
        damage = weapon.DamageLimb
    end

    if distance >= weapon.FalloffStart then
        damage *= API.LerpNumber(1, weapon.FalloffMultiplier, (distance - weapon.FalloffStart) / weapon.FalloffEnd)
    end

    if attacker then
        damage *= Adapters.CalculateDamageModifier(attacker.Karma)
    end

    return damage
end

local function onEntityHit(round: RoundHandlerTypes.Round, weapon: Weapon, attacker: RoundHandlerTypes.Participant?, entity: Entity, partName: string, distance: number): ()
    local damage = calculateDamage(attacker, weapon, partName, distance)

    local hum: Humanoid
    local sameTeam: boolean?
    if type(entity) == "table" then
        hum = entity.Character:FindFirstChildOfClass("Humanoid") :: any
        if not hum then
            return
        end

        if attacker then
            sameTeam = round:CompareRoles(attacker:GetRole(), entity:GetRole(), "__Ally")
        end
    else
        hum = entity.Humanoid
    end

    local canDamage = if sameTeam then round.Gamemode.FriendlyFire else true
    if canDamage then
        if type(entity) == "table" then
            local willDie = false
            if (hum.Health - damage) <= 0 then
                willDie = true

                local death = (entity.Character:FindFirstChild("HumanoidRootPart") :: any):FindFirstChild("DeathSound", true)
                if death and partName == "Head" then
                    death.Volume = 0
                end

                entity:Kill(attacker, round:GetEquipment(weapon.Name), partName == "Head", false)
            elseif attacker and not attacker:HasSelfDefenseAgainst(entity) then
                entity:AddSelfDefense(attacker, 15)
            end

            if attacker and not attacker:HasSelfDefenseAgainst(entity) and #entity.FreeKillReasons < 1 then
                attacker.Karma -= damage * 1.5
            end

            if weapon.BeforeHitParticipant then
                weapon.BeforeHitParticipant(attacker, entity, willDie)
            end
        elseif entity.OnBreak then
            (require)(entity.OnBreak)(if attacker then attacker.Player else nil)
        end
        
        hum.Health -= damage
    end
end

local function onPartHit(round: RoundHandlerTypes.Round, weapon: Weapon, attacker: RoundHandlerTypes.Participant?, rayResult: RaycastResult): ()
    if round:IsRoundPreparing() then
        return
    end
    local part = rayResult.Instance
    local parent = part.Parent
    assert(part:IsA("BasePart") and parent and parent:IsA("Model"))

    local plr = Players:GetPlayerFromCharacter(parent)
    if plr then
        local victim = round:TryGetParticipant(plr.Name)
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
            local model: RoundHandlerTypes.Prop = part:FindFirstAncestorOfClass("Model") :: any
            onEntityHit(round, weapon, attacker, model, part.Name, rayResult.Distance)
        end
    end
end

-- Weapon may be nil if it is e.g. an explosive barrel
function module.CreateExplosion(position: Vector3, explosionInfo: ExplosionInfo, attacker: RoundHandlerTypes.Participant?, weapon: Weapon?): ()
    local explosion = Instance.new("Explosion")
    explosion.BlastRadius = explosionInfo.Radius
    explosion.BlastPressure = explosionInfo.Pressure
    explosion.DestroyJointRadiusPercent = 0
    explosion.ExplosionType = Enum.ExplosionType.NoCraters

    explosion.Parent = workspace
end

function module.Shoot(player: Player, weapon: Weapon, cameraRayInfo: Ray): ()
    
end

return module