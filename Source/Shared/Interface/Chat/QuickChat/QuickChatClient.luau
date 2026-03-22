local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetRemote = require(ReplicatedStorage.API.GetRemote)

local QuickChatClient = {}

local remote = GetRemote("QuickChat", ReplicatedStorage.Remotes)

function QuickChatClient.Chat(messageId: number, id: Model?): ()
	remote:FireServer(messageId, id)
end

return table.freeze(QuickChatClient)