local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local Crowbar = require(script.Parent.Crowbar)
local Types = require(ReplicatedStorage.API.Types)
local PlaySound = require(ReplicatedStorage.API.PlaySound)

local Spoon = {}

local EAT_DURATION = 3
local EAT_COOLDOWN = 30
local HEAL = 45

local clientItem: Types.MeleeWeapon?

local remote = GetRemote("Eat", script)

local function OnEquipClient(item: Types.AnyItem): ()
	local CustomActions = require(ReplicatedStorage.API.CustomActions)
	local WalkSpeed = require(ReplicatedStorage.Shared.Character.WalkSpeed)
	local JumpPower = require(ReplicatedStorage.Shared.Character.JumpPower)

	assert(item.Kind == "Melee")
	clientItem = item

	local player = Players.LocalPlayer

	CustomActions.Register("SpoonEat", function()
		if workspace:GetServerTimeNow() < (item.Extras.CooldownUntil or 0) then
			return
		end

		remote:FireServer()
		WalkSpeed.SetModifier("EatSpoon", -math.huge)
		JumpPower.SetModifier("EatSpoon", false)

		player.CameraMinZoomDistance = 10
		player.CameraMaxZoomDistance = 10
		player.CameraMode = Enum.CameraMode.Classic
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

local itemDefinition: Types.MeleeWeaponDefinition = {
	Kind = "Melee" :: "Melee",

	Name = "SpoonItem",
	DisplayName = "Spoon",

	IsEvilItem = true,

	Model = ReplicatedStorage.Assets.WeaponModels.SpoonItem,
    HoldAnimation = "rbxassetid://98475112106018",
    AttackAnimation = "rbxassetid://124263943524491",

	AttackSound = attackSound,

	Damage = 30,
	AttackInterval = 0.75,
	DamageKind = "Bludgeon" :: "Bludgeon",
	MaxDistance = 10,

	ImpulseForce = 75,

	ItemGroup = {
		PreferredSlot = 1,
	},

	AlternateFireServer = Crowbar.Push,

	OnEquipClient = OnEquipClient,
	OnUnequipClient = OnUnequipClient,
}

if RunService:IsServer() then
	remote.OnServerEvent:Connect(function(player): ()
		local GetParticipant = require(ReplicatedStorage.API.GetParticipant)

		local participant = GetParticipant(player)
		if not participant or not participant:IsAlive() then
			return
		end

		if participant.Extras.IsEatingWithSpoon or (participant.Extras.SpoonNextHealAllowedAt or 0) > workspace:GetServerTimeNow() then
			return
		end

		local foundItem = participant:GetEquippedItem()
		if not foundItem or foundItem.Definition ~= itemDefinition then
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

		participant.Extras.IsEatingWithSpoon = true
		participant:TryPlayAnimation(139173308057702, "SpoonEat")

		local cooldownRequired = participant:GetHealth() < humanoid.MaxHealth

		task.spawn(function()
			for i = 1, EAT_DURATION do
				if not participant:IsAlive() or not participant.Extras.IsEatingWithSpoon then
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
				participant.Extras.IsEatingWithSpoon = false

				local cooldownUntil: number?
				if cooldownRequired then
					cooldownUntil = workspace:GetServerTimeNow() + EAT_COOLDOWN
					participant.Extras.SpoonNextHealAllowedAt = cooldownUntil
				end

				bowl:Destroy()

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

		if LocalParticipantInfo.GetParticipant().Status() ~= "Alive" then
			return
		end

		WalkSpeed.SetModifier("EatSpoon", 0)
		JumpPower.SetModifier("EatSpoon", true)

		local player = Players.LocalPlayer

		player.CameraMinZoomDistance = 128
		player.CameraMaxZoomDistance = 0.5
		player.CameraMode = Enum.CameraMode.LockFirstPerson

		if clientItem then
			clientItem.Extras.CooldownUntil = cooldownUntil
		end
	end)
end

local shopItem: Types.ItemDefinition = {
	Kind = "Item" :: "Item",

	Name = "Spoon",
	Description = "Spoon beats crowbar. Also you can eat food to heal.",
	Icon = "",

	CreditCost = 2,
	MaxStock = 2,

	OnEquipServer = function(_, participant: Types.Participant): ()
		local occupyingItem = participant:GetItemOccupyingGroup({PreferredSlot = 1})
		if occupyingItem then
			participant:TryDropItem(occupyingItem)
		end

		participant:GiveItemFromItemDefinition(itemDefinition)
	end,
}

Spoon.ShopItem = shopItem
Spoon.Item = itemDefinition

return Spoon