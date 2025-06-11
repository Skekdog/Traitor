local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local module = {}

module.IsZoomedIn = false

local function doZoomClient(): ()
	local SetCameraSensitivity = require(ReplicatedStorage.Shared.Camera.SetCameraSensitivity)

	local Mouse = require(ReplicatedStorage.Shared.Interface.GameState.Mouse)
	local Interaction = (require)(ReplicatedStorage.Shared.Actions.Interaction) :: {
		CorpseInteractDistance: number
	}
	Interaction.CorpseInteractDistance = if module.IsZoomedIn then 200 else 10
	Mouse.CorpseInteractDistance = Interaction.CorpseInteractDistance

	local newFov = if module.IsZoomedIn then 30 else 70
	TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.1), {
		FieldOfView = newFov
	}):Play()
	SetCameraSensitivity(newFov / 70)
end

local function doZoomServer(participant: Types.Participant, isZoomed: boolean): ()
	participant.CorpseSearchDistance = if isZoomed then 200 else 10
end

local function AlternateFireClient(): ()
	module.IsZoomedIn = not module.IsZoomedIn
	doZoomClient()
end

local function OnUnequipClient(): ()
	module.IsZoomedIn = false
	doZoomClient()
end

local function OnUnequipServer(_, participant: Types.Participant): ()
	doZoomServer(participant, false)
end

local function OnEquipServer(_, participant: Types.Participant): ()
	doZoomServer(participant, true)
end

local item: Types.ItemDefinition = {
	Kind = "Item" :: "Item",

	Name = "Binoculars",
	Description = "Allows corpses to be searched from a distance.",
	Icon = "rbxassetid://7677183404",

	Slot = 8,
	CanDrop = true,

	Model = ReplicatedStorage.Assets.WeaponModels.Binoculars,

	CreditCost = 1,
	MaxStock = 2,

	AlternateToggled = true,
	AlternateHint = "Zoom In / Out",

	AlternateFireClient = AlternateFireClient,
	OnUnequipClient = OnUnequipClient,

	OnEquipServer = OnEquipServer,
	OnUnequipServer = OnUnequipServer,
}

module.Item = item

return module