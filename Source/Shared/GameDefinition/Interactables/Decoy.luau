local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local module = {}

type Decoy = Types.Interactable & {
	Extras: {
		Player: Player?,
		[any]: nil,
	},
}

local activeDecoysClient: {Decoy} = {}
module.ActiveDecoysClient = activeDecoysClient

local function getPlayerFromAttribute(interactable: Decoy): Player?
	local name = interactable.Model:GetAttribute("Player") :: string?
	if not name then
		return nil
	end
	local player = Players:FindFirstChild(name)
	assert(not player or player:IsA("Player"), "Player is not a Player")
	return player
end

local function setAssociatedPlayerClient(interactable: Decoy, player: Player?): ()
	interactable.Extras.Player = player
end

local function OnLoadClient(interactable: Decoy): ()
	local object = interactable.Model
	if not object:IsDescendantOf(workspace) then
		return
	end

	table.insert(activeDecoysClient, interactable)

	object.Destroying:Connect(function()
		table.remove(activeDecoysClient, table.find(activeDecoysClient, interactable) or error("Could not find"))
	end)

	local player = getPlayerFromAttribute(interactable)
	if not player then
		object:GetAttributeChangedSignal("Player"):Connect(function()
			setAssociatedPlayerClient(interactable, getPlayerFromAttribute(interactable))
		end)
		return
	end

	setAssociatedPlayerClient(interactable, player)
end

local function OnInteractServer(interactable: Decoy, participant: Types.Participant): ()
	local player = getPlayerFromAttribute(interactable)
	if participant.Player ~= player then
		return
	end

	local decoyItem = participant.Round:GetItemDefinition(interactable.Definition.Name)
	if not decoyItem then
		return warn("Could not find Decoy item")
	end

	if participant:IsItemGroupOccupied(decoyItem.ItemGroup) then
		return
	end

	interactable.Model:Destroy()
	participant:GiveItemFromItemDefinition(decoyItem)
end

local function BeforeTakeDamage(interactable: Decoy, params: Types.DamageParams?): boolean
	if not params then
		return false
	end

	local attacker = params.Attacker
	if not attacker then
		return false
	end

	return not attacker:GetRole().Definition.IsEvil
end

local interactable: Types.InteractableDefinition = {
	Name = "Decoy",

	Model = ReplicatedStorage.Assets.InteractableModels.Decoy,

	IsContinuousInteraction = false,
	InteractionRange = 7.5,

	OnLoadClient = OnLoadClient,
	OnInteractServer = OnInteractServer,

	BeforeTakeDamage = BeforeTakeDamage,
}

module.Interactable = interactable

return module