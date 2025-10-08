local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function ChatTag(name: string, value: string): ()
	if value ~= "" then
		ReplicatedStorage.Remotes.ClientServer.SetChatTag:FireServer(value)
	end
end

return ChatTag