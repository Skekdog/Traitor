local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameHooks = require(ReplicatedStorage.API.GameHooks)
local JumpPower = require(ReplicatedStorage.Shared.Character.JumpPower)
local LocalAnimation = require(ReplicatedStorage.Shared.Character.LocalAnimation)
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
local WalkSpeed = require(ReplicatedStorage.Shared.Character.WalkSpeed)

local BLOCKED_CHECK_DISTANCE = 1.75

local isCrouching = false
local track: AnimationTrack?

local module = {}

local function adjustTrackSpeed(): ()
	if not track then
		return
	end

	local hum = LocalCharacter.Humanoid()
	if not hum then
		return
	end

	track:AdjustSpeed(if hum.MoveDirection.Magnitude > 0 then hum.WalkSpeed / 16 else 0)
end

function module.IsCrouching(): boolean
	return isCrouching
end

local params = RaycastParams.new()
params.ExcludeInstances = {workspace.Characters, workspace.Projectiles}
params.IgnoreWater = true

local function isBlocked(): boolean
	local root = LocalCharacter.RootPart()
	if not root then
		return true
	end

	local result = workspace:Raycast(root.Position, Vector3.yAxis * BLOCKED_CHECK_DISTANCE, params)
	return result ~= nil
end

local crouchDisablers: {[string]: true?} = {}

function module.SetCrouchDisabled(source: string, disabled: boolean): ()
	if disabled then
		module.ToggleCrouching(false)
	end
	crouchDisablers[source] = if disabled then true else nil
end

function module.ToggleCrouching(enabled: boolean?): ()
	if isCrouching == enabled then
		return
	end

	for source in crouchDisablers do
		return -- yeah this looks stupid but actually the table will only have a value if it is disabled
	end

	isCrouching = if enabled == nil then not isCrouching else enabled

	if not isCrouching and isBlocked() then
		isCrouching = true
		return
	end

	local hum = LocalCharacter.Humanoid()
	if isCrouching and hum and hum:GetState() == Enum.HumanoidStateType.Swimming then
		isCrouching = false
		return
	end

	WalkSpeed.SetModifier("Crouching", if isCrouching then -6 else 0)

	if hum then
		hum.CameraOffset = Vector3.new(0, if isCrouching then -0.9 else 0, 0)
		JumpPower.SetModifier("Crouching", not isCrouching)
		hum:SetAttribute("IsCrouching", isCrouching)
		ReplicatedStorage.Remotes.ClientServer.Crouch:FireServer(isCrouching)
	end

	if isCrouching then
		track = LocalAnimation.TryPlayAnimation(Content.fromAssetId(94335137129691), "Crouch")
		adjustTrackSpeed()
	else
		LocalAnimation.TryStopAnimation("Crouch")
		track = nil
	end

	for _, hook in GameHooks.OnCrouch do
		hook(isCrouching)
	end
end

LocalCharacter.Humanoid:Connect(function(hum)
	if not hum then
		return
	end

	hum:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		adjustTrackSpeed()
	end)

	hum.Swimming:Connect(function()
		module.ToggleCrouching(false)
	end)
end)

return table.freeze(module)