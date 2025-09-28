local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
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
local CombatTypes = require(script.Parent.CombatTypes)
local HitSounds = require(script.Parent.HitSounds)
local ViewmodelModule = require(script.Parent.ViewmodelModule)

local MAX_RANGE = 10000

local function deriveTargetPosition(origin: Vector3, spread: Vector3, range: number): Vector3
	return origin + (GetCentreRay().Direction + spread).Unit * range
end

local random = Random.new(workspace:GetServerTimeNow())
local function getSpreadVector(item: Types.AnyItem): Vector3
	if item.Kind ~= "Gun" then
		return Vector3.zero
	end

	local spread = item.Definition.Spread * (if Aim.IsAiming() then item.Definition.AimSpreadMultiplier or 1 else 1)
	return Vector3.new(random:NextNumber(-spread, spread), random:NextNumber(-spread, spread), random:NextNumber(-spread, spread))
end

local function raycast(char: Model, spread: Vector3, range: number): RaycastResult?
	local map = LocalRoundInfo.Map()
	if not map then
		return
	end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {char}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.CollisionGroup = "WeaponHitTargets"

	return workspace:Raycast(workspace.CurrentCamera.CFrame.Position, (GetCentreRay().Direction + spread).Unit * range, params)
end

local function playEmptyClipSound(): ()
	PlaySound(ReplicatedStorage.Assets.WeaponSounds.EmptyClip, nil, nil, {SoundGroup = SoundService.AllSounds :: SoundGroup})
end

local crosshair = UIManager.WaitForUI("Crosshair") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Crosshair)}

local crosshairFrames: {Frame} = {}

for _, v in crosshair.Object:GetChildren() do
	if v:IsA("Frame") then
		table.insert(crosshairFrames, v)
	end
end

local function tryReloadWeapon(item: Types.GunWeapon): boolean
	local ammoDefinition = item.Definition.AmmoType
	if item.Ammo >= ammoDefinition.Capacity or item.IsReloading then
		return false
	end

	local reserve = ClientInventory.GetReserveAmmo(ammoDefinition.Name)
	if reserve <= 0 then
		return false
	end

	item.IsReloading = true

	ViewmodelModule.ReloadSpring.p = Vector3.new(10, 5, 10)

	if item.Definition.ReloadSound then
		PlaySound(item.Definition.ReloadSound, nil, nil, {SoundGroup = SoundService.AllSounds :: SoundGroup})
	end

	ReplicatedStorage.Remotes.ClientServer.ReloadWeapon:FireServer(item.Definition.Name)

	return true
end

local lastAmmoConnection: DynamicValue.Connection<typeof(ClientInventory.Ammo:GetValue())>?

local function updateCrosshair(isAiming: boolean): ()
	local item = ClientInventory.EquippedItem()

	if not LocalCharacter.Character() or item and isAiming and item.Kind == "Gun" and item.Definition.HasScope then
		return crosshair:ToggleVisible(false)
	end

	crosshair:ToggleVisible(true)

	local spread = if item and item.Kind == "Gun" then item.Definition.Spread * 2000 * (if isAiming then item.Definition.AimSpreadMultiplier or 1 else 1) else 0

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

