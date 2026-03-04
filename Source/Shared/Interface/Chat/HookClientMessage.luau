local TextChatService = game:GetService("TextChatService")

type Callback = (message: TextChatMessage) -> ()

local hooks: {Callback} = {}

local HookClientMessage = {}

function HookClientMessage.Hook(callback: Callback): ()
	table.insert(hooks, callback)
end

function HookClientMessage.RemoveHook(callback: Callback): ()
	table.remove(hooks, table.find(hooks, callback) or error("aaaa"))
end

function HookClientMessage.ExecuteOn(message: TextChatMessage): ()
	for _, callback in hooks do
		callback(message)
	end
end

TextChatService.OnIncomingMessage = function(message): ()
	HookClientMessage.ExecuteOn(message)
end

return HookClientMessage