local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local Types = require(ReplicatedStorage.API.Types)
local Custom = require(ReplicatedStorage.API.Item.Presets.Custom)

local Flypack = {}

local VELOCITY = 20
local WALKSPEED_BONUS = 2

local MAX_FUEL = 1000000
local FUEL_THRESHOLD = 1
local FUEL_CONSUMPTION_RATE = 5
local FUEL_RECHARGE_RATE = 0.75
local RECHARGE_COOLDOWN = 1

local jetpackFuelUi = ReplicatedStorage.Assets.ItemAssets.JetpackFuel

local fuel = MAX_FUEL

local visualsRemote = GetRemote("JetpackVisuals", script)

local lastUseTime = 0
local function toggleJetpack(velocity: LinearVelocity?, enable: boolean): ()
	local WalkSpeed = require(ReplicatedStorage.Shared.Character.WalkSpeed)

	if not velocity then
		return
	end

	if enable == velocity.Enabled or enable and fuel < FUEL_THRESHOLD then
		return
	end

	if not enable then
		lastUseTime = os.clock()
	end

	velocity.Enabled = enable
	WalkSpeed.SetModifier("UsingJetpack", if enable then WALKSPEED_BONUS else 0)

	visualsRemote:FireServer(enable)
end

local function getUi()
	local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
	local ui: typeof(UIManager.RegisterUI(jetpackFuelUi)) = UIManager.TryGetUI("JetpackFuel") :: typeof(UIManager.RegisterUI(jetpackFuelUi))? or UIManager.RegisterUI(jetpackFuelUi)
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
				toggleJetpack(velocity, false)
			end
		else
			if os.clock() - lastUseTime < RECHARGE_COOLDOWN then
				return
			end
			fuel = math.min(MAX_FUEL, fuel + FUEL_RECHARGE_RATE * dt)
		end

		getUi().Object.Background.Size = UDim2.fromScale(fuel / MAX_FUEL, 1)
	end)
end

local function tryConnectTouchGui(): ()
	local touchGui = Players.LocalPlayer.PlayerGui:FindFirstChild("TouchGui")
	if not touchGui then
		return
	end

	local touchControlFrame = touchGui:FindFirstChild("TouchControlFrame")
	if not touchControlFrame then
		return
	end

	local jumpButton = touchControlFrame:FindFirstChild("JumpButton")
	if not jumpButton then
		return
	end

	assert(jumpButton:IsA("GuiButton"), "What")

	jumpButton:GetPropertyChangedSignal("GuiState"):Connect(function()
		toggleJetpack(velocity, jumpButton.GuiState == Enum.GuiState.Press)
	end)
end

local function OnEquipClient(): ()
	local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
	local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)

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

	ControlManager.Register("Jetpack", function(_, state)
		if state == Enum.UserInputState.Begin then
			toggleJetpack(velocity, true)
		else
			toggleJetpack(velocity, false)
		end

		return Enum.ContextActionResult.Pass
	end, nil, {
		Keybind = {
			KBMKeybind = Enum.KeyCode.Space,
			Gamepad = Enum.KeyCode.ButtonA,
		},
		Toggled = false,
	})

	tryConnectTouchGui()

	getUi():ToggleVisible(true)
end

local function OnUnequipClient(): ()
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

	humanoid:AddAccessory(ReplicatedStorage.Assets.ItemModels.JetpackModel:Clone())
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

		local sound = jetpackModel:FindFirstChild("Thruster", true)
		if sound and sound:IsA("Sound") then
			if enabled then
				sound:Play()
			else
				sound:Stop()
			end
		end
	end)
end

local item = Custom({
	Name = "Flypack",
	Description = "Fly around, forever.",
	IconContent = Content.fromAssetId(17576355326),

	OnEquipClient = OnEquipClient,
	OnUnequipClient = OnUnequipClient,

	OnEquipServer = OnEquipServer,
	OnUnequipServer = OnUnequipServer,
})

Flypack.Item = item

return table.freeze(Flypack)