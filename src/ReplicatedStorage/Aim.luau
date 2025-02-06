local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SetCameraSensitivity = require(script.Parent.SetCameraSensitivity)
local Types = require(ReplicatedStorage.RoundRule.Types)
local UIManager = require(script.Parent.UIManager)
local ViewmodelModule = require(script.Parent.ViewmodelModule)

local scopeUi = UIManager.WaitForUI("Scope")
local isAiming = false

local module = {}

function module.IsAiming(): boolean
	return isAiming
end

function module.ToggleAim(item: Types.GunWeapon, enabled: boolean?): ()
	isAiming = if enabled == nil then not isAiming else enabled

	local camera = workspace.CurrentCamera
	if isAiming then
		camera.FieldOfView = item.Definition.AimFOV or 70
		SetCameraSensitivity((item.Definition.AimFOV or 70) / 70)

		if item.Definition.HasScope then
			scopeUi:ToggleVisible(true)
		end

		if item.Definition.AimAnimation then
			ViewmodelModule.PlayAnimation(item.Definition.AimAnimation, "Aim")
		end
		ViewmodelModule.IsAiming = true
	else
		camera.FieldOfView = 70
		SetCameraSensitivity(1)

		scopeUi:ToggleVisible(false)

		ViewmodelModule.StopAnimation("Aim")
		ViewmodelModule.IsAiming = false
	end
end

return module