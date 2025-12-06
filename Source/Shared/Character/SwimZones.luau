-- Adapted from @tyridge77's SwimController module: https://devforum.roblox.com/t/smooth-terrain-swimming-but-inside-of-partsv30

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)

type CleanupTargets = { Instance | (...any) -> (...any) | RBXScriptConnection }

local function cleanup(targets: CleanupTargets): ()
	for _, target in ipairs(targets) do
		if typeof(target) == "RBXScriptConnection" then
			target:Disconnect()
		elseif typeof(target) == "function" then
			target()
		else
			target:Destroy()
		end
	end
	table.clear(targets)
end

local generalCleanup: CleanupTargets = {}
local stateCleanup: CleanupTargets = {}
local recalcCleanup: CleanupTargets = {}

local function InPart(part: BasePart, pos: Vector3, heightOffset: number): boolean
	local rel = part.CFrame:PointToObjectSpace(pos)
	local size = part.Size
	if math.abs(rel.X) <= size.X/2 and math.abs(rel.Y) <= size.Y/2 + (heightOffset or 0) and math.abs(rel.Z) <= size.Z/2 then
		return true
	end
	return false
end

local zones: {BasePart} = {}
local isSwimming = false

local isInSwimmingState = false

local didJump = false
local lastZone: BasePart?

local INVALID_START_STATES = { -- Can't start swimming if character is in one of these states
	Enum.HumanoidStateType.Seated, Enum.HumanoidStateType.PlatformStanding,
	Enum.HumanoidStateType.Dead, Enum.HumanoidStateType.Physics,
	Enum.HumanoidStateType.Swimming
}

local DISABLED_STATES = { -- These states are disabled when swimming
	Enum.HumanoidStateType.Jumping
}

local CLAMP_SURFACE_MOVEMENT = true -- clamps move direction to the surface of the water
local PROCESS_WELDED_PARTS = true -- calculate buoyancy forces for parts welded to the character

local DRAG_FORCE_MULTIPLIER = 9.85 -- magic number that determines strength of drag

local SURFACE_DEPTH = 0.35 -- offsets surface from the top of the part
local NEAR_SURFACE_THRESHOLD = 2 -- determines how close to the surface you need to be to jump and also when movement clamping applies

local UP_FORCE_MULTIPLIER = 1.5

local shouldRecalculateForces = false
local assemblyMass = 0

local dragMultiplier = 0
local antiGravForce = 0

local nearSurface = false
local surfaceY = 0

local vectorForce: VectorForce?

local function recalculateForces(root: BasePart, hum: Humanoid): ()
	cleanup(recalcCleanup)
	shouldRecalculateForces = false

	assemblyMass = root.AssemblyMass
	local gravity = workspace.Gravity

	local buoyancyForce = -assemblyMass * gravity
	local totalVolume = 0

	for _, v in root:GetConnectedParts(true) do
		local isLimb = v.Parent == root.Parent and (hum:GetBodyPartR15(v) ~= Enum.BodyPartR15.Unknown or hum:GetLimb(v) ~= Enum.Limb.Unknown)

		if not isLimb and not PROCESS_WELDED_PARTS then
			continue
		end

		table.insert(recalcCleanup, v:GetPropertyChangedSignal("CanCollide"):Connect(function()
			shouldRecalculateForces = true
		end))

		if not v.CanCollide then
			continue
		end

		local mass = v.Mass

		if mass == 0 and v.Massless then
			-- Massless parts are still buoyant for some reason /shrug
			v.Massless = false
			mass = v.Mass
			v.Massless = true
		end

		if mass ~= 0 then
			local physicalProperties = v.CurrentPhysicalProperties
			local density = physicalProperties.Density
			local volume = mass / density
			buoyancyForce += volume * gravity
			totalVolume += volume
		end
	end

	table.insert(recalcCleanup, workspace:GetPropertyChangedSignal("Gravity"):Connect(function()
		shouldRecalculateForces = true
	end))

	assemblyMass = assemblyMass
	dragMultiplier = totalVolume * DRAG_FORCE_MULTIPLIER
	antiGravForce = assemblyMass * gravity
	buoyancyForce = buoyancyForce
end

local root, hum
LocalCharacter.RootPart:Connect(function(newRoot)
	root = newRoot
end, true)
LocalCharacter.Humanoid:Connect(function(newHum)
	hum = newHum
end, true)

local function stopSwimming(): ()
	if not isSwimming then
		return
	end

	isSwimming = false
	isInSwimmingState = false
	nearSurface = false
	didJump = false

	cleanup(generalCleanup)
	cleanup(stateCleanup)
	cleanup(recalcCleanup)
