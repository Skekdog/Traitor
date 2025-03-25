local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local PlaySound = require(ReplicatedStorage.RoundRule.Common.PlaySound)
local Ammo = require(script.Parent.Ammo)
local Types = require(ReplicatedStorage.RoundRule.Types)

local function models(name: string): BasePart
    return ReplicatedStorage:WaitForChild("WeaponModels"):WaitForChild(name) :: BasePart
end

local function firedSounds(name: string): string
    return (ReplicatedStorage:WaitForChild("WeaponSounds"):WaitForChild("Fired"):WaitForChild(name) :: Sound).SoundId
end

local function projectiles(name: string): BasePart
    return ReplicatedStorage:WaitForChild("Projectiles"):WaitForChild(name) :: BasePart
end

local function weaponSounds(name: string): string
    return (ReplicatedStorage:WaitForChild("WeaponSounds"):WaitForChild(name) :: Sound).SoundId
end

local burningProps: {Types.MapProp} = {}

local function burn(attacker: Types.Participant, target: Types.Participant | Types.Prop): ()
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
		table.insert(burningProps, target)
    elseif target.Kind == "CorpseProp" then
        target.Model:SetAttribute("Burning", true)
    end

    local endTime = workspace:GetServerTimeNow() + 10
    task.spawn(function()
        while true do
            if workspace:GetServerTimeNow() > endTime then
                break
            end

            task.wait(0.25)

            if target.Kind ~= "Participant" and target.Kind ~= "MapProp" then
                continue
            end

            local health: number? = if target then (target :: Types.Participant):GetHealth() else nil
            if health and health < 0 then
                break
            end
            if not part:IsDescendantOf(workspace) then
                break
            end

            burnSound:Play()

            if health then
                (target :: Types.Participant):TryTakeDamage({
                    Amount = 1,
                    Attacker = attacker,
                    Source = "Burn"
                })
            end
        end
        
        if target.Kind == "MapProp" then
            part:SetAttribute("Burning", false)
        end

        burnSound:Destroy()
        fire:Destroy()

        if target.Kind == "CorpseProp" then
            target.Model:Destroy()
        end
    end)
end

local item: Types.GunWeaponDefinition = {
	Kind = "Gun" :: "Gun",
    Name = "Flare Gun",
    Description = "Will set things it hits on fire. Can be used to burn corpses, preventing others from discovering them.",
    Icon = "rbxassetid://444145395",
    CreditCost = 1,
    MaxStock = 1,

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

local function doBurnDamage(): ()
    local toRemove: {Types.MapProp} = {}
    for _, prop in burningProps do
        if not prop.Model:GetAttribute("Burning") or not prop.Model:IsDescendantOf(workspace) then
            table.insert(toRemove, prop)
            continue
        end

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

            PlaySound(weaponSounds("FlareBurn"), nil, v, {SoundGroup = SoundService.AllSounds :: SoundGroup})
        end
    end

    for _, v in toRemove do
        table.remove(burningProps, table.find(burningProps, v))
    end
end

local elapsedTime = 0
RunService.Heartbeat:Connect(function(dt)
    elapsedTime += dt
    if elapsedTime < 0.1 then
        return
    end

    elapsedTime = 0
    doBurnDamage()
end)

return item