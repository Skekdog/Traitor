local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameHooks = require(ReplicatedStorage.API.GameHooks)
local Types = require(ReplicatedStorage.API.Types)
local ClientInventory = require(ReplicatedStorage.Shared.LocalState.ClientInventory)

local FIRST_UNEQUIP_COUNT = 3
local NEXT_UNEQUIP_COUNT = 4

local CROUCH_COUNT = 3

local unequipCount = 0
local crouchCount = 0
local nextPhase = false

local function reset(): ()
	unequipCount = 0
	crouchCount = 0
	nextPhase = false
end

local function detonate(): ()
	reset()
	ReplicatedStorage.Remotes.ClientServer.Konami:FireServer()
end

local lastItem: Types.Item?
ClientInventory.EquippedItem:Connect(function(item: Types.Item?)
	if item then
		lastItem = item
		return
	end

	if not lastItem then
		return
	end

	if lastItem.Name == "Crowbar" then
		unequipCount += 1
	else
		unequipCount = 0
		return
	end

	if not nextPhase or unequipCount ~= NEXT_UNEQUIP_COUNT or crouchCount ~= CROUCH_COUNT then
		return
	end

	task.delay(3, function()
		if nextPhase and unequipCount == NEXT_UNEQUIP_COUNT and crouchCount == CROUCH_COUNT then
			detonate()
		else
			reset()
		end
	end)
end)

GameHooks.OnCrouch["Konami"] = function(isCrouching): ()
	if isCrouching then
		return
	end

	if unequipCount ~= FIRST_UNEQUIP_COUNT or nextPhase then
		crouchCount = 0
		return
	end

	crouchCount += 1

	nextPhase = crouchCount == CROUCH_COUNT

	if nextPhase then
		unequipCount = 0
	end
end

return nil