local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local DeathSounds = require(ReplicatedStorage.Shared.Config.DeathSounds)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local PLAY_COOLDOWN = 0.25

local serverRound: Types.Round?

type Radio = Types.Interactable & {
	Extras: {
		Player: Player?,
		LastPlayedAt: number?,
		[any]: never,
	}
}

type SoundEntry = {
	Sound: Sound | {Sound},
	AddedByMap: string?,
	AddedByGamemode: string?,
}

local sounds: {SoundEntry} = {}

local remote: RemoteEvent
if RunService:IsServer() then
	remote = Instance.new("RemoteEvent")
	remote.Name = "RadioUse"
	remote.Parent = script
else
	local found = script:WaitForChild("RadioUse")
	assert(found:IsA("RemoteEvent"), "RadioUse must be a RemoteEvent")
	remote = found
end


local function getEquipmentMenu()
	local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
	local ui = UIManager.TryGetUI("Equipment Shop") :: (UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs["Equipment Shop"])})?
	return ui
end

local function addToMenu(sound: Sound | {Sound}): ()
	local ui = getEquipmentMenu()
	if not ui then
		return
	end

	local page = ui.Object.Page.Radio
	local button = page.RadioButton:Clone()

	local soundName = if typeof(sound) == "table" then sound[1].Name else sound.Name

	button.Name = "Button_" .. soundName
	button.Text = soundName
	button.Visible = true

	button.Activated:Connect(function()
		remote:FireServer(soundName)
	end)

	button.Parent = page.ScrollingFrame :: any
end

if RunService:IsClient() then
	local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
	UIManager.RegisteredEvent:Connect(function(name: string)
		if name ~= "Equipment Shop" then
			return
		end

		local ui = getEquipmentMenu()
		if not ui then
			return
		end

		for _, v in ui.Object.Page.Radio.ScrollingFrame:GetChildren() do
			if v:IsA("TextButton") then
				v:Destroy()
			end
		end

		for _, v in sounds do
			addToMenu(v.Sound)
		end
	end)
end

-- jesus fucking christ this is horrible

local function addSound(sound: Sound | {Sound}, map: string?, gamemode: string?): ()
	for _, v in sounds do
		if v.Sound == sound then
			return
		end
	end

	table.insert(sounds, {
		Sound = sound,
		AddedByMap = map,
		AddedByGamemode = gamemode,
	})

	if RunService:IsClient() then
		addToMenu(sound)
	end
end

local function removeSound(index: number): ()
	table.remove(sounds, index)

	if RunService:IsClient() then
		local ui = getEquipmentMenu()
		if not ui then
			return
		end

		local page = ui.Object.Page.Radio
		local sound = sounds[index].Sound
		local button = page:FindFirstChild("Button_" .. if typeof(sound) == "table" then sound[1].Name else sound.Name)
		if button then
			button:Destroy()
		end
	end
end

local function removeSoundsByMap(newMap: string): ()
	for i = #sounds, 1, -1 do
		if sounds[i].AddedByMap == newMap then
			removeSound(i)
		end
	end
end

local function removeSoundsByGamemode(newGamemode: string): ()
	for i = #sounds, 1, -1 do
		if sounds[i].AddedByGamemode == newGamemode then
			removeSound(i)
		end
	end
end

local function addSoundsFromMap(map: Types.Map): ()
	for _, v in map.Definition.AvailableItems do
		if v.Kind == "Gun" and v.AttackSound then
			addSound(v.AttackSound, map.Definition.Name, nil)
		end
	end
end

local function addSoundsFromGamemode(gamemode: Types.GamemodeDefinition): ()
	for _, v in gamemode.AvailableItems do
		if v.Kind == "Gun" and v.AttackSound then
			addSound(v.AttackSound, nil, gamemode.Name)
		end
	end
end

do
	local footstepSound = Instance.new("Sound")
	footstepSound.Name = "Footstep"

	footstepSound.SoundId = "rbxassetid://81623756670923"
	footstepSound.RollOffMinDistance = 10
	footstepSound.RollOffMaxDistance = 15
	footstepSound.Volume = 1

	addSound(footstepSound)

	local burnSound = ReplicatedStorage.Assets.WeaponSounds.FlareBurn:Clone()
	burnSound.Name = "Burn"

	addSound(burnSound)

	local c4BeepingSound = Instance.new("Sound")
	c4BeepingSound.Name = "C4 Beeping"
	c4BeepingSound.SoundId = "rbxassetid://6992631696"
	c4BeepingSound.Volume = 1.5
	c4BeepingSound.RollOffMinDistance = 10
	c4BeepingSound.RollOffMaxDistance = 20
	c4BeepingSound.PlaybackRegionsEnabled = true
	c4BeepingSound.PlaybackRegion = NumberRange.new(2.5, 7.5)

	addSound(c4BeepingSound)

	local smallExplosionSound: Sound = if RunService:IsClient() then Instance.new("Sound") else ServerStorage.Assets.Explosion:Clone()
	smallExplosionSound.Name = "Small Explosion"

	addSound(smallExplosionSound)

	local deathSounds: {Sound} = {}
	for _, v in DeathSounds do
		local sound = Instance.new("Sound")
		sound.Name = "Death"
		sound.SoundId = v
		sound.RollOffMinDistance = 20
		sound.RollOffMaxDistance = 50
		table.insert(deathSounds, sound)
	end

	addSound(deathSounds)