end

local function startSwimming(zone: BasePart): ()
	surfaceY = zone.Position.Y + zone.Size.Y / 2

	if isSwimming then
		return
	end

	isSwimming = true

	local attachment = Instance.new("Attachment")
	attachment.Name = "SwimAttachment"
	attachment.Parent = root

	vectorForce = Instance.new("VectorForce", attachment)
	assert(vectorForce)
	vectorForce.Attachment0 = attachment
	vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
	vectorForce.Force = Vector3.zero

	table.insert(generalCleanup, vectorForce)
	table.insert(stateCleanup, attachment)

	shouldRecalculateForces = true

	assert(hum)
	table.insert(generalCleanup, hum.StateChanged:Connect(function()
		-- Humanoids can change cancollide silently when changing state
		RunService.Stepped:Wait()
		shouldRecalculateForces = true
	end))
end

RunService.PreSimulation:Connect(function(dt)
	if not root or not hum then
		return
	end

	local humanState = hum:GetState()
	local rootPos = root.Position
	local currentZone: BasePart?

	for _, v in zones do
		if InPart(v, rootPos, if didJump then -SURFACE_DEPTH - NEAR_SURFACE_THRESHOLD else 0) then
			currentZone = v
			break
		end
	end

	if lastZone ~= currentZone then
		if not lastZone or not InPart(lastZone, rootPos, 2) then
			lastZone = currentZone

			if currentZone then
				startSwimming(currentZone)
			else
				stopSwimming()
			end
		end
	end

	if isSwimming then
		if humanState == Enum.HumanoidStateType.Swimming or not table.find(INVALID_START_STATES, humanState) then
			if not isInSwimmingState then
				isInSwimmingState = true

				hum:ChangeState(Enum.HumanoidStateType.Swimming)

				for _,state in DISABLED_STATES do
					hum:SetStateEnabled(state, false)
				end

				table.insert(stateCleanup, function()
					for _, state in DISABLED_STATES do
						hum:SetStateEnabled(state, true)
					end
				end)

				table.insert(stateCleanup, UserInputService.JumpRequest:Connect(function()
					didJump = true
				end))

				table.insert(stateCleanup, function()
					hum:ChangeState(Enum.HumanoidStateType.Freefall)
				end)

				if CLAMP_SURFACE_MOVEMENT then
					table.insert(stateCleanup, hum:GetPropertyChangedSignal("MoveDirection"):Connect(function()
						local moveDir = hum.MoveDirection

						if nearSurface and moveDir.Y > 0.1 then
							local camCFrame = workspace.CurrentCamera.CFrame
							local inputDir = camCFrame:VectorToObjectSpace(moveDir)

							if math.abs(inputDir.Y) < 1e-2 then
								local from = camCFrame.LookVector
								local to = Vector3.new(from.X, 0, from.Z)

								local newMoveDir = CFrame.fromAxisAngle(
									from:Cross(to),
									math.acos(math.clamp(from:Dot(to), -1, 1))
								) * moveDir

								hum:Move(newMoveDir)
							end
						end
					end))
				end
			end
		else
			isInSwimmingState = false
			cleanup(stateCleanup)
		end
	end

	if isSwimming then
		local velocity = root.AssemblyLinearVelocity * ((1 / 60) / dt)

		if shouldRecalculateForces or assemblyMass ~= root.AssemblyMass then
			recalculateForces(root, hum)
		end

		local drag = velocity * dragMultiplier
		local upForce = antiGravForce

		local offsetToSurface = (surfaceY - SURFACE_DEPTH) - rootPos.Y

		didJump = false
		nearSurface = offsetToSurface < NEAR_SURFACE_THRESHOLD

		upForce += math.clamp(math.min(1, offsetToSurface) * 12 - velocity.Y, -10, 100) * UP_FORCE_MULTIPLIER * assemblyMass

		if vectorForce then
			vectorForce.Force = Vector3.yAxis * upForce - drag
		end
	end
end)

local function addZone(part: Instance): ()
	if not part:HasTag("Water") or not part:IsA("BasePart") then
		return
	end

	if part.Size.Y < 1 then
		return
	end

	table.insert(zones, part)
	part.Destroying:Once(function()
		table.remove(zones, assert(table.find(zones, part)))
	end)
end

CollectionService:GetInstanceAddedSignal("Water"):Connect(addZone)
for _, v in CollectionService:GetTagged("Water") do
	addZone(v)
end

return nil