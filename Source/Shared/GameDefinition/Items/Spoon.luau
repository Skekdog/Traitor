local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local Crowbar = require(script.Parent.Crowbar)
local Types = require(ReplicatedStorage.API.Types)
local PlaySound = require(ReplicatedStorage.API.PlaySound)

local Spoonbar = {}

local remote = GetRemote("Eat", script)

local function OnEquipClient(): ()
	local CustomActions = require(ReplicatedStorage.API.CustomActions)
	local WalkSpeed = require(ReplicatedStorage.Shared.Character.WalkSpeed)
	local JumpPower = require(ReplicatedStorage.Shared.Character.JumpPower)

	local player = Players.LocalPlayer

	CustomActions.Register("SpoonEat", function()
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

local item: Types.MeleeWeaponDefinition = {
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

		local foundItem = participant:GetEquippedItem()
		if not foundItem or foundItem.Definition ~= item then
			return
		end

		local humanoid = participant:GetHumanoid()
		if not humanoid then
			return
		end

		participant:TryPlayAnimation(139173308057702, "SpoonEat")
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

		participant:GiveItemFromItemDefinition(item)
	end,
}

Spoonbar.ShopItem = shopItem
Spoonbar.Item = item

return Spoonbar