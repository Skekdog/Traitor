local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Types = require(ReplicatedStorage.API.Types)

local function throw(item: Types.Item): boolean
	local Client = require(ReplicatedStorage.API.Item.Behaviour.Client)

	if not Client.RunAllChecks(item, "Primary") then
		return false
	end

	item.PrimaryDisabled = true

	Client.DeductAmmo(item)
	Client.MuzzleFlash(item)
	Client.Recoil(item)
	Client.PlayAnimation(item, "Primary")
	Client.ApplyInterval(item, "Primary")

	local cookBegan = item.Extras.CookBegan or os.clock()
	local cookStopped = os.clock()

	item:SetServerData("Primary", cookStopped - cookBegan)

	return true
end

local function PrimaryActivatedClient(item: Types.Item): ()
	local Client = require(ReplicatedStorage.API.Item.Behaviour.Client)

	if not Client.RunAllChecks(item, "Primary") then
		return
	end

	item.UnequipDisabled = true
	item.DropDisabled = true

	item.Extras.CookBegan = os.clock()

	Client.PlaySound(item, "Primary")
end

local function PrimaryDeactivatedClient(item: Types.Item): ()
	local Client = require(ReplicatedStorage.API.Item.Behaviour.Client)
	local Raycasts = require(ReplicatedStorage.API.Item.Behaviour.Raycasts)

	if not throw(item) then
		return
	end

	Client.ServerFire("Primary", item, Raycasts.GetOrigin(), Raycasts.GetDirection())
end

local function PrimaryFireClient(item: Types.Item): boolean
	if (os.clock() - (item.Extras.CookBegan or math.huge)) >= item.FuseTime then
		return throw(item)
	end

	return false
end

local function PrimaryFireServer(item: Types.Item, origin: Vector3, direction: Vector3, participant: Types.Participant, data: unknown): string?
	local Server = require(ReplicatedStorage.API.Item.Behaviour.Server)
	local Checks = require(ReplicatedStorage.API.Item.Behaviour.Checks)

	if typeof(data) ~= "number" or not math.isfinite(data) then
		return "InvalidRequest"
	end

	if not Checks.Ammo(item) then
		return "NoAmmo"
	end

	Server.DeductAmmo(item)

	local cookedTime = math.clamp(data, 0, item.FuseTime or 0)
	Server.SimulateProjectile(item, participant, origin, direction, cookedTime)

	return nil
end

local function Grenade(components: Types.ItemComponents): Types.ItemComponents
	local base: Types.ItemComponents = {
		Name = "",
		Description = "",
		IconContent = Content.none,

		IsProjectileSimulated = true,
		PregameDisable = true,
		IsSingleUse = true,

		DamageKind = "Explode",

		ExplosionInfo = {
			Damage = 0,
			FalloffStart = 0,
			FalloffEnd = 1,
			Pressure = 1,
			VisualRadius = 10,
		},

		PrimaryFireClient = PrimaryFireClient,

		PrimaryActivatedClient = PrimaryActivatedClient,
		PrimaryDeactivatedClient = PrimaryDeactivatedClient,

		PrimaryFireServer = PrimaryFireServer,

		ProjectileSpeed = 35,

		OnHitRejectServer =
			if RunService:IsServer() then
				require(ReplicatedStorage.API.Item.Behaviour.Server).ProcessReject
			else
				nil
			,
	}

	for i, v in components do
		base[i] = v
	end

	return base
end

return Grenade