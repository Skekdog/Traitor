local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GetRemote = require(script.Parent.GetRemote)
local ScreenMessageB = require(ReplicatedStorage.Shared.Interface.Util.ScreenMessage)

export type Format = "Standard" | "Error" | "Info" | "Success" | "Warn"

local remote = GetRemote("ScreenMessage", script)

local function ScreenMessage(message: string, format: Format, overrides: {LabelProperties: {[string]: any}}?, to: Player?): TextLabel?
	if RunService:IsServer() then
		assert(to, "You must specify a player to send the message to")
		remote:FireClient(to, message, format, overrides)
		return nil
	end
	return ScreenMessageB(format, message, overrides)
end

if RunService:IsClient() then
	remote.OnClientEvent:Connect(ScreenMessage)
end

return ScreenMessage