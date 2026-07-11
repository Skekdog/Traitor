local SoundService = game:GetService("SoundService")

local SubmergedVoice = {}

local equaliser = Instance.new("AudioEqualizer")
equaliser.HighGain = -10
equaliser.LowGain = 5
equaliser.MidGain = -5
equaliser.Parent = SoundService

local reverb = Instance.new("AudioReverb")
reverb.DecayTime = 0.1
reverb.Density = 1
reverb.DryLevel = -6
reverb.WetLevel = 2
reverb.Parent = SoundService

local effectWire = Instance.new("Wire")
effectWire.SourceInstance = equaliser
effectWire.TargetInstance = reverb
effectWire.Parent = reverb

function SubmergedVoice.Connect(input: Wire, output: Wire): ()
	input.TargetInstance = effectWire.SourceInstance
	output.SourceInstance = effectWire.TargetInstance
end

function SubmergedVoice.Disconnect(input: Wire, output: Wire): ()
	input.TargetInstance = output.TargetInstance
	output.SourceInstance = nil :: any -- type definition is wrong here
end

return table.freeze(SubmergedVoice)