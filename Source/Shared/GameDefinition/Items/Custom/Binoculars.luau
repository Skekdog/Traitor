local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Custom = require(ReplicatedStorage.API.Item.Presets.Custom)
local Types = require(ReplicatedStorage.API.Types)

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

local function AlternateFireClient(): true
	module.IsZoomedIn = not module.IsZoomedIn
	doZoomClient()
	return true
end

local bodies: {[Types.MapObject]: Highlight} = {}

local function OnUnequipClient(): ()
	module.IsZoomedIn = false
	doZoomClient()

	for corpse, highlight in bodies do
		highlight.Enabled = false
	end
end

local function OnEquipClient(): ()
	for _, corpse in CollectionService:GetTagged("Corpse") do
		if not corpse:IsA("Model") and not corpse:IsA("BasePart") then
			continue
		end

		if bodies[corpse] then
			bodies[corpse].Enabled = corpse:GetAttribute("Unidentified") == true
			continue
		end

		if not corpse:GetAttribute("Unidentified") then
			continue
		end

		local highlight = Instance.new("Highlight")
		highlight.FillColor = Color3.fromRGB(255, 208, 0)
		highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Name = "BinocularsHighlight"
		highlight.Parent = corpse

		corpse:GetAttributeChangedSignal("Unidentified"):Connect(function(): ()
			highlight.Enabled = corpse:GetAttribute("Unidentified") == true
		end)

		corpse.Destroying:Connect(function()
			bodies[corpse] = nil
		end)

		bodies[corpse] = highlight
	end
end

local function OnUnequipServer(_, participant: Types.Participant): ()
	doZoomServer(participant, false)
end

local function OnEquipServer(_, participant: Types.Participant): ()
	doZoomServer(participant, true)
end

local item = Custom({
	Name = "Binoculars",
	Description = "Corpses can be searched from a long distance. Additionally, unidentified bodies will be highlighted.",
	IconContent = Content.fromAssetId(7677183404),

	ItemGroup = ItemGroups.RoleUtility,

	Model = ReplicatedStorage.Assets.ItemModels.Binoculars,

	Cost = 1,
	MaxStock = 2,

	AlternateToggled = true,
	AlternateHint = "Zoom In / Out",

	AlternateFireClient = AlternateFireClient,
	OnUnequipClient = OnUnequipClient,
	OnEquipClient = OnEquipClient,

	OnEquipServer = OnEquipServer,
	OnUnequipServer = OnUnequipServer,
})

module.Item = item

return table.freeze(module)