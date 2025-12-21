local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)
local ItemGroups = require(ReplicatedStorage.Shared.GameDefinition.Items.Common.ItemGroups)

local Cheeze = {}

local EAT_DURATION = 1
local HEAL_AMOUNT = 90

local function PrimaryFireServer(item: Types.Item, _, _, _, participant: Types.Participant): ()
	if item.Extras.IsEating or item.Extras.IsThrowing then
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

		participant:RemoveItem(item)
	end)
end

local function PrimaryFireClient(item: Types.Item): ()
	local ViewmodelModule = require(ReplicatedStorage.Shared.Combat.ViewmodelModule)

	if item.Extras.IsEating or item.Extras.IsThrowing then
		return
	end

	item.PreventUnequip = true
	item.Extras.IsEating = true

	ViewmodelModule.PlayAnimation("rbxassetid://82123370330518")
end

local function AlternateFireClient(item: Types.Item): ()
	local ViewmodelModule = require(ReplicatedStorage.Shared.Combat.ViewmodelModule)
	local ClientInventory = require(ReplicatedStorage.Shared.LocalState.ClientInventory)

	if item.Extras.IsEating or item.Extras.IsThrowing then
		return
	end

	item.PreventUnequip = true
	item.Extras.IsThrowing = true

	local track = ViewmodelModule.PlayAnimation("rbxassetid://115786020255555")

	local function onFinish(): ()
		ClientInventory.RemoveItem(item)
	end

	if track then
		track:GetMarkerReachedSignal("RemoveCheeze"):Once(onFinish)
	else
		onFinish()
	end
end

local function AlternateFireServer(item: Types.Item, _, _, _, participant: Types.Participant): ()
	if item.Extras.IsEating or item.Extras.IsThrowing then
		return
	end

	item.PreventUnequip = true
	item.Extras.IsThrowing = true

	local track = participant:TryPlayAnimation(115786020255555, "ThrowCheeze")

	local function onFinish(): ()
		assert(item.Model)

		participant:TryThrowAssembly(item.Model:Clone(), 10, participant.Round:GetMap().Structure.Dynamic)
		participant:RemoveItem(item)
	end

	if track then
		track:GetMarkerReachedSignal("RemoveCheeze"):Once(onFinish)
	else
		onFinish()
	end
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
	AlternateFireClient = AlternateFireClient,
}

Cheeze.Item = definition

return Cheeze