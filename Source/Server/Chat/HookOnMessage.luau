local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetChatChannel = require(ReplicatedStorage.API.GetChatChannel)
local RBXGeneral = GetChatChannel("RBXGeneral")

local HookOnMessage = {}

type Callback = (message: TextChatMessage, source: TextSource) -> boolean

local hooks: {Callback} = {}

local finalHook: Callback?
function HookOnMessage.SetFinalHook(callback: Callback): ()
	finalHook = callback
end

RBXGeneral.ShouldDeliverCallback = function(message, source)
	local doNotDeliver = false
	for _, callback in hooks do
		if not callback(message, source) then
			doNotDeliver = true
		end
	end

	if finalHook and not finalHook(message, source) then
		doNotDeliver = true
	end

	return not doNotDeliver
end

function HookOnMessage.Hook(callback: Callback): ()
	table.insert(hooks, callback)
end

return table.freeze(HookOnMessage)