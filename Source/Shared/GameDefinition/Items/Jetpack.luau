local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)

local Jetpack = {}

local VELOCITY = 20

local function OnEquipClient()
	local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
	local CustomActions = require(ReplicatedStorage.API.CustomActions)

	local root = LocalCharacter.RootPart()
	if not root then
		return
	end

	local velocity = Instance.new("LinearVelocity")
	velocity.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	velocity.PlaneVelocity = Vector2.new(0, VELOCITY)
	velocity.ForceLimitsEnabled = true
	velocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	velocity.MaxPlanarAxesForce = Vector2.new(0, 10000)

	velocity.Enabled = false
	velocity.Name = "JetpackVelocity"

	local attachment = Instance.new("Attachment")
	attachment.Name = "JetpackAttachment"
	attachment.Parent = root

	velocity.Attachment0 = attachment
	velocity.Parent = root

	CustomActions.Register("Jetpack", function()
		velocity.Enabled = not velocity.Enabled
	end)
end

local function OnUnequipClient()
	local CustomActions = require(ReplicatedStorage.API.CustomActions)
	CustomActions.Unregister("Jetpack")
end

local item: Types.ItemDefinition = {
	Kind = "Item" :: "Item",

	Name = "Jetpack",
	Description = "Fly around, while fuel lasts.",

	Icon = "rbxassetid://17576355326",

	CreditCost = 1,
	MaxStock = 1,

	OnEquipClient = OnEquipClient,
	OnUnequipClient = OnUnequipClient,
}

Jetpack.Item = item

return Jetpack