local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local GameHooks = require(ReplicatedStorage.API.GameHooks)
local GetRound = require(ReplicatedStorage.API.GetRound)
local Types = require(ReplicatedStorage.API.Types)

local GhostVoice = {}

local ghostOutput = Instance.new("AudioDeviceOutput")
ghostOutput.Name = "GhostVoice"
ghostOutput.Parent = SoundService

local function getAudioInput(player: Player): AudioDeviceInput?
	return player:FindFirstChildWhichIsA("AudioDeviceInput")
end

local function assignPlayers(): ()
	print("\nASSIGNING\n")
	local players = Players:GetPlayers()

	local hasNoCharacterUsers: {number} = {}
	for _, player in players do
		if not player.Character then
			table.insert(hasNoCharacterUsers, player.UserId)
		end
	end

	local isRoundInProgress = GetRound():IsInProgress()
	for _, player in players do
		local input = getAudioInput(player)
		if not input then
			continue
		end

		if isRoundInProgress and not player.Character then
			print("Assigning", player, hasNoCharacterUsers[1], hasNoCharacterUsers[2])
			input.AccessType = Enum.AccessModifierType.Allow
			input:SetUserIdAccessList(hasNoCharacterUsers)
		else
			print("Assigning", player, "everyone")
			input.AccessType = Enum.AccessModifierType.Deny
			input:SetUserIdAccessList({})
		end
	end
end

function GhostVoice.MakeGhost(player: Player): ()
	local input = getAudioInput(player)
	if not input then
		return
	end

	local ghostWire = input:FindFirstChildWhichIsA("Wire") or Instance.new("Wire")
	ghostWire.SourceInstance = input
	ghostWire.TargetInstance = ghostOutput

	ghostWire.Parent = input

	assignPlayers()
end

function GhostVoice.DisconnectGhost(player: Player): ()
	local input = getAudioInput(player)
	if not input then
		return
	end

	input.AccessType = Enum.AccessModifierType.Deny
	input:SetUserIdAccessList({})

	local ghostWire = input:FindFirstChildWhichIsA("Wire")
	if ghostWire then
		ghostWire.SourceInstance = nil :: any -- incorrect type definition here
	end
end

GhostVoice.GhostOutput = ghostOutput

GameHooks.OnDeath["GhostVoice"] = function(_, participant: Types.Participant): ()
	local corpse = participant.Corpse
	if not corpse then
		return
	end

	local char = corpse.Model
	if not char then
		return
	end

	local emitter = char:FindFirstChild("VoiceEmitter")
	if emitter then
		emitter:Destroy()
	end
end

GameHooks.OnPhaseChanged["GhostVoice"] = assignPlayers

local function onPlayerAdded(player: Player): ()
	player.CharacterAdded:Connect(assignPlayers)
	player.CharacterRemoving:Connect(assignPlayers)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

assignPlayers()

return table.freeze(GhostVoice)