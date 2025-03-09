local Players = game:GetService("Players")
local JumpPower = require(script.Parent.JumpPower)
local LocalAnimation = require(script.Parent.LocalAnimation)
local LocalCharacter = require(script.Parent.LocalCharacter)
local WalkSpeed = require(script.Parent.WalkSpeed)

local isCrouching = false
local track: AnimationTrack?

local module = {}

function module.IsCrouching(): boolean
	return isCrouching
end

function module.ToggleCrouching(enabled: boolean?): ()
	isCrouching = if enabled == nil then not isCrouching else enabled

	WalkSpeed.SetModifier("Crouching", if isCrouching then -6 else 0)

	local hum = LocalCharacter.GetHumanoid()
	if hum then
		hum.CameraOffset = Vector3.new(0, if isCrouching then -0.9 else 0, 0)
		JumpPower.SetModifier("Crouching", not isCrouching)
	end

	if isCrouching then
		track = LocalAnimation.TryPlayAnimation(94335137129691, "Crouch")
	else
		LocalAnimation.TryStopAnimation("Crouch")
		track = nil
	end
end

Players.LocalPlayer.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid")
	assert(hum:IsA("Humanoid"), "Humanoid is not a Humanoid")

	hum:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		if not track then
			return
		end

		track:AdjustSpeed(if hum.MoveDirection.Magnitude > 0 then hum.WalkSpeed / 16 else 0)
	end)
end)

return module