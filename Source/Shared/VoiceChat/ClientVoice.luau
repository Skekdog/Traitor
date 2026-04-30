local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
local Settings = require(ReplicatedStorage.Shared.Settings.Settings)
local DynamicValue = require(ReplicatedStorage.Shared.Util.DynamicValue)

local ClientVoice = {}

local input = Players.LocalPlayer:WaitForChild("AudioDeviceInput")
assert(input:IsA("AudioDeviceInput"))

local ghostOutput = SoundService:WaitForChild("GhostVoice")
assert(ghostOutput:IsA("AudioDeviceOutput"))

local ghostWire = input:WaitForChild("Wire")
assert(ghostWire:IsA("Wire"))

local listener = Instance.new("AudioListener")
local output = Instance.new("AudioDeviceOutput")

local wire = Instance.new("Wire")
wire.SourceInstance = listener
wire.TargetInstance = output
wire.Parent = output

output.Parent = listener
listener.Parent = workspace.CurrentCamera

function ClientVoice.ListenToSelf(active: boolean): ()
	ghostWire.TargetInstance = if active then ghostOutput else (nil :: any) -- incorrect type definition

	local char = LocalCharacter.Character()
	if not char then
		return
	end

	local emitter = char:FindFirstChild("VoiceEmitter")
	if not emitter or not emitter:IsA("AudioEmitter") then
		return
	end

	emitter.AudioInteractionGroup = if active then "" else "NoHearSelf"
end

ClientVoice.Emitter = DynamicValue.new<<AudioEmitter?>>()

LocalCharacter.Character:Connect(function(char)
	if not char then
		return
	end

	local emitter = char:FindFirstChild("VoiceEmitter")
	if emitter and emitter:IsA("AudioEmitter") then
		ClientVoice.Emitter:SetValue(emitter)
		return
	end

	local con: RBXScriptConnection
	con = char.ChildAdded:Connect(function(emitter)
		if emitter and emitter:IsA("AudioEmitter") then
			ClientVoice.Emitter:SetValue(emitter)
			con:Disconnect()
		end
	end)
end)

ClientVoice.Emitter:Connect(function(emitter)
	if emitter then
		ClientVoice.ListenToSelf(Settings.GetSetting("Listen To Self") :: boolean)
	end
end)

ClientVoice.ListenToSelf(false)

return table.freeze(ClientVoice)