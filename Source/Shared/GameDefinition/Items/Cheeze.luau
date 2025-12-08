local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local Types = require(ReplicatedStorage.API.Types)
local ItemGroups = require(ReplicatedStorage.Shared.GameDefinition.Items.Common.ItemGroups)

local Cheeze = {}

local EAT_DURATION = 3
local HEAL_AMOUNT = 90
local COOLDOWN = 30

local remote = GetRemote("Cheeze", script)

local clientItem: Types.Item?

local function PrimaryFireServer(item: Types.Item, _, _, _, participant: Types.Participant): ()
	if item.Extras.IsEating or (item.Extras.CooldownUntil or 0) > workspace:GetServerTimeNow() then
		return
	end

	item.PreventUnequip = true
	item.Extras.IsEating = true

	participant:TryPlayAnimation(82123370330518, "EatCheeze")

	task.delay(EAT_DURATION, function()
		if not participant:IsAlive() then
			return
		end

		participant:SetHealth(participant:GetHealth() + HEAL_AMOUNT)

		local cooldownUntil = workspace:GetServerTimeNow() + COOLDOWN
		item.Extras.CooldownUntil = cooldownUntil
		item.Extras.IsEating = false

		remote:FireClient(participant.Player, cooldownUntil)
	end)
end

local function PrimaryFireClient(item: Types.Item): ()
	local ViewmodelModule = require(ReplicatedStorage.Shared.Combat.ViewmodelModule)

	if item.Extras.IsEating or (item.Extras.CooldownUntil or 0) > workspace:GetServerTimeNow() then
		return
	end

	item.PreventUnequip = true
	item.Extras.IsEating = true

	ViewmodelModule.PlayAnimation("rbxassetid://82123370330518")
end

local function AlternateFireServer(item: Types.Item, _, _, _, participant: Types.Participant): ()
	participant:TryPlayAnimation(115786020255555, "ThrowCheeze")
end

local function OnEquipClient(item: Types.AnyItem): ()
	clientItem = item :: Types.Item
end

if RunService:IsClient() then
	remote.OnClientEvent:Connect(function(cooldownUntil: number?)
		if not clientItem then
			return
		end

		clientItem.Extras.IsEating = false
		clientItem.Extras.CooldownUntil = cooldownUntil
	end)
end

local definition: Types.ItemDefinition = {
	Kind = "Item" :: "Item",

	Name = "Cheeze",
	Description = "Can be consumed to instantly heal, or thrown on the ground to allow others to heal.",
	Icon = "",

	Model = ReplicatedStorage.Assets.WeaponModels.Cheeze,
	HoldAnimation = "rbxassetid://85447019535859",

	CreditCost = 2,
	MaxStock = 1,

	ItemGroup = ItemGroups.RoleUtility,

	PrimaryFireServer = PrimaryFireServer,
	PrimaryFireClient = PrimaryFireClient,
	AlternateFireServer = AlternateFireServer,
	OnEquipClient = OnEquipClient,
}

Cheeze.Item = definition

return Cheeze