local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local DynamicValue = require(script.Parent.DynamicValue)
local JumpPower = require(script.Parent.JumpPower)
local SetCameraSensitivity = require(script.Parent.SetCameraSensitivity)
local Types = require(ReplicatedStorage.RoundRule.Types)
local UIManager = require(script.Parent.UIManager)
local ViewmodelModule = require(script.Parent.ViewmodelModule)
local WalkSpeed = require(script.Parent.WalkSpeed)

local scopeUi = UIManager.WaitForUI("Scope")

local module = {}

module.IsAiming = DynamicValue.new(false)

function module.ToggleAim(item: Types.AnyItem?, enabled: boolean?): ()
	local isAiming = not module.IsAiming()

	JumpPower.SetModifier("Aiming", not isAiming)

	local camera = workspace.CurrentCamera
	if isAiming then
		assert(item and item.Kind == "Gun", "Must pass a gun when enabling aiming")

		TweenService:Create(camera, TweenInfo.new(0.1), {FieldOfView = item.Definition.AimFOV or 70}):Play()
		
		SetCameraSensitivity((item.Definition.AimFOV or 70) / 70)

		if item.Definition.HasScope then
			scopeUi:ToggleVisible(true)
		end

		WalkSpeed.SetModifier("Aiming", -4)

		if item.Definition.AimAnimation then
			ViewmodelModule.PlayAnimation(item.Definition.AimAnimation, "Aim")
		end
		ViewmodelModule.IsAiming = true
	else
		TweenService:Create(camera, TweenInfo.new(0.1), {FieldOfView = 70}):Play()

		SetCameraSensitivity(1)

		scopeUi:ToggleVisible(false)

		WalkSpeed.SetModifier("Aiming", 0)

		ViewmodelModule.StopAnimation("Aim")
		ViewmodelModule.IsAiming = false
	end

	module.IsAiming:SetValue(if enabled == nil then isAiming else enabled)
end

return module