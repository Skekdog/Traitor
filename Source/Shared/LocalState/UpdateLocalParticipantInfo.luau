local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)
local Defaults = require(ReplicatedStorage.Shared.RoundRule.Defaults)
local Role = require(ReplicatedStorage.Shared.RoundRule.Role)
local LocalParticipantInfo = require(script.Parent.LocalParticipantInfo)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)

local remotes = ReplicatedStorage.Shared.RoundRule.Remotes

local function getRoleFromName(name: string?): Types.Role
    if not name or name == "" then
        return Defaults.Role
    end

	local gamemode = LocalRoundInfo.Gamemode() or LocalRoundInfo.Gamemode:Wait() -- this may have unforseen consequences, test it
    assert(gamemode, "Gamemode is not loaded")
    return Role.fromDefinition(gamemode.Roles[name] or error("Role not found"))
end

remotes.UpdatePlayerStatus.OnClientEvent:Connect(function(name: string, status: Types.ParticipantStatus?)
	local participant = LocalParticipantInfo.GetParticipant(name)
    participant.Status:SetValue(status or "Spectating")
end)

remotes.UpdatePlayerRole.OnClientEvent:Connect(function(name: string, roleName: string?)
	local participant = LocalParticipantInfo.GetParticipant(name)
	participant.Role:SetValue(getRoleFromName(roleName))
end)

remotes.UpdatePlayerCorpse.OnClientEvent:Connect(function(corpse: Types.ClientCorpseView | string, covert: boolean)
    if covert then
        return
    end

	if typeof(corpse) == "table" then
		local participant = LocalParticipantInfo.GetParticipant(corpse.Name)
		participant.Corpse:SetValue(corpse)
		return
	end

	local participant = LocalParticipantInfo.GetParticipant(corpse)
	participant.Corpse:SetValue()
end)

remotes.Reset.OnClientEvent:Connect(function()
	local participants = LocalParticipantInfo.Participants()
	for name, v in participants do
		if not Players:FindFirstChild(name) then
			participants[name] = nil
			continue
		end

		v.Role:SetValue(Defaults.Role)
		v.Status:SetValue("Spectating")
		v.Corpse:SetValue(nil)
	end
	LocalParticipantInfo.Participants:Invoke()
end)

return nil