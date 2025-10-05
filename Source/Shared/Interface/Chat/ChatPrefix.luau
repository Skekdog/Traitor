local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UsernameColor = require(script.Parent.UsernameColor)
local GetChatChannel = require(ReplicatedStorage.API.GetChatChannel)
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)

local DEAD_COLOR = Color3.fromRGB(245, 175, 26)

GetChatChannel("RBXGeneral").OnIncomingMessage = function(message): ()
	local sender = Players:GetPlayerByUserId(message.TextSource.UserId)
	if not sender then
		return
	end

	local participant = LocalParticipantInfo.GetParticipant(sender.Name)

	message.PrefixText = `<b><font color='#{UsernameColor(participant.Name):ToHex()}'>{participant.Name}</font></b>:`

	if participant.Status() ~= "Alive" then
		message.PrefixText = `<b><font color='#{DEAD_COLOR:ToHex()}'>` .. "*DEAD*</font></b> " .. message.PrefixText
	end
end

return nil