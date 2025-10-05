local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UsernameColor = require(script.Parent.UsernameColor)
local GetChatChannel = require(ReplicatedStorage.API.GetChatChannel)
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)

local DEAD_COLOR = Color3.fromRGB(245, 175, 26)

GetChatChannel("RBXGeneral").OnIncomingMessage = function(message): ()
	if not message.TextSource then
		return -- Sometimes this is nil 🤷‍♂️
	end
	local sender = Players:GetPlayerByUserId(message.TextSource.UserId)
	if not sender then
		return
	end

	local participant = LocalParticipantInfo.GetParticipant(sender.Name)

	message.PrefixText = "<b>"

	if participant.Status() ~= "Alive" then
		message.PrefixText ..= `<font color='#{DEAD_COLOR:ToHex()}'>` .. "*DEAD*</font> "
	end

	if sender:GetAttribute("ChatTag") then
		message.PrefixText ..= `{sender:GetAttribute("ChatTag")} `
	end

	message.PrefixText ..= `<font color='#{UsernameColor(participant.Name):ToHex()}'>{participant.Name}</font>:`

	message.PrefixText ..= "</b>"
end

return nil