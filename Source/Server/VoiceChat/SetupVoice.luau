local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SubmergedVoice = require(ReplicatedStorage.Shared.Effects.SubmergedVoice)
local GhostVoice = require(script.Parent.GhostVoice)

local DISTANCE_ATTENUATION = {
	[10] = 1,
	[11] = 0.91,
	[12] = 0.82,
	[14] = 0.73,
	[15] = 0.64,
	[16] = 0.55,
	[20] = 0.4,
	[25] = 0.3,
	[32] = 0.1,
	[40] = 0,
}

local function createEmitter(player: Player, source: AudioDeviceInput): (AudioEmitter, Wire, Wire)
	local emitter = Instance.new("AudioEmitter")
	emitter.Name = "VoiceEmitter"
	emitter.AcousticSimulationEnabled = false
	emitter:SetDistanceAttenuation(DISTANCE_ATTENUATION)

	local inputWire = Instance.new("Wire")
	inputWire.SourceInstance = source
	inputWire.TargetInstance = emitter
	inputWire.Name = "InputWire"
	inputWire.Parent = emitter

	local outputWire = Instance.new("Wire")
	outputWire.TargetInstance = emitter
	outputWire.Name = "OutputWire"
	outputWire.Parent = emitter

	inputWire.Destroying:Once(function()
		GhostVoice.MakeGhost(player)
	end)

	return emitter, inputWire, outputWire
end

local function onPlayerAdded(player: Player): ()
	local input = Instance.new("AudioDeviceInput")
	input.Player = player
	input.Parent = player

	player.CharacterAdded:Connect(function(char)
		local emitter, input, output = createEmitter(player, input)
		emitter.Parent = char

		GhostVoice.DisconnectGhost(player)

		char:GetAttributeChangedSignal("IsSubmerged"):Connect(function()
			local isSubmerged = char:GetAttribute("IsSubmerged")
			if isSubmerged then
				SubmergedVoice.Connect(input, output)
			else
				SubmergedVoice.Disconnect(input, output)
			end
		end)
	end)

	GhostVoice.MakeGhost(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

return nil