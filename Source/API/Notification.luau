local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Types = require(script.Parent.Types)

local function ShowMessage(message: string, kind: Types.MessageKind | "QuickChat" | "Relay", to: Player?, from: Player?): ()
	if RunService:IsServer() then
		if to then
			ReplicatedStorage.Shared.RoundRule.Remotes.SendMessage:FireClient(to, message, kind, from)
		else
			ReplicatedStorage.Shared.RoundRule.Remotes.SendMessage:FireAllClients(message, kind, from)
		end
		return
	end

	local ShowMessage = require(ReplicatedStorage.Shared.Interface.Util.ShowMessage)
	ShowMessage(message, kind)
end

return ShowMessage