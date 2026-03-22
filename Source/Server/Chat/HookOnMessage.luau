local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetChatChannel = require(ReplicatedStorage.API.GetChatChannel)
local RBXGeneral = GetChatChannel("RBXGeneral")

local HookOnMessage = {}

type Callback = (message: TextChatMessage, source: TextSource) -> boolean

local hooks: {Callback} = {}

HookOnMessage.FinalHook = nil :: Callback?

RBXGeneral.ShouldDeliverCallback = function(message, source)
	local doNotDeliver = false
	for _, callback in hooks do
		if not callback(message, source) then
			doNotDeliver = true
		end
	end

	if HookOnMessage.FinalHook and not HookOnMessage.FinalHook(message, source) then
		doNotDeliver = true
	end

	return not doNotDeliver
end

function HookOnMessage.Hook(callback: Callback): ()
	table.insert(hooks, callback)
end

return table.freeze(HookOnMessage)