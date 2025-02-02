local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatTypes = require(ReplicatedStorage.CombatTypes)
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

local function isShot(value: any): boolean
	if typeof(value) ~= "table" then
		return false
	end

	if typeof(value.Destination) ~= "Vector3" then
		return false
	end

	if value.HitPart ~= nil and typeof(value.HitPart) ~= "Instance" then
		return false
	end

	if value.HitPartCenterPosition ~= nil and typeof(value.HitPartCenterPosition) ~= "Vector3" then
		return false
	end

	return true
end

local function isPrimaryFireRequest(value: any): boolean
	if typeof(value) ~= "table" then
		return false
	end

	if typeof(value.Origin) ~= "Vector3" then
		return false
	end

	if typeof(value.ItemName) ~= "string" then
		return false
	end

	if typeof(value.Shots) ~= "table" then
		return false
	end

	for i, v in ipairs(value.Shots) do
		if not isShot(v) then
			return false
		end
	end

	return true
end

ReplicatedStorage.ClientServer.PrimaryFire.OnServerInvoke = function(plr, request: CombatTypes.PrimaryFireRequest): CombatTypes.ValidateItemUsageResult
	if not isPrimaryFireRequest(request) then
		return "OtherError"
	end

	local participant = RoundHandler.GetRound():GetParticipant(plr.Name)
	if not participant then
		print("participant not found")
		return "Dead"
	end

	local result = Combat.PrimaryFire(participant, request)
	return result :: CombatTypes.ValidateItemUsageResult
end