local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RoundHandler = require(script.Parent.Parent.ReplicatedFirst.RoundHandler.RoundHandler)
local WeaponsManager = require(script.Parent.Parent.ReplicatedFirst.WeaponsManager)

local si = ReplicatedStorage.ServerInterconnect
si.ExplosiveBarrel.Event:Connect(function(part: BasePart, plr: Player?)
	local roundId = ServerStorage:GetAttribute("RoundID")
	if not roundId then
		return
	end

	local participant
	if plr then
		participant = RoundHandler.GetRound(roundId):GetParticipant(plr.Name)
	end
	if part then
		WeaponsManager.CreateExplosion(part.Position, {
			Kind = "Explosion",
			Radius = 25,
			Pressure = 50,
			Damage = 150,
		}, participant)
	end
end)