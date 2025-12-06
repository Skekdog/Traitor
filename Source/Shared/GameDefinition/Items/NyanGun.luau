local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local PlaySound = require(ReplicatedStorage.API.PlaySound)
local Ammo = require(script.Parent.Ammo)
local Types = require(ReplicatedStorage.API.Types)
local ItemGroups = require(ReplicatedStorage.Shared.GameDefinition.Items.Common.ItemGroups)

local NyanGun = {}

local equipLoop = PlaySound.MakeSound(7834135677, {Looped = true})
equipLoop.Name = "NyanEquip"
equipLoop.Parent = SoundService

local shootLoop = PlaySound.MakeSound(78552787219713, {Looped = true})
shootLoop.Name = "NyanShoot"
shootLoop.Parent = SoundService

local function OnEquipClient(): ()
	equipLoop:Play()
end

local function OnUnequipClient(): ()
	equipLoop:Stop()
end

local function OnActivateClient(): ()
	equipLoop:Stop()
	shootLoop:Play()
end

local function OnDeactivateClient(): ()
	local ClientInventory = require(ReplicatedStorage.Shared.LocalState.ClientInventory)

	shootLoop:Stop()

	local equipped = ClientInventory.EquippedItem()
	if equipped and equipped.Definition.Name == "NyanGun" then
		equipLoop:Play()
	end
end

local item: Types.GunWeaponDefinition = {
	Kind = "Gun" :: "Gun",

	Name = "NyanGun",
	DisplayName = "Nyan Gun",
	Description = "Because a cat gun is unethical.",

	CreditCost = 1,
	MaxStock = 4,

	ItemGroup = ItemGroups.RoleWeapon,
	CanDrop = true,

	Spread = 0.05,

	Damage = {
		Head = 15,
		Body = 10,
		Limb = 5,
	},

	AttackInterval = 0.1,

	AmmoType = Ammo.Infinite,
	ReloadTime = 0,

	Model = ReplicatedStorage.Assets.WeaponModels.NyanGun,
	HoldAnimation = "rbxassetid://12481091962",

	Projectile = ReplicatedStorage.Assets.Projectiles.NyanBullet,
	ProjectileSpeed = 280,

	ImpulseForce = 3,

	RecoilX = 0,
	RecoilY = 0,

	OnEquipClient = OnEquipClient,
	OnUnequipClient = OnUnequipClient,

	OnActivateClient = OnActivateClient,
	OnDeactivateClient = OnDeactivateClient,
}

NyanGun.Item = item

return NyanGun