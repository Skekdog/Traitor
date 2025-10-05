local TextChatService = game:GetService("TextChatService")

export type ChannelName = "RBXGeneral" | "RBXSystem"
local function GetChatChannel(channelName: ChannelName): TextChannel
	local channel = TextChatService:WaitForChild("TextChannels"):WaitForChild(channelName)
	if not channel:IsA("TextChannel") then
		error(channelName .. " is not a valid channel")
	end

	return channel
end

return GetChatChannel