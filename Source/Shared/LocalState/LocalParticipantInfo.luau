local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local Defaults = require(ReplicatedStorage.Shared.RoundRule.Defaults)
local Role = require(ReplicatedStorage.Shared.RoundRule.Role)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local DynamicValue = require(ReplicatedStorage.Shared.Util.DynamicValue)

local localPlayerName = Players.LocalPlayer.Name

local module = {}

local remotes = ReplicatedStorage.Shared.RoundRule.Remotes

export type LocalParticipant = {
    Name: string,
    Role: DynamicValue.DynamicValue<Types.Role>,
    Status: DynamicValue.DynamicValue<Types.ParticipantStatus | "Spectating">,
    Corpse: DynamicValue.DynamicValue<Types.CorpseView?>,
}

local function getRoleFromName(name: string?): Types.Role
    if not name or name == "" then
        return Defaults.Role
    end

	local gamemode = LocalRoundInfo.Gamemode() or LocalRoundInfo.Gamemode:Wait() -- this may have unforseen consequences, test it
    assert(gamemode, "Gamemode is not loaded")
    return Role.fromDefinition(gamemode.Roles[name] or error("Role not found"))
end

module.Participants = DynamicValue.new({} :: {[string]: LocalParticipant})

local function getOrCreateParticipantValue(name: string): LocalParticipant
    local value = module.Participants()[name]
	if not value then
		value = {
			Name = name,
			Role = DynamicValue.new(Defaults.Role),
			Status = DynamicValue.new("Spectating" :: any),
			Corpse = DynamicValue.new(nil :: Types.CorpseView?),
		}

		module.Participants()[name] = value
		module.Participants:Invoke()
	end

	return value
end

Players.PlayerAdded:Connect(function(plr: Player): ()
	getOrCreateParticipantValue(plr.Name)
end)

function module.GetParticipant(name: string?): LocalParticipant
    name = name or localPlayerName
    assert(name)
    return module.Participants()[name] or getOrCreateParticipantValue(name)
end

remotes.UpdatePlayerStatus.OnClientEvent:Connect(function(name: string, status: Types.ParticipantStatus?)
	local participant = module.GetParticipant(name)
    participant.Status:SetValue(status or "Spectating")
end)

remotes.UpdatePlayerRole.OnClientEvent:Connect(function(name: string, roleName: string?)
	local participant = module.GetParticipant(name)
	participant.Role:SetValue(getRoleFromName(roleName))
end)

remotes.UpdatePlayerCorpse.OnClientEvent:Connect(function(corpse: Types.CorpseView, covert: boolean)
    if covert then
        return
    end

	local participant = module.GetParticipant(corpse.Name)
	participant.Corpse:SetValue(corpse)
end)

remotes.Reset.OnClientEvent:Connect(function()
	local participants = module.Participants()
	for name, v in participants do
		if not Players:FindFirstChild(name) then
			participants[name] = nil
			continue
		end

		v.Role:SetValue(Defaults.Role)
		v.Status:SetValue("Spectating")
		v.Corpse:SetValue(nil)
	end
	module.Participants:Invoke()
end)

return module