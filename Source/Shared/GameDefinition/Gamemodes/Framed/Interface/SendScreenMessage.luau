local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Types = require(ReplicatedStorage.API.Types)
local GetRemote = require(ReplicatedStorage.Shared.GameDefinition.Items.Common.GetRemote)
local ScreenMessage = require(ReplicatedStorage.Shared.Interface.Util.ScreenMessage)

local remote = GetRemote("SendScreenMessage")

local function SendScreenMessage(to: Types.Participant, message: string, format: string): ()
	remote:FireClient(to.Player, message, format)
end

if RunService:IsClient() then
	remote.OnClientEvent:Connect(function(message: string, format: string)
		ScreenMessage(format, message)
	end)
end

return SendScreenMessage