local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetParticipant = require(ReplicatedStorage.API.GetParticipant)
local Notification = require(ReplicatedStorage.API.Notification)
local Plural = require(ReplicatedStorage.Shared.Grammar.Plural)
local IsBadNumber = require(ReplicatedStorage.Shared.Util.IsBadNumber)

ReplicatedStorage.Remotes.ClientServer.TransferCredits.OnServerEvent:Connect(function(player, toName: unknown, amount: unknown): ()
	if typeof(toName) ~= "string" or typeof(amount) ~= "number" or IsBadNumber(amount) then
		return
	end

	if amount ~= math.floor(amount) or amount < 0 then
		return
	end

	local from = GetParticipant(player)
	if not from then
		return
	end

	if not from:IsAlive() then
		return
	end

	if from:GetCredits() < amount then
		return
	end

	local to = GetParticipant(toName)
	if not to then
		return
	end

	if from == to then
		return
	end

	if not to:IsAlive() then
		return
	end

	if not from:IsAlliedWithParticipant(to) then
		return
	end

	from:AddCredits(-amount)
	to:AddCredits(amount)

	Notification(`Successfully transferred {amount} {Plural(amount, "credit", "credits")} to [PLAYER-{toName}].`, "Team", player)
	Notification(`You have received {amount} {Plural(amount, "credit", "credits")} from [PLAYER-{player.Name}].`, "Team", to.Player)
end)

return nil