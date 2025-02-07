local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
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

local callbacks: {(boolean) -> ()} = {}
function module.ConnectAimToggled(callback: (boolean) -> ()): ()
	table.insert(callbacks, callback)
end

local function runCallbacks(): ()
	for _, v in callbacks do
		v(isAiming)
	end
end

function module.ToggleAim(item: Types.AnyItem?, enabled: boolean?): ()
	isAiming = if enabled == nil then not isAiming else enabled

	local camera = workspace.CurrentCamera
	if isAiming then
		assert(item and item.Kind == "Gun", "Must pass a gun when enabling aiming")

		TweenService:Create(camera, TweenInfo.new(0.1), {FieldOfView = item.Definition.AimFOV or 70}):Play()
		
		SetCameraSensitivity((item.Definition.AimFOV or 70) / 70)

		if item.Definition.HasScope then
			scopeUi:ToggleVisible(true)
		end

		if item.Definition.AimAnimation then
			ViewmodelModule.PlayAnimation(item.Definition.AimAnimation, "Aim")
		end
		ViewmodelModule.IsAiming = true
	else
		TweenService:Create(camera, TweenInfo.new(0.1), {FieldOfView = 70}):Play()

		SetCameraSensitivity(1)

		scopeUi:ToggleVisible(false)

		ViewmodelModule.StopAnimation("Aim")
		ViewmodelModule.IsAiming = false
	end

	runCallbacks()
end

return module