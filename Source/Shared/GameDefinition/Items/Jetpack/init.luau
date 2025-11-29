local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local Types = require(ReplicatedStorage.API.Types)

local Jetpack = {}

local VELOCITY = 20

local visualsRemote = GetRemote("JetpackVisuals", script)

local function OnEquipClient(): ()
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
		visualsRemote:FireServer(velocity.Enabled)
	end)
end

local function OnUnequipClient(): ()
	local CustomActions = require(ReplicatedStorage.API.CustomActions)
	CustomActions.Unregister("Jetpack")
end

local function OnEquipServer(_, participant: Types.Participant): ()
	local humanoid = participant:GetHumanoid()
	if not humanoid then
		return
	end

	humanoid:AddAccessory(script.JetpackModel:Clone())
end

local function OnUnequipServer(_, participant: Types.Participant): ()
	local humanoid = participant:GetHumanoid()
	if not humanoid then
		return
	end

	for _, accessory in humanoid:GetAccessories() do
		if accessory.Name == "JetpackModel" then
			accessory:Destroy()
		end
	end
end

if RunService:IsServer() then
	visualsRemote.OnServerEvent:Connect(function(player, enabled: unknown): ()
		if typeof(enabled) ~= "boolean" then
			return
		end

		local character = player.Character
		if not character then
			return
		end

		local jetpackModel = character:FindFirstChild("JetpackModel")
		if not jetpackModel then
			return
		end

		local particles = jetpackModel:QueryDescendants("ParticleEmitter")
		for _, particle in particles do
			assert(particle:IsA("ParticleEmitter"))
			particle.Enabled = enabled
		end
	end)
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

	OnEquipServer = OnEquipServer,
	OnUnequipServer = OnUnequipServer,
}

Jetpack.Item = item

return Jetpack