local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Combat = require(script.Parent.Combat)
local RoundHandler = require(script.Parent.RoundHandler)

ReplicatedStorage.ClientServer.PrimaryFire.OnServerEvent:Connect(function(plr, ownPosition: unknown, targetPosition: unknown, hitPart: unknown, itemName: unknown)
	if typeof(ownPosition) ~= "Vector3" or typeof(targetPosition) ~= "Vector3" then
		return print("invalid position args")
	end

	if hitPart and (typeof(hitPart) ~= "Instance" or not hitPart:IsA("BasePart")) then
		return print("invalid hitpart arg")
	end

	if typeof(itemName) ~= "string" then
		return print("invalid itemname arg")
	end

	local participant = RoundHandler.GetRound():GetParticipant(plr.Name)
	if not participant then
		return print("participant not found")
	end

	local item = participant:GetEquippedItem()
	if not item or item.Definition.Name ~= itemName then
		return print("invalid item")
	end

	print(Combat.PrimaryFire(participant, item, ownPosition, targetPosition, hitPart))
end)