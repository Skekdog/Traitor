local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local ScreenMessage = require(ReplicatedStorage.API.ScreenMessage)
local GetCentreRay = require(ReplicatedStorage.Shared.Camera.GetCentreRay)
local LocalAnimation = require(ReplicatedStorage.Shared.Character.LocalAnimation)
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local RoundInfoUI = require(ReplicatedStorage.Shared.Interface.GameState.RoundInfoUI)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local ClientInventory = require(ReplicatedStorage.Shared.LocalState.ClientInventory)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local Aim = require(script.Parent.Aim)
local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local Settings = require(ReplicatedStorage.Shared.Settings.Settings)
local DynamicValue = require(ReplicatedStorage.Shared.Util.DynamicValue)
local Viewmodel = require(script.Parent.Viewmodel)

local remote = GetRemote("ItemFire")

remote.OnClientEvent:Connect(function(message: string | {string}): ()
	local result: {string}
	if typeof(message) == "string" then
		result = {message}
	else
		result = message
	end

	for _, msg in result do
		warn("Hit rejected:", message)
		if Settings.GetSetting("Show Hit Rejects") then
			ScreenMessage("Hit rejected: " .. msg, "Warn")
		end
	end
end)

local function playEmptyClipSound(): ()
	PlaySound(ReplicatedStorage.Assets.ItemSounds.EmptyClip, nil, nil, {SoundGroup = SoundService.AllSounds :: SoundGroup})
end

local crosshair = UIManager.WaitForUI("Crosshair") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Crosshair)}

local crosshairFrames: {Frame} = {}

for _, v in crosshair.Object:GetChildren() do
	if v:IsA("Frame") then
		table.insert(crosshairFrames, v)
	end
end

local function tryReloadWeapon(item: Types.Item): boolean
	local ammoDefinition = item.AmmoDefinition
	if not ammoDefinition then
		return false
	end

	if item.Ammo >= ammoDefinition.Capacity or item.IsReloading then
		return false
	end

	local reserve = ClientInventory.GetReserveAmmo(ammoDefinition.Name)
	if reserve <= 0 then
		return false
	end

	item.IsReloading = true

	Viewmodel.ReloadSpring.p = Vector3.new(10, 5, 10)

	if item.ReloadSound then
		PlaySound(item.ReloadSound)
	end

	ReplicatedStorage.Remotes.ClientServer.ReloadWeapon:FireServer(item.Name)

	return true
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
				break
			end
		end

		local interval = if isPrimary then item.PrimaryInterval else item.AlternateInterval
		if interval then
			local lastUse = if isPrimary then item.PrimaryLastUse else item.AlternateLastUse
			if (lastUse or 0) + interval > os.clock() then
				continue
			end
			if isPrimary then
				item.PrimaryLastUse = os.clock()
			else
				item.AlternateLastUse = os.clock()
			end
		end

		if isPrimary and item.UseAttack then
			if item.IsReloading then
				continue
			end

			if item.Ammo and item.Ammo <= 0 then
				if not tryReloadWeapon(item) then
					playEmptyClipSound()
				end
				continue
			end
		end

		if isPrimary and item.PrimaryAnimation then
			LocalAnimation.TryPlayAnimation(item.PrimaryAnimation, "Primary")
		elseif not isPrimary and item.AlternateAnimation then
			LocalAnimation.TryPlayAnimation(item.AlternateAnimation, "Alternate")
		end

		local sound = if isPrimary then item.PrimarySound else item.AlternateSound
		if sound then
			PlaySound(sound)
		end

		local head = char:WaitForChild("Head")
		assert(head and head:IsA("BasePart"), "HumanoidRootPart is not a BasePart")

		local origin = head.Position
		local direction = GetCentreRay().Direction

		if isPrimary then
			print("pre client")
			if item.PrimaryFireClient then
				print("in client")
				item.PrimaryFireClient(item, origin, direction)
			end
			print("post client")
			if item.PrimaryFireServer then
				print("in server")
				remote:FireServer(item.Name, "Primary", origin, direction, item:GetServerData("Primary"))
			end
			print("post server")
		else
			if item.AlternateFireClient then
				item.AlternateFireClient(item, origin, direction)
			end

			if item.AlternateFireServer then
				remote:FireServer(item.Name, "Alternate", origin, direction, item:GetServerData("Alternate"))
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

	if item.IsAimable and not item.AlternateFireClient and not item.AlternateFireServer then
		ControlManager.Register("Alternate Fire", function(_, state)
			if state ~= Enum.UserInputState.End then
				return Enum.ContextActionResult.Pass
			end

			Aim.ToggleAim(item)
			return Enum.ContextActionResult.Pass
		end)
	end

	if item.AmmoDefinition and item.AmmoDefinition.Capacity ~= math.huge and item.AmmoDefinition.ReserveCapacity ~= 0 then
		ControlManager.Register("Reload Weapon", function(_, state)
			if state ~= Enum.UserInputState.End then
				return Enum.ContextActionResult.Pass
			end

			return if tryReloadWeapon(item) then Enum.ContextActionResult.Pass else Enum.ContextActionResult.Pass
		end)
	end

	if not item.IsAimable and item.AlternateFireClient or item.AlternateFireServer then
		ControlManager.Register("Alternate Fire", function(_, _, input)
			action(item, false, input)
			return Enum.ContextActionResult.Pass
		end)
	end

	if item.PrimaryFireClient or item.PrimaryFireServer or item.UseAttack then
		ControlManager.Register("Primary Fire", function(_, _, input)
			action(item, true, input)
			return Enum.ContextActionResult.Pass
		end)
	end
end)

return nil