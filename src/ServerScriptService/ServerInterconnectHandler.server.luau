local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RoundHandler = require(script.Parent.Parent.ReplicatedFirst.RoundHandler.RoundHandler)
local Types = require(script.Parent.Parent.ReplicatedFirst.RoundHandler.Types)
local WeaponsManager = require(script.Parent.WeaponsManager)

local si = ReplicatedStorage.ServerInterconnect
si.ExplosiveBarrel.Event:Connect(function(part: BasePart, participant: Types.ClientOwnParticipant?)
	local roundId = ServerStorage:GetAttribute("RoundID")
	if not roundId then
		return
	end

	local plr
	if participant then
		plr = RoundHandler.GetRound(roundId):GetParticipant(participant.Player.Name)
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