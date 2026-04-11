local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Audio = require(ReplicatedStorage.API.Audio)
local Custom = require(ReplicatedStorage.API.Item.Presets.Custom)
local Types = require(ReplicatedStorage.API.Types)

local Scanner = {}

local BEEP_SOUND = Audio.MakeSound({
	Content = Content.fromAssetId(4578451106),
})

local scannerUi = ReplicatedStorage.Assets.Gamemode.PropHunt.Scanner

local function getUi()
	local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
	local ui: typeof(UIManager.RegisterUI(scannerUi)) = UIManager.TryGetUI("Scanner") :: typeof(UIManager.RegisterUI(scannerUi))? or UIManager.RegisterUI(scannerUi)
	return ui
end

local function OnEquipClient(): ()
	getUi():ToggleVisible(true)
end

local function OnUnequipClient(): ()
	getUi():ToggleVisible(false)
end

local DISTANCE_VALUES: {
	[number]: {
		Text: string,
		Colour: Color3,
		BeepRate: number,
	},
} = {
	[10] = {Text = "BOILING", Colour = Color3.fromRGB(252, 41, 4), BeepRate = 0.5},
	[20] = {Text = "HOT", Colour = Color3.fromRGB(252, 105, 0), BeepRate = 1},
	[40] = {Text = "WARM", Colour = Color3.fromRGB(255, 147, 23), BeepRate = 3},
	[60] = {Text = "COOL", Colour = Color3.fromRGB(149, 250, 255), BeepRate = 5},
	[80] = {Text = "COLD", Colour = Color3.fromRGB(46, 175, 255), BeepRate = 7},
	[100] = {Text = "FREEZING", Colour = Color3.fromRGB(23, 85, 255), BeepRate = math.huge},
}


local order: {number} = {}
for i, value in DISTANCE_VALUES do
	table.insert(order, i)
end
table.sort(order)

local function HeartbeatClient(item: Types.Item, dt: number): ()
	local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
	local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)

	local root = LocalCharacter.RootPart()
	if not root then
		return
	end

	local timeCount = (item.Extras.TimeCount or 0) + dt
	item.Extras.TimeCount = timeCount

	local position = root.Position

	local closestDistance = math.huge
	for _, player in Players:GetPlayers() do
		if player.Character and LocalParticipantInfo.GetParticipant(player.Name).Role().Definition.Name == "Prop" then
			local distance = player:DistanceFromCharacter(position)
			if distance < closestDistance then
				closestDistance = player:DistanceFromCharacter(position)
			end
		end
	end

	local value = DISTANCE_VALUES[order[#order]]
	for i = #order, 1, -1 do
		if closestDistance < order[i] then
			value = DISTANCE_VALUES[order[i]]
		end
	end

	if timeCount > value.BeepRate then
		item.Extras.TimeCount = 0
		Audio.Play2D(BEEP_SOUND)
	end

	local ui = getUi().Object

	if ui.TemperatureLabel.Text == value.Text then
		return
	end

	ui.TemperatureLabel.Text = value.Text

	TweenService:Create(ui.ColourBar, TweenInfo.new(0.25), {
		BackgroundColor3 = value.Colour
	}):Play()
end

local item = Custom({
	Name = "Scanner",
	Description = "Determines closeness to hiding Props",
	IconContent = Content.none,

	ItemGroup = {PreferredSlot = 9},
	DropDisabled = true,

	Model = ReplicatedStorage.Assets.ItemModels.DNAScanner,

	HoldAnimation = Content.fromAssetId(134193046304179),

	OnEquipClient = OnEquipClient,
	OnUnequipClient = OnUnequipClient,

	HeartbeatClient = HeartbeatClient,
})

Scanner.Item = item

return table.freeze(Scanner)