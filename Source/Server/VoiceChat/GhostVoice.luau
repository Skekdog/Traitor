local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local GameHooks = require(ReplicatedStorage.API.GameHooks)
local Types = require(ReplicatedStorage.API.Types)

local GhostVoice = {}

local ghostOutput = Instance.new("AudioDeviceOutput")
ghostOutput.Name = "GhostVoice"
ghostOutput.Parent = SoundService

local function getAudioInput(player: Player): AudioDeviceInput?
	return player:FindFirstChildWhichIsA("AudioDeviceInput")
end

local function assignPlayers(audioInput: AudioDeviceInput): ()
	local players = Players:GetPlayers()

	local userIds: {number} = {}
	for _, player in players do
		if not player.Character then
			table.insert(userIds, player.UserId)
		end
	end

	audioInput:SetUserIdAccessList(userIds)
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

	input.AccessType = Enum.AccessModifierType.Allow
	assignPlayers(input)
end

function GhostVoice.DisconnectGhost(player: Player): ()
	local input = getAudioInput(player)
	if not input then
		return
	end

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



return table.freeze(GhostVoice)