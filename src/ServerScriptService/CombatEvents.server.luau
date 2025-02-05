local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatTypes = require(ReplicatedStorage.CombatTypes)
local Types = require(ReplicatedStorage.RoundRule.Types)
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

local function finishReloading(plr: Player, item: Types.GunWeapon): ()
	item.IsReloading = false
	ReplicatedStorage.ClientServer.ReloadWeapon:FireClient(plr, item.Definition.Name, item.Ammo)
end

ReplicatedStorage.ClientServer.ReloadWeapon.OnServerEvent:Connect(function(plr, itemName: unknown): ()
	if typeof(itemName) ~= "string" then
		return
	end

	local participant = RoundHandler.GetRound():GetParticipant(plr.Name)
	if not participant then
		return
	end

	local item = participant:GetEquippedItem()
	if not item or item.Definition.Name ~= itemName or item.Kind ~= "Gun" or item.Definition.Kind ~= "Gun" then
		return
	end

	if item.IsReloading then
		return
	end

	if item.Ammo >= item.Definition.AmmoType.Capacity then
		return
	end

	-- take care: we shouldn't store the GetAmmo result, as the player may pick up more ammo whilst reloading

	local ammoKind = item.Definition.AmmoType.Name
	if participant:GetAmmo(ammoKind) <= 0 then
		return
	end

	item.IsReloading = true

	local endTime = workspace:GetServerTimeNow() + item.Definition.ReloadTime
	while workspace:GetServerTimeNow() < endTime do
		if participant:GetEquippedItem() ~= item then
			finishReloading(plr, item)
			return
		end
		task.wait()
	end

	local diff = math.clamp(participant:GetAmmo(ammoKind), 0, item.Definition.AmmoType.Capacity - item.Ammo)
	participant:SetAmmo(ammoKind, participant:GetAmmo(ammoKind) - diff)
	item.Ammo += diff

	finishReloading(plr, item)
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

	if typeof(value.Shots) ~= "table" or #value.Shots < 1 then
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
		return "Dead"
	end

	local result = Combat.PrimaryFire(participant, request)
	return result :: CombatTypes.ValidateItemUsageResult
end