local TextChatService = game:GetService("TextChatService")

type Callback = (message: TextChatMessage) -> ()

local hooks: {[Callback]: true} = {}

local HookClientMessage = {}

function HookClientMessage.Hook(callback: Callback): ()
	hooks[callback] = true
end

function HookClientMessage.RemoveHook(callback: Callback): ()
	hooks[callback] = nil
end

function HookClientMessage.ExecuteOn(message: TextChatMessage): ()
	for callback in hooks do
		callback(message)
	end
end

TextChatService.OnIncomingMessage = function(message): ()
	HookClientMessage.ExecuteOn(message)
end

return HookClientMessage