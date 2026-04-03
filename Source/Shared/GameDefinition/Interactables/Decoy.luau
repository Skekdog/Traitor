local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DNATraces = require(ReplicatedStorage.API.DNATraces)
local BlockFriendlyDamage = require(ReplicatedStorage.API.Prop.BlockFriendlyDamage)
local ReplicateAssociatedPlayer = require(ReplicatedStorage.API.Prop.ReplicateAssociatedPlayer)
local Types = require(ReplicatedStorage.API.Types)

local module = {}

type Decoy = Types.Prop & {
	Interactable: Types.InteractableDefinition,
	Extras: {
		Player: Player?,
		Participant: Types.Participant?,
		[any]: nil,
	},
}

local activeDecoysClient: {Decoy} = {}

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

	ReplicateAssociatedPlayer(interactable)
end

local function OnInteractServer(interactable: Types.Prop, participant: Types.Participant): ()
	local decoy = interactable :: Decoy

	if participant ~= decoy.Extras.Participant then
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

local function OnLoadServer(prop: Types.Prop): ()
	ReplicateAssociatedPlayer(prop)

	local participant: Types.Participant = prop.Extras.Participant
	if not participant then
		return
	end

	DNATraces.Add(prop, participant, nil, Content.fromAssetId(96906503847712), prop.Model)
end

local interactable: Types.InteractableDefinition = {
	Name = "Decoy",

	Model = ReplicatedStorage.Assets.InteractableModels.Decoy,

	IsContinuousInteraction = false,
	InteractionRange = 7.5,

	OnLoadClient = OnLoadClient,
	OnInteractServer = OnInteractServer,

	BeforeTakeDamage = BlockFriendlyDamage,

	OnLoadServer = OnLoadServer,
}

function module.GetPlayerPosition(player: Player): (CFrame?, boolean)
	for _, decoy in activeDecoysClient do
		if decoy.Extras.Player :: Player? == player then
			return decoy.Model:GetPivot(), true
		end
	end

	local char = player.Character
	if not char then
		return nil, false
	end

	local root = char.PrimaryPart
	local humanoid = char:FindFirstAncestorOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return nil, false
	end

	return root.CFrame, false
end

module.Interactable = interactable

return table.freeze(module)