end

if RunService:IsClient() then
	local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)

	local lastGamemode: Types.GamemodeDefinition?
	local lastMap: Types.Map?

	LocalRoundInfo.Gamemode:Connect(function(gamemode)
		if not gamemode or gamemode == lastGamemode then
			return
		end
		if lastGamemode then
			removeSoundsByGamemode(lastGamemode.Name)
		end
		lastGamemode = gamemode
		addSoundsFromGamemode(gamemode)
	end, true)

	LocalRoundInfo.Map:Connect(function(map)
		if not map or map :: Types.Map? == lastMap then
			return
		end
		if lastMap then
			removeSoundsByMap(lastMap.Definition.Name)
		end
		lastMap = map
		addSoundsFromMap(map)
	end, true)
end

local activeRadios: {Radio} = {}

if RunService:IsServer() then
	local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)

	local lastGamemode: Types.GamemodeDefinition?
	local lastMap: Types.Map?

	remote.OnServerEvent:Connect(function(player, soundName: unknown): ()
		if typeof(soundName) ~= "string" then
			return
		end

		if not serverRound then
			return
		end

		if not player.Character then
			return
		end

		local radio: Radio?
		for _, v in activeRadios do
			if (v.Extras.Player :: Player?) == player then
				radio = v
				break
			end
		end

		if not radio then
			return
		end

		if radio.Extras.LastPlayedAt and tick() - radio.Extras.LastPlayedAt < PLAY_COOLDOWN then
			return
		end

		if radio.Model:FindFirstChild(soundName) then
			return
		end

		if lastGamemode ~= serverRound.Gamemode then
			if lastGamemode then
				removeSoundsByGamemode(lastGamemode.Name)
			end
			lastGamemode = serverRound.Gamemode
			addSoundsFromGamemode(serverRound.Gamemode)
		end

		local map = serverRound:GetMap()
		if lastMap ~= map :: Types.Map? then
			if lastMap then
				removeSoundsByMap(lastMap.Definition.Name)
			end
			lastMap = map
			addSoundsFromMap(map)
		end

		local sound: Sound
		for _, v in sounds do
			if typeof(v.Sound) == "table" and v.Sound[1].Name == soundName or typeof(v.Sound) ~= "table" and v.Sound.Name == soundName then
				sound = if typeof(v.Sound) == "table" then v.Sound[math.random(#v.Sound)] else v.Sound
				break
			end
		end

		if not sound then
			return
		end

		radio.Extras.LastPlayedAt = tick()

		PlaySound(sound, nil, radio.Model, {
			SoundGroup = SoundService.AllSounds :: SoundGroup,
		})
	end)
end

local function BeforeTakeDamage(interactable: Radio, params: Types.DamageParams?): boolean
	if not params then
		return false
	end

	local attacker = params.Attacker
	if not attacker then
		return false
	end

	return not attacker:GetRole().Definition.IsEvil
end

local function OnLoadServer(interactable: Radio): ()
	serverRound = interactable.Round
	interactable.Model.Destroying:Connect(function()
		table.remove(activeRadios, table.find(activeRadios, interactable) or error("Radio not found"))
	end)

	table.insert(activeRadios, interactable)
end

local function OnInteractServer(interactable: Radio, participant: Types.Participant): ()
	if participant.Player ~= interactable.Extras.Player :: Player? then
		return
	end

	local radioItem = participant.Round:GetItemDefinition(interactable.Definition.Name)
	if not radioItem then
		return warn("Could not find Radio item")
	end

	if participant:IsItemGroupOccupied(radioItem.ItemGroup) then
		return
	end

	interactable.Model:Destroy()
	participant:GiveItemFromItemDefinition(radioItem)
end

local interactable: Types.InteractableDefinition = {
	Name = "Radio",

	IsContinuousInteraction = false,
	InteractionRange = 7.5,

	Model = ReplicatedStorage.Assets.InteractableModels.Radio,

	OnInteractServer = OnInteractServer,
	OnLoadServer = OnLoadServer,
	BeforeTakeDamage = BeforeTakeDamage,
}

return interactable