local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetParticipant = require(ReplicatedStorage.API.GetParticipant)
local Server = require(ReplicatedStorage.API.Item.Behaviour.Server)

ReplicatedStorage.Remotes.ClientServer.Konami.OnServerEvent:Connect(function(player)
	local participant = GetParticipant(player)
	if not participant then
		return
	end

	local char = participant:GetCharacter()
	if not char then
		return
	end

	local root = char.PrimaryPart
	if not root then
		return
	end

	Server.CreateExplosion(participant.Round, {
		Kind = "ExplosionParams",
		Definition = {
			Damage = 0,
			FalloffEnd = 1,
			FalloffStart = 0,
			Pressure = 0,
			VisualRadius = 15,
		},
		Position = root.Position,
	})

	participant:TryTakeDamage({
		Amount = math.huge,
		Source = "Magic",
	})
end)

return nil