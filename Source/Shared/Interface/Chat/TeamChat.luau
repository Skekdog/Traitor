local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChatWindow = require(script.Parent.ChatWindow)
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)

local participant = LocalParticipantInfo.GetParticipant()

participant.Role:Connect(function(role)
	ChatWindow.AllowTeamChat(role.Definition, participant.Status())
end, true)

participant.Status:Connect(function(status)
	ChatWindow.AllowTeamChat(participant.Role().Definition, status)
end)

return nil