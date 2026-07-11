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

	local logOutput = message
	logOutput = "\n" .. "WARNING: " .. logOutput .. "\n"
	logOutput = EscapeRichText(logOutput)
	logOutput = TextColor(logOutput, Color3.new(1, 0.48, 0.13))
	logOutput = "<b>" .. logOutput .. "</b>"

	Message.Chat(logOutput, if RunService:IsServer() then "All" else nil)
end)

ScriptContext.Error:Connect(function(message, trace, instance)
	local logOutput = message
	logOutput = "\n" .. "ERROR: " .. logOutput .. "\n" .. trace .. "\n"
	logOutput = EscapeRichText(logOutput)
	logOutput = TextColor(logOutput, Color3.new(1, 0, 0))
	logOutput = "<b>" .. logOutput .. "</b>"

	Message.Chat(logOutput, if RunService:IsServer() then "All" else nil)
end)

return nil