local LogService = game:GetService("LogService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ScriptContext = game:GetService("ScriptContext")
local Message = require(ReplicatedStorage.API.Interface.Message)
local TextColor = require(ReplicatedStorage.API.TextColor)
local EscapeRichText = require(ReplicatedStorage.Shared.Grammar.EscapeRichText)

if RunService:IsStudio() then
	return nil
end

LogService.MessageOut:Connect(function(message, kind)
	if kind ~= Enum.MessageType.MessageWarning then
		return
	end

	message = "\n" .. "WARNING: " .. message .. "\n"
	message = EscapeRichText(message)
	message = TextColor(message, Color3.new(1, 0.48, 0.13))
	message = "<b>" .. message .. "</b>"

	Message.Chat(message, if RunService:IsServer() then "All" else nil)
end)

ScriptContext.Error:Connect(function(message, trace, instance)
	message = "\n" .. "ERROR: " .. message .. "\n" .. trace .. "\n"
	message = EscapeRichText(message)
	message = TextColor(message, Color3.new(1, 0, 0))
	message = "<b>" .. message .. "</b>"

	Message.Chat(message, if RunService:IsServer() then "All" else nil)
end)

return nil