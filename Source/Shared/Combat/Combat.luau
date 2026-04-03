local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local Message = require(ReplicatedStorage.API.Interface.Message)
local Client = require(ReplicatedStorage.API.Item.Behaviour.Client)
local GetCentreRay = require(ReplicatedStorage.Shared.Camera.GetCentreRay)
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local RoundInfoUI = require(ReplicatedStorage.Shared.Interface.GameState.RoundInfoUI)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local ClientInventory = require(ReplicatedStorage.Shared.LocalState.ClientInventory)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local Aim = require(script.Parent.Aim)
local Types = require(ReplicatedStorage.API.Types)
local Settings = require(ReplicatedStorage.Shared.Settings.Settings)
local DynamicValue = require(ReplicatedStorage.Shared.Util.DynamicValue)

local remote = GetRemote("ItemFire")

local function logReject(message: string | {string}): ()
	local result: {string}
	if typeof(message) == "string" then
		result = {message}
	else
		result = message
	end

	for _, msg in result do
		warn("Hit rejected:", msg)
		if Settings.GetSetting("Show Hit Rejects") then
			Message.Screen("Hit rejected: " .. msg, "Warn")
		end
	end
end

remote.OnClientEvent:Connect(logReject)

local crosshair = UIManager.WaitForUI("Crosshair") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Crosshair)}

local crosshairFrames: {Frame} = {}

for _, v in crosshair.Object:GetChildren() do
	if v:IsA("Frame") then
		table.insert(crosshairFrames, v)
	end
end

local lastAmmoConnection: DynamicValue.Connection<typeof(ClientInventory.Ammo:GetValue())>?

local function updateCrosshair(isAiming: boolean): ()
	local item = ClientInventory.EquippedItem()

	if not LocalCharacter.Character() or item and isAiming and item.IsScopable then
		return crosshair:ToggleVisible(false)
	end

	crosshair:ToggleVisible(true)

	local spread = if item and item.Spread then item.Spread * 2000 * (if isAiming then item.AimSpreadMultiplier or 1 else 1) else 0

	local value = math.max(24 + (math.round(spread / 2) * 2), 36)
	for _, v in crosshairFrames do
		v.Size = UDim2.fromOffset(value, value)
	end
end

LocalCharacter.Character:Connect(function()
	updateCrosshair(Aim.IsAiming())
end, true)

Aim.IsAiming:Connect(function(isAiming)
	updateCrosshair(isAiming)
end)

local function action(item: Types.Item, isPrimary: boolean, input: InputObject): ()
	if isPrimary and item.PrimaryActivatedClient then
		item.PrimaryActivatedClient(item)
	elseif not isPrimary and item.AlternateActivatedClient then
		item.AlternateActivatedClient(item)
	end

	local char = LocalCharacter.Character()
	if not char then
		return
	end

	local stop = false

	while
		not stop and
		not (if isPrimary then item.PrimaryDisabled else item.AlternateDisabled) and
		input.UserInputState ~= Enum.UserInputState.Cancel and
		ClientInventory.EquippedItem() == item and
		if
			(if isPrimary then item.PrimaryToggled else item.AlternateToggled) then
				input.UserInputState == Enum.UserInputState.End
			else
				input.UserInputState ~= Enum.UserInputState.End
	do
		task.wait()

		if ClientInventory.EquippedItem() ~= item then
			break
		end

		if item.PregameDisable then
			local phase = LocalRoundInfo.Phase() :: Types.Phase
			if phase == "Preparing" or phase == "Intermission" then
				continue
			end
		end

		local centre = GetCentreRay()
		local origin = centre.Origin
		local direction = centre.Direction

		if isPrimary then
			if item.PrimaryFireClient then
				local result = item.PrimaryFireClient(item, origin, direction)
				if result ~= true then
					if typeof(result) == "string" then
						logReject(result)
					end
					continue
				end
			end

			if item.PrimaryFireServer then
				Client.ServerFire("Primary", item, origin, direction)
			end
		else
			if item.AlternateFireClient then
				local result = item.AlternateFireClient(item, origin, direction)
				if result ~= true then
					if typeof(result) == "string" then
						logReject(result)
					end
					continue
				end
			end

			if item.AlternateFireServer then
				Client.ServerFire("Alternate", item, origin, direction)
			end
		end

		if item.IsSingleUse then
			break
		end

		if isPrimary and item.PrimaryToggled or not isPrimary and item.AlternateToggled then
			break
		end
	end

	if isPrimary and item.PrimaryDeactivatedClient then
		item.PrimaryDeactivatedClient(item)
	elseif not isPrimary and item.AlternateDeactivatedClient then
		item.AlternateDeactivatedClient(item)
	end
end

ClientInventory.EquippedItem:Connect(function(item): ()
	updateCrosshair(false)

	Aim.ToggleAim(item, false)

	RoundInfoUI.UpdateAmmo()

	if lastAmmoConnection then
		lastAmmoConnection:Disconnect()
	end

	local char = LocalCharacter.Character()
	if not item or not char then
		ControlManager.Unregister("Primary Fire")
		ControlManager.Unregister("Reload Weapon")
		ControlManager.Unregister("Alternate Fire")
		return
	end

	lastAmmoConnection = ClientInventory.Ammo:Connect(RoundInfoUI.UpdateAmmo)

	if item.AmmoDefinition and item.AmmoDefinition.Capacity ~= math.huge and item.AmmoDefinition.ReserveCapacity ~= 0 then
		ControlManager.Register("Reload Weapon", function(_, state)
			if state ~= Enum.UserInputState.End then
				return Enum.ContextActionResult.Pass
			end

			Client.TryReloadWeapon(item)

			return Enum.ContextActionResult.Pass
		end)
	end

	if item.AlternateFireClient or item.AlternateFireServer then
		ControlManager.Register("Alternate Fire", function(_, _, input)
			action(item, false, input)
			return Enum.ContextActionResult.Pass
		end)
	end

	if item.PrimaryFireClient or item.PrimaryFireServer then
		ControlManager.Register("Primary Fire", function(_, _, input)
			action(item, true, input)
			return Enum.ContextActionResult.Pass
		end)
	end
end)

return nil