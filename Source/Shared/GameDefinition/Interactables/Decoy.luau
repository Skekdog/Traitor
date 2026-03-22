local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local module = {}

type Decoy = Types.Prop & {
	Interactable: Types.InteractableDefinition,
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

local function OnLoadClient(interactable: Types.Prop): ()
	local decoy = interactable :: Decoy

	local object = decoy.Model
	if not object:IsDescendantOf(workspace) then
		return
	end

	table.insert(activeDecoysClient, decoy)

	object.Destroying:Connect(function()
		table.remove(activeDecoysClient, table.find(activeDecoysClient, decoy) or error("Could not find"))
	end)

	local player = getPlayerFromAttribute(decoy)
	if not player then
		object:GetAttributeChangedSignal("Player"):Connect(function()
			setAssociatedPlayerClient(decoy, getPlayerFromAttribute(decoy))
		end)
		return
	end

	setAssociatedPlayerClient(decoy, player)
end

local function OnInteractServer(interactable: Types.Prop, participant: Types.Participant): ()
	local decoy = interactable :: Decoy

	local player = getPlayerFromAttribute(decoy)
	if participant.Player ~= player then
		return
	end

	local decoyItem = participant.Round:GetItemDefinition(decoy.Interactable.Name)
	if not decoyItem then
		return warn("Could not find Decoy item")
	end

	if participant:GetItemOccupyingGroup(decoyItem.ItemGroup) then
		return
	end

	interactable.Model:Destroy()
	participant:AddItem(participant.Round:LoadItem(decoyItem))
end

local function BeforeTakeDamage(interactable: Types.Prop, params: Types.DamageParams?): boolean
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

return table.freeze(module)