local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetChatChannel = require(ReplicatedStorage.API.GetChatChannel)
local RBXGeneral = GetChatChannel("RBXGeneral")

type Callback = (message: TextChatMessage) -> ()

local hooks: {[Callback]: true} = {}

RBXGeneral.OnIncomingMessage = function(message): ()
	for callback in hooks do
		callback(message)
	end
end

local HookClientMessage = {}

function HookClientMessage.Hook(callback: Callback): ()
	hooks[callback] = true
end

function HookClientMessage.RemoveHook(callback: Callback): ()
	hooks[callback] = nil
end

return HookClientMessage