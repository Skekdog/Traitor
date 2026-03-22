local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SetCameraSensitivity = require(ReplicatedStorage.Shared.Camera.SetCameraSensitivity)
local JumpPower = require(ReplicatedStorage.Shared.Character.JumpPower)
local WalkSpeed = require(ReplicatedStorage.Shared.Character.WalkSpeed)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local DynamicValue = require(ReplicatedStorage.Shared.Util.DynamicValue)
local Viewmodel = require(script.Parent.Viewmodel)

local scopeUi = UIManager.WaitForUI("Scope")

local module = {}

module.IsAiming = DynamicValue.new(false)

function module.ToggleAim(item: Types.Item?, enabled: boolean?): ()
	local isAiming = if enabled == nil then not module.IsAiming() else enabled

	JumpPower.SetModifier("Aiming", not isAiming)

	local camera = workspace.CurrentCamera
	if isAiming then
		assert(item and item.IsAimable, "Must pass an aimable item when enabling aiming")

		TweenService:Create(camera, TweenInfo.new(0.1), {FieldOfView = item.AimFOV or 70}):Play()

		SetCameraSensitivity((item.AimFOV or 70) / 70)

		if item.IsScopable then
			scopeUi:ToggleVisible(true)
		end

		WalkSpeed.SetModifier("Aiming", -4)

		if item.AimAnimation then
			Viewmodel.PlayAnimation(item.AimAnimation, "Aim")
		end
		Viewmodel.IsAiming = true
	else
		TweenService:Create(camera, TweenInfo.new(0.1), {FieldOfView = 70}):Play()

		SetCameraSensitivity(1)

		scopeUi:ToggleVisible(false)

		WalkSpeed.SetModifier("Aiming", 0)

		Viewmodel.StopAnimation("Aim")
		Viewmodel.IsAiming = false
	end

	module.IsAiming:SetValue(isAiming)
end

return table.freeze(module)