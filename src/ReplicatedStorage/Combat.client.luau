local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Types = require(ReplicatedStorage.RoundRule.Types)
local ClientInventory = require(script.Parent.ClientInventory)
local CombatTypes = require(script.Parent.CombatTypes)
local ControlManager = require(script.Parent.ControlManager)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local ViewmodelModule = require(script.Parent.ViewmodelModule)

local player = Players.LocalPlayer

local MAX_RANGE = 10000

local function getCharacter(): Model?
	return player.Character
end

local function getCenterRay(): Ray
    local camera = workspace.CurrentCamera
    return camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
end

local function deriveTargetPosition(origin: Vector3, spread: Vector3, range: number): Vector3
	return origin + (getCenterRay().Direction + spread).Unit * range
end

local random = Random.new(workspace:GetServerTimeNow())
local function getSpreadVector(spread: number?): Vector3
	if not spread then
		return Vector3.zero
	end

	return Vector3.new(random:NextNumber(-spread, spread), random:NextNumber(-spread, spread), random:NextNumber(-spread, spread))
end

local function raycast(char: Model, spread: Vector3): RaycastResult?
	local map = LocalRoundInfo.GetMap()
	if not map then
		return
	end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {char}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.CollisionGroup = "WeaponHitTargets"

	return workspace:Raycast(workspace.CurrentCamera.CFrame.Position, (getCenterRay().Direction + spread).Unit * MAX_RANGE, params)
end

player.CharacterRemoving:Connect(function()
	ControlManager.Unregister("Primary Fire")
end)

local function playEmptyClipSound(): ()
	local sound = ReplicatedStorage.WeaponSounds.EmptyClip:Clone()
	sound.Parent = SoundService
	sound:Destroy()
end

ClientInventory.ConnectEquippedItemChanged(function(item): ()
	local char = getCharacter()
	if not item or not char then
		print(1)
		return ControlManager.Unregister("Primary Fire")
	end

	ControlManager.Register("Primary Fire", true, function(_, _, input)
		while ClientInventory.EquippedItem == item and input.UserInputState ~= Enum.UserInputState.End and input.UserInputState ~= Enum.UserInputState.Cancel do
			task.wait()

			if item.Kind == "Melee" or item.Kind == "Gun" then
				if item.LastAttackTime + item.Definition.AttackInterval > tick() then
					continue
				end
				(item :: Types.GunWeapon).LastAttackTime = tick()
			end

			if item.Kind == "Gun" and item.Ammo <= 0 then
				playEmptyClipSound()
				print(2)
				continue
			end

			local head = char:WaitForChild("Head")
			assert(head and head:IsA("BasePart"), "HumanoidRootPart is not a BasePart")

			if item.Kind == "Gun" then
				item.Ammo -= 1
			end

			if item.Kind == "Gun" and item.Definition.HasMuzzleFlash then
				ViewmodelModule.MuzzleFlash()
			end
			ViewmodelModule.Recoil(item.Definition)

			local shots: {CombatTypes.Shot} = {}
			for i = 1, if item.Kind == "Gun" then item.Definition.BulletsPerShot or 1 else 1 do
				local spread = getSpreadVector(if item.Kind == "Gun" then item.Definition.Spread else nil)

				local origin = head.Position
				local raycastResult = raycast(assert(head:FindFirstAncestorOfClass("Model")), spread)

				local targetPosition = if raycastResult then raycastResult.Position else deriveTargetPosition(origin, spread, MAX_RANGE)
				local hitPart = if raycastResult then raycastResult.Instance :: BasePart else nil
				local hitPartCenterPosition = if hitPart then hitPart.Position else nil

				table.insert(shots, {
					Destination = targetPosition,
					HitPart = hitPart,
					HitPartCenterPosition = hitPartCenterPosition
				})
			end

			local request: CombatTypes.PrimaryFireRequest = {
				ItemName = item.Definition.Name,
				Shots = shots,
				Origin = head.Position,
			}

			local result: CombatTypes.ValidateItemUsageResult = ReplicatedStorage.ClientServer.PrimaryFire:InvokeServer(request)
			if result ~= "Success" then
				warn("Hit rejected:", result)
			end
		end

		return Enum.ContextActionResult.Sink
	end)
end)
