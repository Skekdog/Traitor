local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetRound = require(script.Parent.GetRound)
local Types = require(ReplicatedFirst.RoundHandler.Types)
local WeaponsManager = require(script.Parent.WeaponsManager)

local si = ReplicatedStorage.ServerInterconnect
si.ExplosiveBarrel.Event:Connect(function(part: BasePart, participant: Types.ClientOwnParticipant?)
	local plr
	if participant then
		local round = GetRound()
		if round then
			plr = round:GetParticipant(participant.Player.Name)
		end
	end
	if part then
		WeaponsManager.CreateExplosion(part.Position, {
			Kind = "Explosion",
			Radius = 25,
			Pressure = 50,
			Damage = 150,
		}, plr)
	end
end)