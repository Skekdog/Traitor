local Players = game:GetService("Players")

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

local function createEmitter(source: AudioDeviceInput): AudioEmitter
	local emitter = Instance.new("AudioEmitter")
	emitter.Name = "VoiceEmitter"
	emitter.AcousticSimulationEnabled = false
	emitter:SetDistanceAttenuation(DISTANCE_ATTENUATION)

	local wire = Instance.new("Wire")
	wire.SourceInstance = source
	wire.TargetInstance = emitter
	wire.Parent = emitter

	return emitter
end

local function onPlayerAdded(player: Player): ()
	local input = Instance.new("AudioDeviceInput")
	input.Player = player
	input.Parent = player

	player.CharacterAdded:Connect(function(char)
		createEmitter(input).Parent = char
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

return nil