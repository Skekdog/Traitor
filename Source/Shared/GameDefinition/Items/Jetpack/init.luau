local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local Types = require(ReplicatedStorage.API.Types)

local Jetpack = {}

local VELOCITY = 20
local MAX_FUEL = 8
local FUEL_THRESHOLD = 2
local FUEL_CONSUMPTION_RATE = 2
local FUEL_RECHARGE_RATE = 0.5

local fuel = MAX_FUEL

local visualsRemote = GetRemote("JetpackVisuals", script)

local function toggleJetpack(velocity: LinearVelocity): ()
	velocity.Enabled = not velocity.Enabled
	visualsRemote:FireServer(velocity.Enabled)
end

local function getUi()
	local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
	local ui: typeof(UIManager.RegisterUI(script.JetpackFuel)) = UIManager.TryGetUI("JetpackFuel") :: typeof(UIManager.RegisterUI(script.JetpackFuel))? or UIManager.RegisterUI(script.JetpackFuel)
	return ui
end

local velocity: LinearVelocity?
if RunService:IsClient() then
	RunService.Heartbeat:Connect(function(dt)
		if not velocity then
			return
		end

		if velocity.Enabled then
			fuel = math.max(0, fuel - FUEL_CONSUMPTION_RATE * dt)
			if fuel <= 0 then
				toggleJetpack(velocity)
			end
		else
			fuel = math.min(MAX_FUEL, fuel + FUEL_RECHARGE_RATE * dt)
		end

		getUi().Object.Background.Size = UDim2.fromScale(fuel / MAX_FUEL, 1)
	end)
end

local function OnEquipClient(): ()
	local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
	local CustomActions = require(ReplicatedStorage.API.CustomActions)

	local root = LocalCharacter.RootPart()
	if not root then
		return
	end

	velocity = Instance.new("LinearVelocity")
	assert(velocity)

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
		if not velocity or not velocity.Enabled and fuel < FUEL_THRESHOLD then
			return
		end
		toggleJetpack(velocity)
	end)

	getUi():ToggleVisible(true)
end

local function OnUnequipClient(): ()
	local CustomActions = require(ReplicatedStorage.API.CustomActions)
	CustomActions.Unregister("Jetpack")

	if velocity then
		velocity:Destroy()
		velocity = nil
	end

	getUi():ToggleVisible(false)
	fuel = MAX_FUEL
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