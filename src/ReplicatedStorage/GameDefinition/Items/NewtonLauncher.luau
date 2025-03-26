local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Ammo = require(script.Parent.Ammo)
local MagnetoStick = require(script.Parent.MagnetoStick)
local Types = require(ReplicatedStorage.RoundRule.Types)

local flingRemote: RemoteEvent
if RunService:IsServer() then
	flingRemote = Instance.new("RemoteEvent")
	flingRemote.Name = "Fling"
	flingRemote.Parent = script
else
	local found = script:WaitForChild("Fling")
	assert(found:IsA("RemoteEvent"), "Fling must be a RemoteEvent")
	flingRemote = found
end

local function fling(part: BasePart, force: Vector3): ()
    part:ApplyImpulse(force)
end

if RunService:IsClient() then
    flingRemote.OnClientEvent:Connect(fling)
end

local beforeHit = function(weapon: Types.ItemBeforeHit, round: Types.Round, hit: Types.Participant | Types.Prop, params: Types.DamageParams): boolean
	assert(weapon.Kind == "Gun")

	local model = if hit.Kind == "Participant" then hit:GetCharacter() else hit.Model
	if not model then
		return true
	end

	local part = if model:IsA("BasePart") then model else model.PrimaryPart
	if not part then
		return true
	end

	local attacker = params.Attacker
	assert(attacker)

	local char = attacker:GetCharacter()
	if not char then
		return true
	end

    if hit.Kind == "MapProp" then
        MagnetoStick.SetLastHeldBy(hit, attacker.Player)
    end

    local lookVector = char:GetPivot().LookVector
    lookVector = Vector3.new(lookVector.X, 1, lookVector.Z)

    local force = lookVector * 1000 * part.AssemblyMass / 18

    if hit.Kind == "Participant" then
        force *= Vector3.new(2, 1, 2)
    end

    local owner = part:GetNetworkOwner()
    if owner then
        flingRemote:FireClient(owner, part, force)
    else
        fling(part, force)
    end

	return true
end

local item: Types.GunWeaponDefinition = {
	Kind = "Gun" :: "Gun",
    Name = "Newton Launcher",
    Description = "Flings anything it hits. Low inherent damage, but can be used to crush others with props or throw them off high ledges.",
    Icon = "rbxassetid://1491877109",

	Slot = 8,
    MaxStock = 2,
    CreditCost = 1,
    CanDrop = true,

    Damage = {
        Head = 8,
        Body = 4,
        Limb = 1,
    },

    Spread = 0,

    AttackInterval = 2,
    ReloadTime = 0,
    AmmoType = Ammo["Newton"],

    Model = ReplicatedStorage.WeaponModels["Newton Launcher"],
    HoldAnimation = "rbxassetid://10247380824",
    AttackSound = "rbxassetid://8561500387",
    ReloadSound = "",

    Projectile = ReplicatedStorage.Projectiles["Newton"],
    ProjectileSpeed = 300,

    RecoilX = 0,
    RecoilY = 0,

	BeforeHitParticipant = beforeHit,
	BeforeHitProp = beforeHit,
}

return item