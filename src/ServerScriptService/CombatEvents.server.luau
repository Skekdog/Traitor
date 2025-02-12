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

ReplicatedStorage.ClientServer.DropWeapon.OnServerEvent:Connect(function(plr, itemName: unknown, direction: unknown): ()
	if typeof(itemName) ~= "string" then
		return
	end

	if typeof(direction) ~= "Vector3" then
		return
	end

	if direction.Magnitude > 1.1 then
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

	participant:DropItem(item, direction)
end)

local function isPrimaryFireBaseRequest(value: any): boolean
	if typeof(value) ~= "table" then
		return false
	end

	if typeof(value.Origin) ~= "Vector3" then
		return false
	end

	if typeof(value.ItemName) ~= "string" then
		return false
	end

	return true
end

local function isAlternateFireBaseRequest(value: any): boolean
	return isPrimaryFireBaseRequest(value)
end

local function isRaycastInfo(value: any): boolean
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

	if value.Normal ~= nil and typeof(value.Normal) ~= "Vector3" then
		return false
	end

	return true
end

local function isThrow(value: any): boolean
	if typeof(value) ~= "Vector3" then
		return false
	end

	if value.Magnitude > 1.1 then
		return false
	end

	return true
end

local function isRaycastRequest(value: any): boolean
	if value.Kind ~= "PrimaryFireRaycastRequest" then
		return false
	end

	if typeof(value) ~= "table" then
		return false
	end

	if typeof(value.Origin) ~= "Vector3" then
		return false
	end

	if typeof(value.ItemName) ~= "string" then
		return false
	end

	if typeof(value.Raycasts) ~= "table" or #value.Raycasts < 1 then
		return false
	end

	for i, v in ipairs(value.Raycasts) do
		if not isRaycastInfo(v) then
			return false
		end
	end

	return true
end

local function isPrimaryFireRequest(value: any): boolean
	if not isPrimaryFireBaseRequest(value) then
		return false
	end
	
	if value.Kind == "PrimaryFireRaycastRequest" then
		return isRaycastRequest(value)
	elseif value.Kind == "PrimaryFireThrowRequest" then
		return isThrow(value.Direction)
	elseif value.Kind == "PrimaryFireItemRequest" then
		return isThrow(value.Direction)
	else
		return false
	end
end

local function isAlternateFireRequest(value: any): boolean
	if not isAlternateFireBaseRequest(value) then
		return false
	end

	if value.Kind == "AlternateFireItemRequest" then
		return isThrow(value.Direction)
	else
		return false
	end
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

ReplicatedStorage.ClientServer.AlternateFire.OnServerInvoke = function(plr, request: CombatTypes.AlternateFireRequest): CombatTypes.ValidateItemUsageResult
	if not isAlternateFireRequest(request) then
		return "OtherError"
	end

	local participant = RoundHandler.GetRound():GetParticipant(plr.Name)
	if not participant then
		return "Dead"
	end

	local result = Combat.AlternateFire(participant, request)
	return result :: CombatTypes.ValidateItemUsageResult
end

ReplicatedStorage.ClientServer.DropAmmo.OnServerEvent:Connect(function(plr, itemName: unknown, direction: unknown): ()
	if typeof(itemName) ~= "string" then
		return
	end

	if typeof(direction) ~= "Vector3" then
		return
	end

	if direction.Magnitude > 1.1 then
		return
	end

	local round = RoundHandler.GetRound()

	local participant = round:GetParticipant(plr.Name)
	if not participant then
		return
	end

	local item = participant:GetItems()[itemName]
	if not item then
		return
	end

	if item.Kind ~= "Gun" or not item.Definition.AmmoType.CanDrop then
		return
	end

	if item.Ammo < item.Definition.AmmoType.Capacity / 4 then
		return
	end

	local char = participant:GetCharacter()
	if not char then
		return
	end

	local head = char:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return
	end

	local amount = item.Ammo
	local model = item.Definition.AmmoType.Model:Clone()

	if not participant:TryThrowAssembly(model, 15, round:GetMap().AmmoSpawns, nil, direction) then
		return
	end

	item.Ammo = 0
	ReplicatedStorage.ServerClient.UpdateAmmo:FireClient(plr, item.Definition.Name, 0)

	round:LoadAmmoBox(round:GetMap(), model, amount)
end)
