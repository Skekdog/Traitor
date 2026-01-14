local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local GetMaterial = require(ReplicatedStorage.API.GetMaterial)
local ScreenMessage = require(ReplicatedStorage.API.ScreenMessage)
local GetCentreRay = require(ReplicatedStorage.Shared.Camera.GetCentreRay)
local LocalAnimation = require(ReplicatedStorage.Shared.Character.LocalAnimation)
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local RoundInfoUI = require(ReplicatedStorage.Shared.Interface.GameState.RoundInfoUI)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local ClientInventory = require(ReplicatedStorage.Shared.LocalState.ClientInventory)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local CreateEmptyPart = require(ReplicatedStorage.Shared.RoundRule.Common.CreateEmptyPart)
local Aim = require(script.Parent.Aim)
local BulletTracer = require(script.Parent.BulletTracer)
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
local function getSpreadVector(item: Types.Item): Vector3
	if not item.Spread then
		return Vector3.zero
	end

	local spread = item.Spread * (if Aim.IsAiming() then item.AimSpreadMultiplier or 1 else 1)
	return Vector3.new(random:NextNumber(-spread, spread), random:NextNumber(-spread, spread), random:NextNumber(-spread, spread))
end

local function raycast(char: Model, spread: Vector3, range: number, checkInitialOverlap: boolean, origin: Vector3, direction: Vector3, fallbackToBlockcast: boolean): {RaycastResult: RaycastResult?, Parts: {BasePart}?, Origin: Vector3?}
	local map = LocalRoundInfo.Map()
	if not map then
		return {}
	end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {char}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.CollisionGroup = "WeaponHitTargets"

	local parts: {BasePart}?
	if checkInitialOverlap then
		local overlapParams = OverlapParams.new()
		overlapParams.FilterDescendantsInstances = {char}
		overlapParams.FilterType = Enum.RaycastFilterType.Exclude
		overlapParams.CollisionGroup = "WeaponHitTargets"

		local boundPart = CreateEmptyPart(workspace.CurrentCamera.CFrame)
		boundPart.Size = Vector3.new(0.1, 0.1, 0.1)
		parts = workspace:GetPartsInPart(boundPart, overlapParams)
	end

	direction = (direction + spread).Unit * range
	local result = workspace:Raycast(origin, direction, params)

	if not result and fallbackToBlockcast then
		result = workspace:Blockcast(CFrame.new(origin), Vector3.one * 1.5, direction, params)
	end

	return {
		RaycastResult = result,
		Parts = parts,
		Origin = origin,
	}
end

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

	ViewmodelModule.ReloadSpring.p = Vector3.new(10, 5, 10)

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
		item.UseAttack and
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
			return
		end

		if isPrimary and item.IsScopeRequired and not Aim.IsAiming() then
			playEmptyClipSound()
			return Enum.ContextActionResult.Pass -- note: we return here instead of continuing so that if we aren't scoped in, and later we are, we don't have to wait for the attack interval
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

		if isPrimary then
			if item.IsReloading then
				continue
			end

			if item.Ammo and item.Ammo <= 0 then
				if not tryReloadWeapon(item) then
					playEmptyClipSound()
				end
				continue
			end

			if item.Ammo then
				item.Ammo -= 1
				RoundInfoUI.UpdateAmmo()
			end

			if item.HasMuzzleFlash then
				ViewmodelModule.MuzzleFlash()
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

		ViewmodelModule.Recoil(item)

		local head = char:WaitForChild("Head")
		assert(head and head:IsA("BasePart"), "HumanoidRootPart is not a BasePart")

		local origin = head.Position
		local direction = GetCentreRay().Direction

		local func = if isPrimary then item.PrimaryFireClient else item.AlternateFireClient
		if func then
			func(item, origin, direction)
		end

		local raycasts: {CombatTypes.RaycastInfo} = {}

		if not item.IsProjectileSimulated then
			for i = 1, item.ProjectileCount or 1 do
				local spread = getSpreadVector(item)

				local result = raycast(assert(head:FindFirstAncestorOfClass("Model")), spread, item.MaxDistance or MAX_RANGE, item.CheckInitialIntersection or false, origin, direction, item.CheckInitialIntersection or false)
				local raycastResult = result.RaycastResult
				local part = if result.Parts then result.Parts[1] else nil

				local targetPosition = if raycastResult then raycastResult.Position else deriveTargetPosition(origin, spread, item.MaxDistance or MAX_RANGE)
				local hitPart = if raycastResult then raycastResult.Instance :: BasePart else nil
				local hitPartCenterPosition = if hitPart then hitPart.Position else nil
				local normal = if raycastResult then raycastResult.Normal else nil
				local relativeHitCFrame = if raycastResult then raycastResult.Instance.CFrame:ToObjectSpace(CFrame.new(targetPosition)) else nil

				if item.Projectile and result.Origin then
					BulletTracer(item.Projectile, item.ProjectileSpeed or 100, result.Origin, targetPosition)
				end

				if hitPart and not hitPart:IsDescendantOf(workspace.Characters) then
					PlaySound(HitSounds[GetMaterial(hitPart)] or HitSounds.Default, targetPosition or hitPart.Position, nil, {
						RollOffMaxDistance = 20,
					})
				end

				if not part then
					table.insert(raycasts, {
						Destination = targetPosition,
						HitPart = hitPart,
						HitPartCenterPosition = hitPartCenterPosition,
						Normal = normal,
						RelativeHitCFrame = relativeHitCFrame,
					})
				else
					table.insert(raycasts, {
						Destination = part.Position,
						HitPart = part,
						HitPartCenterPosition = part.Position,
						Normal = Vector3.zero,
						RelativeHitCFrame = CFrame.identity,
					})
				end
			end
		end

		local request: CombatTypes.Request = {
			Action = if isPrimary then "Primary" else "Alternate",
			ItemName = item.Name,
			Origin = origin,
			Direction = direction,
			Raycasts = raycasts,
		}

		if isPrimary then
			if item.Ammo == 0 then
				tryReloadWeapon(item)
			end

			if item.IsSingleUse then
				break
			end
		end

		if isPrimary and item.PrimaryFireServer or not isPrimary and item.AlternateFireServer or item.UseAttack then
			task.spawn(function()
				local result: CombatTypes.ValidateUsageResult = ReplicatedStorage.Remotes.ClientServer.Fire:InvokeServer(request)
				if result ~= "Success" then
					warn("Hit rejected:", result)
					if Settings.GetSetting("Show Hit Rejects") then
						ScreenMessage("Hit rejected: " .. result, "Warn")
					end
				end
			end)
		end
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