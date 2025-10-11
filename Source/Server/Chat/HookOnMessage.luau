local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetChatChannel = require(ReplicatedStorage.API.GetChatChannel)
local RBXGeneral = GetChatChannel("RBXGeneral")

type Callback = (message: TextChatMessage, source: TextSource) -> boolean

local hooks: {Callback} = {}

RBXGeneral.ShouldDeliverCallback = function(message, source)
	local doNotDeliver = false
	for _, callback in hooks do
		if not callback(message, source) then
			doNotDeliver = true
		end
	end
	return not doNotDeliver
end

local function HookOnMessage(callback: Callback): ()
	table.insert(hooks, callback)
end

return HookOnMessage