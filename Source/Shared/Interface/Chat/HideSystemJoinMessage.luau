local HookClientMessage = require(script.Parent.HookClientMessage)

HookClientMessage.Hook(function(message)
	if message.Metadata:find("Roblox.Notification.Friend.Joined") then
		message.Metadata ..= " MUTED"
	end
end)

return nil