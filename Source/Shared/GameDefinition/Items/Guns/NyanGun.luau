local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Audio = require(ReplicatedStorage.API.Audio)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Ammo = require(ReplicatedStorage.API.Item.Ammo)
local Gun = require(ReplicatedStorage.API.Item.Presets.Gun)

local NyanGun = {}

local equipLoop = Audio.MakeSound({
	Content = Content.fromAssetId(7834135677),
	Name = "NyanEquip",
	Volume = 0.1
})
equipLoop.Looped = true

local shootLoop = Audio.MakeSound({
	Content = Content.fromAssetId(78552787219713),
	Name = "NyanShoot",
	Volume = 0.1
})
shootLoop.Looped = true

if RunService:IsClient() then
	equipLoop.Parent = SoundService
	shootLoop.Parent = SoundService
end

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

return table.freeze(NyanGun)