local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HookClientMessage = require(script.Parent.HookClientMessage)
local TagColors = require(script.Parent.TagColors)
local UsernameColor = require(script.Parent.UsernameColor)
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)

local DEAD_COLOR = Color3.fromRGB(245, 175, 26)
local DEAD_ASTERISK_COLOR = Color3.fromRGB(255, 0, 0)

local DEAD_STRING = `<font color='#{DEAD_ASTERISK_COLOR:ToHex()}'>*<font color='#{DEAD_COLOR:ToHex()}'>DEAD</font>*</font> `

local PRESET_MESSAGE_STRING = "[System Preset] "

HookClientMessage.Hook(function(message)
	local metadata = message.Metadata:split(" ")

	local sender: Player?
	if message.TextSource then
		sender = Players:GetPlayerByUserId(message.TextSource.UserId)
	else
		for _, tag in metadata do
			if tag:find("Player_") then
				local id = tonumber(tag:split("Player_")[2]) or 0
				sender = Players:GetPlayerByUserId(id)
			end
		end
	end

	if not sender then
		return
	end

	local participant = LocalParticipantInfo.GetParticipant(sender.Name)

	message.PrefixText = "<b>"

	if table.find(metadata, "QuickChat") then
		message.PrefixText ..= PRESET_MESSAGE_STRING
	end

	if participant.Status() ~= "Alive" then
		message.PrefixText ..= DEAD_STRING
	end

	local tag = sender:GetAttribute("ChatTag")
	if typeof(tag) == "string" then
		local color = TagColors[tag] or Color3.new(1, 1, 1)
		message.PrefixText ..= `<font color='#{color:ToHex()}'>{tag}</font> `
	end

	local padlocked = if message.Metadata:find("Relay") then " 🔒" else ""

	message.PrefixText ..= `<font color='#{UsernameColor(participant.Name):ToHex()}'>{participant.Name}{padlocked}</font>:`

	message.PrefixText ..= "</b>"
end)

return nil