local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local Types = require(ReplicatedStorage.API.Types)
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local Settings = require(ReplicatedStorage.Shared.Settings.Settings)
local DynamicValue = require(ReplicatedStorage.Shared.Util.DynamicValue)

local ClientVoice = {}

local remote = GetRemote("TeamVoice", ReplicatedStorage.Remotes.ClientServer)

function ClientVoice.AllowTeamVoice(role: Types.RoleDefinition, status: Types.ParticipantStatus | "Spectating"): ()
	local allow = (role.CanTeamChat and status == "Alive") or false
	if allow then
		ControlManager.Register("Team Voice", function(_, state)
			remote:FireServer(state == Enum.UserInputState.Begin)
			return Enum.ContextActionResult.Pass
		end)
	else
		ControlManager.Unregister("Team Voice")
	end
end

local listener = Instance.new("AudioListener")
local output = Instance.new("AudioDeviceOutput")

local wire = Instance.new("Wire")
wire.SourceInstance = listener
wire.TargetInstance = output
wire.Parent = output

output.Parent = listener
listener.Parent = workspace.CurrentCamera

function ClientVoice.ListenToSelf(active: boolean): ()
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

return table.freeze(ClientVoice)