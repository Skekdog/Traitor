local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)
local Ammo = require(script.Parent.Ammo)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local function models(name: string): BasePart
    return ReplicatedStorage.Assets:WaitForChild("WeaponModels"):WaitForChild(name) :: BasePart
end

local function firedSounds(name: string): string
    return (ReplicatedStorage.Assets:WaitForChild("WeaponSounds"):WaitForChild("Fired"):WaitForChild(name) :: Sound).SoundId
end

local function projectiles(name: string): BasePart
    return ReplicatedStorage.Assets:WaitForChild("Projectiles"):WaitForChild(name) :: BasePart
end

local function weaponSounds(name: string): string
    return (ReplicatedStorage.Assets:WaitForChild("WeaponSounds"):WaitForChild(name) :: Sound).SoundId
end

type BurnTarget = Types.Participant | Types.Prop
type BurnInfo = {
    LastBurn: number,
    BurnUntil: number,
    FireEffect: Fire,
    Attacker: Types.Participant?,
}

local burningThings: {[BurnTarget]: BurnInfo} = {}

local function burn(attacker: Types.Participant, target: BurnTarget): ()
    if target.Kind ~= "Participant" and burningThings[target] then
        return
    end

    local part: BasePart
    if target.Kind == "Participant" then
        local character = target:GetCharacter()
        if not character then
            return
        end

        local root = character.PrimaryPart
        if not root then
            return
        end

        part = root
    elseif target.Kind == "MapProp" or target.Kind == "AmmoProp" or target.Kind == "ItemProp" then
        part = target.Model
    elseif target.Kind == "CorpseProp" then
        local root = target.Model.PrimaryPart
        if not root then
            return
        end

        part = root
    end

    local fire = Instance.new("Fire")
    fire.Size = 10
    fire.Parent = part

    local burnSound = Instance.new("Sound")
    burnSound.SoundId = weaponSounds("FlareBurn")
    burnSound.Parent = part

    if target.Kind == "MapProp" then
        part:SetAttribute("Burning", true)
    elseif target.Kind == "CorpseProp" then
        target.Model:SetAttribute("Burning", true)
    end
    
    burningThings[target] = {
        LastBurn = tick(),
        BurnUntil = tick() + 10,
        FireEffect = fire,
        Attacker = attacker,
    }
end

local function stopBurning(target: BurnTarget): ()
    local info = burningThings[target]
    assert(info, "Attempt to stop burning thing which is not burning")

    burningThings[target] = nil

    info.FireEffect:Destroy()

    if target.Kind ~= "Participant" then
        target.Model:SetAttribute("Burning", false)

        if target.Kind == "CorpseProp" then
            target.Model:Destroy()
        end
    end
end

local function burnTouchingParticipants(prop: Types.MapProp): ()
    local burnedParticipants: {Types.Participant} = {}
    for _, v in workspace:GetPartsInPart(prop.Model) do
        local model = v:FindFirstAncestorOfClass("Model")
        if not model then
            continue
        end

        local participant = prop.Round:GetParticipant(model.Name)
        if not participant then
            continue
        end

        if table.find(burnedParticipants, participant) then
            continue
        end

        table.insert(burnedParticipants, participant)

        participant:TryTakeDamage({
            Amount = 1,
            Source = "Burn",
        })
    end
end

local function burnThing(target: BurnTarget, info: BurnInfo): ()
    local timeNow = tick()
    if timeNow > info.BurnUntil then
        return stopBurning(target)
    end

    local model = if target.Kind == "Participant" then target:GetCharacter() else target.Model
    if not model or not model:IsDescendantOf(workspace) then
        return stopBurning(target)
    end

    if timeNow < info.LastBurn + 0.25 then
        return
    end
    
    info.LastBurn = timeNow

    PlaySound(weaponSounds("FlareBurn"), nil, model, {SoundGroup = SoundService.AllSounds :: SoundGroup})

    if target.Kind == "Participant" or target.Kind == "MapProp" then
        local health = (target :: Types.MapProp):GetHealth()
        if health and health <= 0 then
            return stopBurning(target)
        end

        if target.Kind == "MapProp" then
            burnTouchingParticipants(target)
        end

        if health then
            (target :: Types.MapProp):TryTakeDamage({
                Amount = 1,
                Source = "Burn",
                Attacker = info.Attacker,
            })
        end
    end
end

local function burnHeartbeat(): ()
    for target, info in burningThings do
        burnThing(target, info)
    end
end

local item: Types.GunWeaponDefinition = {
	Kind = "Gun" :: "Gun",
    Name = "Flare Gun",
    Description = "Will set things it hits on fire. Can be used to burn corpses, preventing others from discovering them.",
    Icon = "rbxassetid://444145395",
    CreditCost = 1,
    MaxStock = 1,

    IsBadGuyItem = true,

    Slot = 8,
    CanDrop = true,

    Damage = {
        Head = 15,
        Body = 10,
        Limb = 5,
    },

    AmmoType = Ammo.Flare,
    ReloadSound = "",

    HasMuzzleFlash = true,

    Spread = 0.015,

    AttackInterval = 0.25,
    ReloadTime = 0,
    MagazineSize = 6,

    Model = models("Flare Gun"),
    HoldAnimation = "rbxassetid://9253211833",
    AimAnimation = "rbxassetid://18691552315",
    AttackSound = firedSounds("Flare Gun"),

    Projectile = projectiles("Flare"),
    ProjectileSpeed = 140,

    AimFOV = 60,
    AimSpreadMultiplier = 0.3,

    BeforeHitParticipant = function(_, _, target: Types.Participant, params: Types.DamageParams): boolean
        local attacker = params.Attacker
        assert(attacker)
        burn(attacker, target)
        return true
    end,

    BeforeHitProp = function(_, _, target: Types.Prop, params: Types.DamageParams): boolean
        local attacker = params.Attacker
        assert(attacker)

        burn(attacker, target)
        return true
    end,

    RecoilX = 0.8,
    RecoilY = 1.2,
}

local elapsedTime = 0
RunService.Heartbeat:Connect(function(dt)
    elapsedTime += dt
    if elapsedTime < 0.05 then
        return
    end

    elapsedTime = 0
    burnHeartbeat()
end)

return item