local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Custom = require(ReplicatedStorage.API.Item.Presets.Custom)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Types = require(ReplicatedStorage.API.Types)
local PlaySound = require(ReplicatedStorage.API.PlaySound)

local JBomb = {}

local texts = {
	"STAP!!!",
	"PLIZZZ )):",
	"NOOOO!!! DD:"
}

local TEXT_INTERVAL = 0.5

local function disable(item: Types.Item): ()
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
	if model then
		model.DisplayUI.Label.Text = texts[1]
		model.DisplayUI.Enabled = true

		task.spawn(function()
			for _, text in texts do
				model.DisplayUI.Label.Text = text
				task.wait(TEXT_INTERVAL)
			end
		end)
	end

	return true
end

local explosion = PlaySound.MakeSound(131518429398957, {
	RollOffMinDistance = 30,
	RollOffMaxDistance = 60,
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

local item = Custom({
	Name = "JBomb",
	DisplayName = "J-Bomb",
	Description = "Triggers an explosion, killing everyone in range. No refunds.",
	IconContent = Content.none,

	Cost = 1,
	MaxStock = 2, -- Give it to an innocent, you know you want to

	IsSuspicious = true,
	ItemGroup = ItemGroups.RoleWeapon,

	Model = ReplicatedStorage.Assets.ItemModels.JBomb,
	HoldAnimation = Content.fromAssetId(109945925204096),

	PrimaryToggled = true,
	PrimarySound = ReplicatedStorage.Assets.ItemSounds.JBomb,
	PrimaryAnimation = Content.fromAssetId(80011723264524),

	PrimaryFireClient = PrimaryFireClient,
	PrimaryFireServer = PrimaryFireServer,
})

JBomb.Item = item

return JBomb