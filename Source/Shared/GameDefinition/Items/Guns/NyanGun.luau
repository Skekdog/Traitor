local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Ammo = require(ReplicatedStorage.API.ItemPresets.Ammo)
local Gun = require(ReplicatedStorage.API.ItemPresets.Gun)
local PlaySound = require(ReplicatedStorage.API.PlaySound)

local NyanGun = {}

local equipLoop = PlaySound.MakeSound(7834135677, {Looped = true, Volume = 0.1})
equipLoop.Name = "NyanEquip"
equipLoop.Parent = SoundService

local shootLoop = PlaySound.MakeSound(78552787219713, {Looped = true, Volume = 0.1})
shootLoop.Name = "NyanShoot"
shootLoop.Parent = SoundService

local function OnEquipClient(): ()
	equipLoop:Play()
end

local function OnUnequipClient(): ()
	equipLoop:Stop()
end

local function OnActivatedClient(): ()
	equipLoop:Stop()
	shootLoop:Play()
end

local function OnDeactivatedClient(): ()
	local ClientInventory = require(ReplicatedStorage.Shared.LocalState.ClientInventory)

	shootLoop:Stop()

	local equipped = ClientInventory.EquippedItem()
	if equipped and equipped.Name == "NyanGun" then
		equipLoop:Play()
	end
end

local item = Gun({
	Name = "NyanGun",
	DisplayName = "Nyan Gun",
	Description = "Fast-firing and unlimited ammo cat action!",
	IconContent = Content.fromAssetId(83079381),

	Cost = 1,
	MaxStock = 4,

	ItemGroup = ItemGroups.RoleWeapon,

	IsAimable = false,

	Spread = 0.05,

	Damage = {
		Head = 15,
		Body = 10,
		Limb = 5,
	},

	PrimaryInterval = 0.1,

	AmmoDefinition = Ammo.Infinite,

	Model = ReplicatedStorage.Assets.ItemModels.NyanGun,
	HoldAnimation = Content.fromAssetId(12481091962),

	Projectile = ReplicatedStorage.Assets.Projectiles.NyanBullet,
	ProjectileSpeed = 280,

	ImpulseForce = 3,

	OnEquipClient = OnEquipClient,
	OnUnequipClient = OnUnequipClient,

	PrimaryActivatedClient = OnActivatedClient,
	PrimaryDeactivatedClient = OnDeactivatedClient,
})

NyanGun.Item = item

return NyanGun