local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChatWindow = require(script.Parent.ChatWindow)
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)

local lastStatus: string?
LocalParticipantInfo.GetParticipant().Status:Connect(function(status)
	if status == lastStatus then
		return
	end

	lastStatus = status

	if status == "Missing" and ChatWindow.InputBox.Text ~= "" then
		ReplicatedStorage.Remotes.ClientServer.LastWords:FireServer(ChatWindow.InputBox.Text)
	end
end)

return nil