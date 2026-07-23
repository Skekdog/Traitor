local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Defaults = require(ReplicatedStorage.Shared.RoundRule.Defaults)
local Types = require(ReplicatedStorage.API.Types)
local DynamicValue = require(ReplicatedStorage.Shared.Util.DynamicValue)

local localPlayerName = Players.LocalPlayer.Name

local module = {}

export type LocalParticipant = {
    Name: string,
    Role: DynamicValue.DynamicValue<Types.Role>,
    Status: DynamicValue.DynamicValue<Types.ParticipantStatus | "Spectating">,
    Corpse: DynamicValue.DynamicValue<Types.ClientCorpseView?>,
}

module.Participants = DynamicValue.new({} :: {[string]: LocalParticipant})

local function getOrCreateParticipantValue(name: string): LocalParticipant
    local value = module.Participants()[name]
	if not value then
		value = {
			Name = name,
			Role = DynamicValue.new(Defaults.Role),
			Status = DynamicValue.new("Spectating" :: any),
			Corpse = DynamicValue.new(nil :: Types.ClientCorpseView?),
		}

		local player = Players:FindFirstChild(name)
		if player then
			module.Participants()[name] = value
			module.Participants:Invoke()
		end
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

return table.freeze(module)