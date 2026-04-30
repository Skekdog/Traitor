local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientVoice = require(ReplicatedStorage.Shared.VoiceChat.ClientVoice)

local function ListenToSelf(_, value: boolean): ()
	ClientVoice.ListenToSelf(value)
end

return ListenToSelf