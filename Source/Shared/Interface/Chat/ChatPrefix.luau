local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HookClientMessage = require(script.Parent.HookClientMessage)
local TagColors = require(script.Parent.TagColors)
local UsernameColor = require(script.Parent.UsernameColor)
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)

local DEAD_COLOR = Color3.fromRGB(245, 175, 26)
local DEAD_ASTERISK_COLOR = Color3.fromRGB(255, 0, 0)

local DEAD_STRING = `<font color='#{DEAD_ASTERISK_COLOR:ToHex()}'>*<font color='#{DEAD_COLOR:ToHex()}'>DEAD</font>*</font> `

HookClientMessage.Hook(function(message)
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
		message.PrefixText ..= DEAD_STRING
	end

	local tag = sender:GetAttribute("ChatTag")
	if typeof(tag) == "string" then
		local color = TagColors[tag] or Color3.new(1, 1, 1)
		message.PrefixText ..= `<font color='#{color:ToHex()}'>{tag}</font> `
	end

	message.PrefixText ..= `<font color='#{UsernameColor(participant.Name):ToHex()}'>{participant.Name}</font>:`

	message.PrefixText ..= "</b>"
end)

return nil