ClientInventory.EquippedItem:Connect(function(item): ()
	updateCrosshair(false)

	Aim.ToggleAim(item, false)

	RoundInfoUI.UpdateAmmo(item)

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

	lastAmmoConnection = ClientInventory.Ammo:Connect(function()
		RoundInfoUI.UpdateAmmo(item)
	end)

	if item.Kind == "Gun" then
		if item.Definition.AimAnimation then
			ControlManager.Register("Alternate Fire", function(_, state)
				if state ~= Enum.UserInputState.End then
					return Enum.ContextActionResult.Pass
				end

				Aim.ToggleAim(item)
				return Enum.ContextActionResult.Sink
			end)
		end

		ControlManager.Register("Reload Weapon", function(_, state)
			if state ~= Enum.UserInputState.End then
				return Enum.ContextActionResult.Pass
			end

			return if tryReloadWeapon(item) then Enum.ContextActionResult.Sink else Enum.ContextActionResult.Pass
		end)
	else
		ControlManager.Unregister("Reload Weapon")
	end

	if (item.Kind == "Item" or item.Kind == "Melee") and (item.Definition.AlternateFireClient or item.Definition.AlternateFireServer) then
		ControlManager.Register("Alternate Fire", function(_, state)
			if item.Definition.AlternateToggled and state ~= Enum.UserInputState.End then
				return Enum.ContextActionResult.Pass
			end

			if item.Kind == "Melee" then
				if item.LastAttackTime + item.Definition.AttackInterval > tick() then
					return Enum.ContextActionResult.Pass
				end
				item.LastAttackTime = tick()

				ViewmodelModule.Recoil(item.Definition)
			end

			local head = char:WaitForChild("Head")
			assert(head and head:IsA("BasePart"), "HumanoidRootPart is not a BasePart")

			local origin = head.Position
			local direction = GetCentreRay().Direction

			local itemRequest: CombatTypes.AlternateFireItemRequest = {
				Kind = "AlternateFireItemRequest" :: "AlternateFireItemRequest",
				ItemName = item.Definition.Name,
				Origin = origin,
				Direction = direction,
			}

			if item.Definition.AlternateFireClient then
				(item.Definition.AlternateFireClient :: Types.FireActionClient)(item :: Types.Item, "Alternate", origin, direction)
			end

			if item.Definition.AlternateFireServer then
				local result: CombatTypes.ValidateItemUsageResult = ReplicatedStorage.Remotes.ClientServer.AlternateFire:InvokeServer(itemRequest)
				if result ~= "Success" then
					warn("Item alternate fire rejected:", result)
				end
			end

			return Enum.ContextActionResult.Sink
		end)
	end

	if (item.Kind == "Item" and (item.Definition.PrimaryFireClient or item.Definition.PrimaryFireServer)) or item.Kind == "Grenade" or item.Kind == "Gun" or item.Kind == "Melee" then
		ControlManager.Register("Primary Fire", function(_, _, input)
			local stop = false
			while not stop and ClientInventory.EquippedItem() == item and (if item.Kind == "Item" and item.Definition.PrimaryToggled then input.UserInputState == Enum.UserInputState.End else input.UserInputState ~= Enum.UserInputState.End) and input.UserInputState ~= Enum.UserInputState.Cancel do
				task.wait()

				if item.Kind == "Item" and item.Definition.PrimaryToggled and input.UserInputState == Enum.UserInputState.End then
					stop = true
				end

				if item.Kind == "Gun" and item.Definition.ScopeRequired and not Aim.IsAiming() then
					playEmptyClipSound()
					return Enum.ContextActionResult.Sink -- note: we return here instead of continuing so that if we aren't scoped in, and later we are, we don't have to wait for the attack interval
				end

				if item.Kind == "Melee" or item.Kind == "Gun" then
					if item.LastAttackTime + item.Definition.AttackInterval > tick() then
						continue
					end
					(item :: Types.GunWeapon).LastAttackTime = tick()
				end

				if item.Kind == "Gun" and item.IsReloading then
					continue
				end

				if item.Kind == "Gun" and item.Ammo <= 0 then
					if not tryReloadWeapon(item) then
						playEmptyClipSound()
					end
					continue
				end

				local head = char:WaitForChild("Head")
				assert(head and head:IsA("BasePart"), "HumanoidRootPart is not a BasePart")

				local origin = head.Position
				local direction = GetCentreRay().Direction

				local request: CombatTypes.PrimaryFireRequest?
				if item.Kind == "Melee" or item.Kind == "Gun" then
					local raycasts: {CombatTypes.RaycastInfo} = {}
					for i = 1, if item.Kind == "Gun" then item.Definition.BulletsPerShot or 1 else 1 do
						local spread = getSpreadVector(item)

						local raycastResult = raycast(assert(head:FindFirstAncestorOfClass("Model")), spread, if item.Kind == "Melee" then item.Definition.MaxDistance else MAX_RANGE)

						local targetPosition = if raycastResult then raycastResult.Position else deriveTargetPosition(origin, spread, if item.Kind == "Melee" then item.Definition.MaxDistance else MAX_RANGE)
						local hitPart = if raycastResult then raycastResult.Instance :: BasePart else nil
						local hitPartCenterPosition = if hitPart then hitPart.Position else nil
						local normal = if raycastResult then raycastResult.Normal else nil
						local relativeHitCFrame = if raycastResult then raycastResult.Instance.CFrame:ToObjectSpace(CFrame.new(targetPosition)) else nil

						if item.Kind == "Melee" and hitPart and not hitPart:IsDescendantOf(workspace.Characters) then
							local materialOverride = hitPart:GetAttribute("MaterialOverride")
							local material = if materialOverride and materialOverride ~= "" then materialOverride else hitPart.Material.Name
							PlaySound(HitSounds[material] or HitSounds.Default, targetPosition or hitPart.Position)
						end

						table.insert(raycasts, {
							Destination = targetPosition,
							HitPart = hitPart,
							HitPartCenterPosition = hitPartCenterPosition,
							Normal = normal,
							RelativeHitCFrame = relativeHitCFrame,
						})
					end

					if item.Kind == "Gun" and item.Definition.BeforePrimaryFireClient then
						local parts: {BasePart} = {}
						for _, v in raycasts do
							if v.HitPart then
								table.insert(parts, v.HitPart)
							end
						end

						if not item.Definition.BeforePrimaryFireClient(item, parts) then
							continue
						end
					end

					local raycastRequest: CombatTypes.PrimaryFireRaycastRequest = {
						Kind = "PrimaryFireRaycastRequest" :: "PrimaryFireRaycastRequest",
						ItemName = item.Definition.Name,
						Raycasts = raycasts,
						Origin = origin,
					}
					request = raycastRequest
				elseif item.Kind == "Grenade" then
					local throwRequest: CombatTypes.PrimaryFireThrowRequest = {
						Kind = "PrimaryFireThrowRequest" :: "PrimaryFireThrowRequest",
						ItemName = item.Definition.Name,
						Origin = origin,
						Direction = direction,
					}
					request = throwRequest
				elseif item.Kind == "Item" then
					if item.Definition.PrimaryFireServer then
						local itemRequest: CombatTypes.PrimaryFireItemRequest = {
							Kind = "PrimaryFireItemRequest" :: "PrimaryFireItemRequest",
							ItemName = item.Definition.Name,
							Origin = origin,
							Direction = direction,
						}
						request = itemRequest
					end

					if item.Definition.PrimaryFireClient then
						item.Definition.PrimaryFireClient(item, "Primary", origin, direction)
					end
				else
					error("Unknown item kind: " .. item.Kind)
				end

				if item.Kind == "Gun" then
					item.Ammo -= 1
					RoundInfoUI.UpdateAmmo(item)
				end

				if item.Kind == "Melee" then
					local id = assert(tonumber((item.Definition.AttackAnimation :: string):split("://")[2]), "Invalid attack animation: " .. tostring(item.Definition.HoldAnimation))
					LocalAnimation.TryPlayAnimation(id, "MeleeAttack")
				end

				if item.Kind == "Gun" and item.Definition.HasMuzzleFlash then
					ViewmodelModule.MuzzleFlash()
				end
				ViewmodelModule.Recoil(item.Definition)

				if request then
					task.spawn(function()
						local result: CombatTypes.ValidateItemUsageResult = ReplicatedStorage.Remotes.ClientServer.PrimaryFire:InvokeServer(request)
						if result ~= "Success" and result ~= "PreGame" then
							warn("Hit rejected:", result)
							if Settings.GetSetting("Show Hit Rejects") then
								ScreenMessage("Hit rejected: " .. result, "Warn")
							end
						end
					end)
				end

				if item.Kind == "Gun" and item.Ammo == 0 then
					tryReloadWeapon(item)
				end

				if item.Kind == "Grenade" then
					break
				end
			end

			return Enum.ContextActionResult.Sink
		end)
	end
end)

return nil