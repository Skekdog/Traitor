local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.Shared.GameDefinition.Items.Common.ItemGroups)
local Types = require(ReplicatedStorage.API.Types)

local FreezeGrenade = {}

local FREEZE_TIME = 5

local function OnHitClient(item: Types.AnyItemDefinition): ()
	local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
	local JumpPower = require(ReplicatedStorage.Shared.Character.JumpPower)

	local root = LocalCharacter.RootPart()
	if not root then
		return
	end

	JumpPower.SetModifier("FreezeGrenade", false)

	local attachment = Instance.new("Attachment")
	attachment.Name = "FreezeGrenadeAttachment"
	attachment.Parent = root

	local alignPosition = Instance.new("AlignPosition")
	alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignPosition.RigidityEnabled = true
	alignPosition.Attachment0 = attachment
	alignPosition.Position = root.Position
	alignPosition.Name = "FreezeGrenade"
	alignPosition.Parent = root

	task.delay(FREEZE_TIME, function()
		attachment:Destroy()
		alignPosition:Destroy()
	end)
end

local item: Types.GrenadeWeaponDefinition = {
	Kind = "Grenade" :: "Grenade",

	Name = "FreezeGrenade",
	DisplayName = "Freeze Grenade",
	Description = "Stops players from moving within the blast radius. Explodes on impact.",
	Icon = "rbxassetid://102415235814315",

	HoldAnimation = "rbxassetid://12498620263",
	Model = ReplicatedStorage.Assets.WeaponModels.FreezeGrenade,

	ItemGroup = ItemGroups.Grenade,
	CreditCost = 2,
	MaxStock = 1,

	FuseTime = -1,
	Projectile = ReplicatedStorage.Assets.WeaponModels.FreezeGrenade :: BasePart,
	ProjectileForce = 100,

	OnHitClient = OnHitClient,

	ExplosionInfo = {
		Damage = 0,
		FalloffBegin = 0,
		FalloffEnd = 15,
		Pressure = 10000,
		VisualRadius = 15,
	},
}

FreezeGrenade.Item = item

return FreezeGrenade