local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Types = require(script.Parent.Types)

local function ShowMessage(message: string, kind: Types.MessageKind, to: Player?): ()
	if RunService:IsServer() then
		if to then
			ReplicatedStorage.Shared.RoundRule.Remotes.SendMessage:FireClient(to, message, kind)
		else
			ReplicatedStorage.Shared.RoundRule.Remotes.SendMessage:FireAllClients(message, kind)
		end
		return
	end

	local ShowMessage = require(ReplicatedStorage.Shared.Interface.Util.ShowMessage)
	ShowMessage(message, kind)
end

return ShowMessage