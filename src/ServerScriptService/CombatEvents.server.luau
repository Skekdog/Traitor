local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Combat = require(script.Parent.Combat)
local RoundHandler = require(script.Parent.RoundHandler)

ReplicatedStorage.ClientServer.EquipItem.OnServerEvent:Connect(function(plr, itemName: unknown)
	if itemName and typeof(itemName) ~= "string" then
		return
	end

	local participant = RoundHandler.GetRound():GetParticipant(plr.Name)
	if not participant then
		return
	end

	if not itemName then
		return participant:SetEquippedItem()
	end

	local item = participant:GetItems()[itemName]
	if not item then
		return participant:SetEquippedItem()
	end

	participant:SetEquippedItem(item)
end)

ReplicatedStorage.ClientServer.PrimaryFire.OnServerEvent:Connect(function(plr, ownPosition: unknown, targetPosition: unknown, hitPart: unknown, hitPartCenterPosition: unknown, itemName: unknown)
	if typeof(ownPosition) ~= "Vector3" or typeof(targetPosition) ~= "Vector3" then
		return print("invalid position args")
	end

	if typeof(itemName) ~= "string" then
		return print("invalid itemname arg")
	end

	if hitPartCenterPosition and typeof(hitPartCenterPosition) ~= "Vector3" then
		return print("invalid hitpartcenterposition arg")
	end

	if hitPart and (typeof(hitPart) ~= "Instance" or not hitPart:IsA("BasePart")) then
		return print("invalid hitpart arg")
	end

	if (hitPartCenterPosition and not hitPart) or (not hitPartCenterPosition and hitPart) then
		return print("invalid hitpart and hitpartcenterposition args")
	end

	local participant = RoundHandler.GetRound():GetParticipant(plr.Name)
	if not participant then
		return print("participant not found")
	end

	local item = participant:GetEquippedItem()
	if not item or item.Definition.Name ~= itemName then
		print(item, itemName)
		return print("invalid item")
	end

	print(Combat.PrimaryFire(participant, item, ownPosition, targetPosition, hitPart, hitPartCenterPosition))
end)