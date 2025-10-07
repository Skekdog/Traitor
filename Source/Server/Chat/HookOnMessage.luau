local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetChatChannel = require(ReplicatedStorage.API.GetChatChannel)
local RBXGeneral = GetChatChannel("RBXGeneral")

type Callback = (message: TextChatMessage, source: TextSource) -> boolean

local hooks: {Callback} = {}

RBXGeneral.ShouldDeliverCallback = function(message, source)
	for _, callback in hooks do
		if not callback(message, source) then
			return false
		end
	end
	return true
end

local function HookOnMessage(callback: Callback): ()
	table.insert(hooks, callback)
end

return HookOnMessage