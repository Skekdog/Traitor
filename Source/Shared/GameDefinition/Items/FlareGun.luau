local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ItemKillHighlights = require(ReplicatedStorage.Shared.GameDefinition.Items.Common.ItemKillHighlights)
local ForEachPart = require(ReplicatedStorage.Shared.RoundRule.Common.ForEachPart)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)
local Ammo = require(script.Parent.Ammo)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local function models(name: string): BasePart
    return ReplicatedStorage.Assets:WaitForChild("WeaponModels"):WaitForChild(name) :: BasePart
end

local function firedSounds(name: string): Sound
    return (ReplicatedStorage.Assets:WaitForChild("WeaponSounds"):WaitForChild("Fired"):WaitForChild(name) :: Sound)
end

local function projectiles(name: string): BasePart
    return ReplicatedStorage.Assets:WaitForChild("Projectiles"):WaitForChild(name) :: BasePart
end

local function weaponSounds(name: string): Sound
    return (ReplicatedStorage.Assets:WaitForChild("WeaponSounds"):WaitForChild(name) :: Sound)
end

local highlight1 = {
    Title = "To The Rescue",
    Description = "%s used their flares to signal for %d deaths.",
    Priority = 2,
    Threshold = 2,
}

local highlight2 = {
    Title = "Flare Indicates Fire",
    Description = "%s taught %d people about the danger of wearing flammable clothing.",
    Priority = 4,
    Threshold = 4,
}

type BurnTarget = Types.Participant | Types.Prop | Types.Interactable
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
    else
        part = GetPrimaryPart(target.Model)
    end

    local fire = Instance.new("Fire")
    fire.Size = 10
    fire.Parent = part

    if target.Kind == "Prop" and target.Model:HasTag("Corpse") then
        target.Model:SetAttribute("Burning", true)
        if not attacker:IsBadGuy() then
            attacker:SetFreeKill("burned a corpse")
        end
    else
        part:SetAttribute("Burning", true)
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

        if target.Model:HasTag("Corpse") then
            target.Model:Destroy()
        end
    end
end

local function burnTouchingParticipants(prop: Types.Prop): ()
    local burnedParticipants: {Types.Participant} = {}
    ForEachPart(prop.Model, function(propPart)
        for _, v in workspace:GetPartsInPart(propPart) do
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
    end)
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

    PlaySound(weaponSounds("FlareBurn"), nil, if model:IsA("Model") then model.PrimaryPart else model)

    if target.Kind == "Participant" or target.Kind == "Prop" then
        local health = (target :: Types.Prop):GetHealth()
        if health and health <= 0 then
            return stopBurning(target)
        end

        if target.Kind == "Prop" then
            burnTouchingParticipants(target)
        end

        if health then
            local params = {
                Amount = 1,
                Source = "Burn" :: "Burn",
                Attacker = info.Attacker,
            }
            if target.Kind == "Participant" then
                ItemKillHighlights(highlight1, highlight2)({Definition = {Name = "Flare Gun"}} :: Types.GunWeapon, target.Round, target, params)
            end
            (target :: Types.Prop):TryTakeDamage(params)
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

    BeforeHitParticipant = function(item, round, target: Types.Participant, params: Types.DamageParams): boolean
        ItemKillHighlights(highlight1, highlight2)(item, round, target, params)
        local attacker = params.Attacker
        assert(attacker)
        burn(attacker, target)
        return true
    end,

    BeforeHitProp = function(_, _, target: Types.Prop | Types.Interactable, params: Types.DamageParams): boolean
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