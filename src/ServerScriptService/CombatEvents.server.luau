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

ReplicatedStorage.ClientServer.DropWeapon.OnServerEvent:Connect(function(plr, itemName: unknown)
	if typeof(itemName) ~= "string" then
		return
	end

	local participant = RoundHandler.GetRound():GetParticipant(plr.Name)
	if not participant then
		return
	end

	local item = participant:GetItems()[itemName]
	if not item or not item.Definition.Slot then
		return
	end

	participant:DropItem(item, true)
end)

ReplicatedStorage.ClientServer.PrimaryFire.OnServerInvoke = function(plr, ownPosition: unknown, targetPosition: unknown, hitPart: unknown, hitPartCenterPosition: unknown, itemName: unknown): Combat.ValidateItemUsageResult
	if typeof(ownPosition) ~= "Vector3" or typeof(targetPosition) ~= "Vector3" then
		print("invalid position args")
		return "OtherError"
	end

	if typeof(itemName) ~= "string" then
		print("invalid itemname arg")
		return "OtherError"
	end

	if hitPartCenterPosition and typeof(hitPartCenterPosition) ~= "Vector3" then
		print("invalid hitpartcenterposition arg")
		return "OtherError"
	end

	if hitPart and (typeof(hitPart) ~= "Instance" or not hitPart:IsA("BasePart")) then
		print("invalid hitpart arg")
		return "OtherError"
	end

	if (hitPartCenterPosition and not hitPart) or (not hitPartCenterPosition and hitPart) then
		print("invalid hitpart and hitpartcenterposition args")
		return "OtherError"
	end

	local participant = RoundHandler.GetRound():GetParticipant(plr.Name)
	if not participant then
		print("participant not found")
		return "OtherError"
	end

	local item = participant:GetEquippedItem()
	if not item or item.Definition.Name ~= itemName then
		print(item, itemName)
		print("invalid item")
		return "NotEquipped"
	end

	local result: Combat.ValidateItemUsageResult = Combat.PrimaryFire(participant, item, ownPosition, targetPosition, hitPart, hitPartCenterPosition)
	print(result)
	return result
end