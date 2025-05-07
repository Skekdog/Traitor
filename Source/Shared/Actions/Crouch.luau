local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JumpPower = require(ReplicatedStorage.Shared.Character.JumpPower)
local LocalAnimation = require(ReplicatedStorage.Shared.Character.LocalAnimation)
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
local WalkSpeed = require(ReplicatedStorage.Shared.Character.WalkSpeed)

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

function module.ToggleCrouching(enabled: boolean?): ()
	isCrouching = if enabled == nil then not isCrouching else enabled

	WalkSpeed.SetModifier("Crouching", if isCrouching then -6 else 0)

	local hum = LocalCharacter.Humanoid()
	if hum then
		hum.CameraOffset = Vector3.new(0, if isCrouching then -0.9 else 0, 0)
		JumpPower.SetModifier("Crouching", not isCrouching)
		hum:SetAttribute("IsCrouching", isCrouching)
	end

	if isCrouching then
		track = LocalAnimation.TryPlayAnimation(94335137129691, "Crouch")
		adjustTrackSpeed()
	else
		LocalAnimation.TryStopAnimation("Crouch")
		track = nil
	end
end

Players.LocalPlayer.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid")
	assert(hum:IsA("Humanoid"), "Humanoid is not a Humanoid")

	hum:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		adjustTrackSpeed()
	end)
end)

return module