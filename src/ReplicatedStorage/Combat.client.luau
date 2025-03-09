local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local PlaySound = require(ReplicatedStorage.RoundRule.Common.PlaySound)
local Aim = require(script.Parent.Aim)
local Types = require(ReplicatedStorage.RoundRule.Types)
local RoundInfoUI = require(ReplicatedStorage.UIScripts.RoundInfoUI)
local ClientInventory = require(script.Parent.ClientInventory)
local CombatTypes = require(script.Parent.CombatTypes)
local ControlManager = require(script.Parent.ControlManager)
local GetCentreRay = require(script.Parent.GetCentreRay)
local HitSounds = require(script.Parent.HitSounds)
local LocalAnimation = require(script.Parent.LocalAnimation)
local LocalCharacter = require(script.Parent.LocalCharacter)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local UIManager = require(script.Parent.UIManager)
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
	local map = LocalRoundInfo.GetMap()
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
	PlaySound(ReplicatedStorage.WeaponSounds.EmptyClip, nil, nil, {SoundGroup = SoundService.AllSounds :: SoundGroup})
end

local crosshair = UIManager.WaitForUI("Crosshair") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Crosshair)}

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
	
	PlaySound(item.Definition.ReloadSound, nil, nil, {SoundGroup = SoundService.AllSounds :: SoundGroup})

	ReplicatedStorage.ClientServer.ReloadWeapon:FireServer(item.Definition.Name)

	return true
end

local lastAmmoConnection: ClientInventory.AmmoConnection?

local function updateCrosshair(isAiming: boolean): ()
	local item = ClientInventory.EquippedItem
	crosshair:ToggleVisible(not not item)

	if not item then
		return
	end

	if isAiming and item.Kind == "Gun" and item.Definition.HasScope then
		return crosshair:ToggleVisible(false)
	end

	if item.Kind == "Gun" then
		local spread = item.Definition.Spread * 5 * (if isAiming then item.Definition.AimSpreadMultiplier or 1 else 1)
        crosshair.Object.Size = UDim2.fromScale(spread, spread)
    else
        crosshair.Object.Size = UDim2.new()
    end
end

Aim.AimEvent:Connect(function(isAiming)
	updateCrosshair(isAiming)
end)

ClientInventory.ConnectEquippedItemChanged(function(item): ()
	updateCrosshair(false)

	Aim.ToggleAim(item, false)

	RoundInfoUI.UpdateAmmo(item)

	if lastAmmoConnection then
		ClientInventory.RemoveAmmoChangedConnection(lastAmmoConnection)
	end

	local char = LocalCharacter.GetCharacter()
	if not item or not char then
		ControlManager.Unregister("Primary Fire")
		ControlManager.Unregister("Reload Weapon")
		ControlManager.Unregister("Alternate Fire")
		return
	end

	lastAmmoConnection = ClientInventory.ConnectAmmoChanged(item.Kind, function(ammo)
		RoundInfoUI.UpdateAmmo(item)
	end)

	if item.Kind == "Gun" then
		ControlManager.Register("Alternate Fire", true, function(_, state)
			if state ~= Enum.UserInputState.End then
				return Enum.ContextActionResult.Pass
			end

			Aim.ToggleAim(item)
			return Enum.ContextActionResult.Sink
		end)
		
		ControlManager.Register("Reload Weapon", true, function(_, state)
			if state ~= Enum.UserInputState.End then
				return Enum.ContextActionResult.Pass
			end

			return if tryReloadWeapon(item) then Enum.ContextActionResult.Sink else Enum.ContextActionResult.Pass
		end)
	else
		ControlManager.Unregister("Reload Weapon")
	end

	if item.Kind == "Item" then
		ControlManager.Register("Alternate Fire", true, function(_, state)
			if state ~= Enum.UserInputState.End then
				return Enum.ContextActionResult.Pass
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
				item.Definition.AlternateFireClient(item, "Alternate", origin, direction)
			end

			local result: CombatTypes.ValidateItemUsageResult = ReplicatedStorage.ClientServer.AlternateFire:InvokeServer(itemRequest)
			if result ~= "Success" then
				warn("Item alternate fire rejected:", result)
			end

			return Enum.ContextActionResult.Sink
		end)
	end

	ControlManager.Register("Primary Fire", true, function(_, _, input)
		while ClientInventory.EquippedItem == item and input.UserInputState ~= Enum.UserInputState.End and input.UserInputState ~= Enum.UserInputState.Cancel do
			task.wait()

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

			local origin = head.Position
			local direction = GetCentreRay().Direction

			local request: CombatTypes.PrimaryFireRequest
			if item.Kind == "Melee" or item.Kind == "Gun" then
				local raycasts: {CombatTypes.RaycastInfo} = {}
				for i = 1, if item.Kind == "Gun" then item.Definition.BulletsPerShot or 1 else 1 do
					local spread = getSpreadVector(item)

					local raycastResult = raycast(assert(head:FindFirstAncestorOfClass("Model")), spread, if item.Kind == "Melee" then item.Definition.MaxDistance else MAX_RANGE)

					local targetPosition = if raycastResult then raycastResult.Position else deriveTargetPosition(origin, spread, if item.Kind == "Melee" then item.Definition.MaxDistance else MAX_RANGE)
					local hitPart = if raycastResult then raycastResult.Instance :: BasePart else nil
					local hitPartCenterPosition = if hitPart then hitPart.Position else nil
					local normal = if raycastResult then raycastResult.Normal else nil

					if item.Kind == "Melee" and hitPart and not hitPart:IsDescendantOf(workspace.Characters) and not hitPart:IsDescendantOf(workspace.Corpses) then
						local material = hitPart:GetAttribute("MaterialOverride") or hitPart.Material.Name
						PlaySound(HitSounds[material] or HitSounds.Default, targetPosition or hitPart.Position)
					end

					table.insert(raycasts, {
						Destination = targetPosition,
						HitPart = hitPart,
						HitPartCenterPosition = hitPartCenterPosition,
						Normal = normal,
					})
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
				local itemRequest: CombatTypes.PrimaryFireItemRequest = {
					Kind = "PrimaryFireItemRequest" :: "PrimaryFireItemRequest",
					ItemName = item.Definition.Name,
					Origin = origin,
					Direction = direction,
				}
				request = itemRequest

				if item.Definition.PrimaryFireClient then
					item.Definition.PrimaryFireClient(item, "Primary", origin, direction)
				end
			else
				error("Unknown item kind: " .. item.Kind)
			end

			local result: CombatTypes.ValidateItemUsageResult = ReplicatedStorage.ClientServer.PrimaryFire:InvokeServer(request)
			if result ~= "Success" then
				warn("Hit rejected:", result)
			end
		end

		return Enum.ContextActionResult.Sink
	end)
end)
