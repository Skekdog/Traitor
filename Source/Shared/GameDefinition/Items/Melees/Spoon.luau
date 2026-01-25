local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Crowbar = require(script.Parent.Crowbar)
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local Types = require(ReplicatedStorage.API.Types)
local PlaySound = require(ReplicatedStorage.API.PlaySound)
local Melee = require(ReplicatedStorage.API.Item.Presets.Melee)
local Custom = require(ReplicatedStorage.API.Item.Presets.Custom)
local Item = require(ReplicatedStorage.Shared.RoundRule.Item)

local Spoon = {}

local EAT_DURATION = 3
local EAT_COOLDOWN = 30
local HEAL = 45

local clientItem: Types.Item?

local remote = GetRemote("Eat", script)

local function OnEquipClient(item: Types.Item): ()
	local CustomActions = require(ReplicatedStorage.API.CustomActions)
	local WalkSpeed = require(ReplicatedStorage.Shared.Character.WalkSpeed)
	local JumpPower = require(ReplicatedStorage.Shared.Character.JumpPower)
	local Camera = require(ReplicatedStorage.API.Camera)

	clientItem = item

	CustomActions.Register("SpoonEat", function()
		if workspace:GetServerTimeNow() < (item.Extras.CooldownUntil or 0) then
			return
		end

		item.UnequipDisabled = true
		item.PrimaryDisabled = true
		item.AlternateDisabled = true

		remote:FireServer()
		WalkSpeed.SetModifier("EatSpoon", -math.huge)
		JumpPower.SetModifier("EatSpoon", false)

		Camera.EnterAnimationView()
	end, 3, "Feast")

	WalkSpeed.SetModifier("HoldingSpoon", 3)
end

local function OnUnequipClient(): ()
	local CustomActions = require(ReplicatedStorage.API.CustomActions)
	local WalkSpeed = require(ReplicatedStorage.Shared.Character.WalkSpeed)

	CustomActions.Unregister("SpoonEat")
	WalkSpeed.SetModifier("HoldingSpoon", 0)
end

local attackSound = PlaySound.MakeSound(329792582, {
	RollOffMaxDistance = 40,
	RollOffMinDistance = 10,
})

local itemDefinition = Melee({
	Name = "SpoonItem",
	DisplayName = "Spoon",
	Description = "",
	IconContent = Content.none,

	IsEvilItem = true,

	Model = ReplicatedStorage.Assets.ItemModels.SpoonItem,
    HoldAnimation = Content.fromAssetId(98475112106018),
    PrimaryAnimation = Content.fromAssetId(124263943524491),

	PrimarySound = attackSound,

	Damage = 45,
	PrimaryInterval = 0.75,
	DamageKind = "Bludgeon" :: "Bludgeon",
	MaxDistance = 10,

	ImpulseForce = 75,

	ItemGroup = {
		PreferredSlot = 1,
	},

	OnEquipClient = OnEquipClient,
	OnUnequipClient = OnUnequipClient,

	AlternateFireServer = Crowbar.AlternateFireServer,
	AlternateFireClient = Crowbar.AlternateFireClient,
})

if RunService:IsServer() then
	remote.OnServerEvent:Connect(function(player): ()
		local GetParticipant = require(ReplicatedStorage.API.GetParticipant)

		local participant = GetParticipant(player)
		if not participant or not participant:IsAlive() then
			return
		end

		local foundItem = participant:GetEquippedItem()
		if not foundItem or foundItem.Base ~= itemDefinition then
			return
		end

		if foundItem.Extras.IsEating or (foundItem.Extras.NextHealAllowedAt or 0) > workspace:GetServerTimeNow() then
			return
		end

		local humanoid = participant:GetHumanoid()
		if not humanoid then
			return
		end

		local char = participant:GetCharacter()
		if not char then
			return
		end

		local root = char.PrimaryPart
		if not root then
			return
		end

		local bowl = ReplicatedStorage.Assets.ItemAssets.SpoonBowl:Clone()

		local motor = Instance.new("Motor6D")
		motor.Part0 = root
		motor.Part1 = bowl
		motor.Parent = bowl

		bowl.Name = "Bowl"
		bowl.Parent = char :: any

		foundItem.Extras.IsEating = true
		participant:TryPlayAnimation(Content.fromAssetId(139173308057702), "SpoonEat");

		foundItem.UnequipDisabled = true
		foundItem.AlternateDisabled = true
		foundItem.PrimaryDisabled = true

		local cooldownRequired = participant:GetHealth() < humanoid.MaxHealth

		task.spawn(function()
			for i = 1, EAT_DURATION do
				if not participant:IsAlive() or not foundItem.Extras.IsEating then
					return
				end

				PlaySound(3043029786, nil, root, {
					RollOffMaxDistance = 20,
					RollOffMinDistance = 5,
				})

				participant:SetHealth(participant:GetHealth() + HEAL / EAT_DURATION)

				task.wait(1)
			end
		end)

		task.delay(EAT_DURATION, function()
			if participant:IsAlive() then
				foundItem.Extras.IsEating = false

				local cooldownUntil: number?
				if cooldownRequired then
					cooldownUntil = workspace:GetServerTimeNow() + EAT_COOLDOWN
					foundItem.Extras.NextHealAllowedAt = cooldownUntil
				end

				bowl:Destroy();

				foundItem.UnequipDisabled = false
				foundItem.AlternateDisabled = false
				foundItem.PrimaryDisabled = false

				participant:TryStopAnimation("SpoonEat")
				participant:SetHealth(participant:GetHealth() + HEAL)
				remote:FireClient(player, cooldownUntil)
			end
		end)
	end)
else
	remote.OnClientEvent:Connect(function(cooldownUntil: number?)
		local WalkSpeed = require(ReplicatedStorage.Shared.Character.WalkSpeed)
		local JumpPower = require(ReplicatedStorage.Shared.Character.JumpPower)
		local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)
		local Camera = require(ReplicatedStorage.API.Camera)

		if LocalParticipantInfo.GetParticipant().Status() ~= "Alive" then
			return
		end

		WalkSpeed.SetModifier("EatSpoon", 0)
		JumpPower.SetModifier("EatSpoon", true)

		Camera.EnterFirstPerson()

		if clientItem then
			clientItem.UnequipDisabled = false
			clientItem.AlternateDisabled = false
			clientItem.PrimaryDisabled = false
			clientItem.Extras.CooldownUntil = cooldownUntil
		end
	end)
end

local shopItem = Custom({
	Name = "Spoon",
	Description = "Flings people at high speeds, and can be used to eat a healing bowl of soup.",
	IconContent = Content.fromAssetId(10974184304),

	Cost = 2,
	MaxStock = 1,

	OnEquipServer = function(_, participant: Types.Participant): ()
		local occupyingItem = participant:GetItemOccupyingGroup({PreferredSlot = 1})
		if occupyingItem then
			participant:TryDropItem(occupyingItem)
		end

		participant:AddItem(Item.new(itemDefinition))
	end,
})

Spoon.ShopItem = shopItem
Spoon.Item = itemDefinition

return Spoon