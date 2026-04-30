local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Audio = require(ReplicatedStorage.API.Audio)
local Custom = require(ReplicatedStorage.API.Item.Presets.Custom)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Types = require(ReplicatedStorage.API.Types)

local JBomb = {}

local texts = {
	"STAP!!!",
	"PLIZZZ )):",
	"NOOOO!!! DD:"
}

local TEXT_INTERVAL = 0.5

local heyOverHere = Audio.MakeSound({
	Content = Content.fromAssetId(1454256125),
	RolloffEnd = 40,
	RolloffStart = 50,
	Volume = 1,
})

if RunService:IsServer() then
	heyOverHere.Parent = ReplicatedStorage.Assets.ItemSounds
end

local function disable(item: Types.Item): ()
	item.AlternateDisabled = true
	item.PrimaryDisabled = true
	item.UnequipDisabled = true
	item.DropDisabled = true
end

local function PrimaryFireClient(item: Types.Item): boolean
	local Client = require(ReplicatedStorage.API.Item.Behaviour.Client)

	disable(item)

	Client.PlaySound(item, "Primary")
	Client.PlayAnimation(item, "Primary")

	local model = Client.GetViewmodelItem() :: typeof(ReplicatedStorage.Assets.ItemModels.JBomb)?
	local displayUI = if model then model:FindFirstChild("DisplayUI") else nil
	local label = if displayUI then displayUI:FindFirstChild("Label") else nil
	if label and displayUI then
		label.Text = texts[1]
		displayUI.Enabled = true

		task.spawn(function()
			for _, text in texts do
				label.Text = text
				task.wait(TEXT_INTERVAL)
			end
		end)
	end

	return true
end

local explosion = Audio.MakeSound({
	Content = Content.fromAssetId(131518429398957),
	RolloffStart = 30,
	RolloffEnd = 60,
	Volume = 2,
})

local function PrimaryFireServer(item: Types.Item, _, _, participant: Types.Participant): ()
	local Server = require(ReplicatedStorage.API.Item.Behaviour.Server)

	disable(item)

	assert(item.PrimarySound)
	task.delay(item.PrimarySound.TimeLength, function()
		if participant:GetEquippedItem() ~= item then
			return
		end

		local char = participant:GetCharacter()
		if not char or not char.PrimaryPart then
			return
		end

		Server.CreateExplosion(participant.Round, {
			Kind = "ExplosionParams",
			Attacker = participant,
			Position = char.PrimaryPart.Position,
			SourceItem = item,
			Definition = {
				Damage = 200,
				FalloffEnd = 25,
				FalloffStart = 15,
				Pressure = 200000,
				VisualRadius = 25,
				Sound = explosion,
			}
		})
	end)
end

local function AlternateFireClient(item: Types.Item): boolean
	local Client = require(ReplicatedStorage.API.Item.Behaviour.Client)
	local Checks = require(ReplicatedStorage.API.Item.Behaviour.Checks)

	if not Checks.Interval(item, "Alternate") then
		return false
	end

	Client.ApplyInterval(item, "Alternate")
	Client.PlaySound(item, "Alternate")

	return true
end

local item = Custom({
	Name = "JBomb",
	DisplayName = "J-Bomb",
	Description = "Triggers an explosion, killing everyone in range. No refunds.",
	IconContent = Content.fromAssetId(120985266025944),

	Cost = 1,
	MaxStock = 2, -- Give it to an innocent, you know you want to

	IsSuspicious = true,
	ItemGroup = ItemGroups.RoleWeapon,

	Model = ReplicatedStorage.Assets.ItemModels.JBomb,
	HoldAnimation = Content.fromAssetId(109945925204096),

	PregameDisable = true,

	PrimaryToggled = true,
	PrimarySound = ReplicatedStorage.Assets.ItemSounds.JBomb,
	PrimaryAnimation = Content.fromAssetId(80011723264524),

	AlternateInterval = 1,
	AlternateToggled = true,
	AlternateSound = heyOverHere,

	AlternateFireServer = function() return nil end,
	AlternateFireClient = AlternateFireClient,

	PrimaryFireClient = PrimaryFireClient,
	PrimaryFireServer = PrimaryFireServer,
})

JBomb.Item = item

return JBomb