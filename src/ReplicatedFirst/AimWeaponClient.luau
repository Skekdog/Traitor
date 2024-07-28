local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local InventoryManager = require(script.Parent.InventoryManager)
local SetCameraSensitivity = require(script.Parent.SetCameraSensitivity)
local SettingsManager = require(script.Parent.SettingsManager)
local UIManager = require(script.Parent.UIManager)

local module = {}
module.IsAiming = false

local function getSensitivityMultiplier(fov: number): number
    return fov / 70
end

local scope = UIManager.WaitForUI("Scope")
local function aim(aiming: boolean): ()
    local Viewmodel = (require)(script.Parent.Viewmodel)
    if aiming then
        local item = InventoryManager.GetEquipped(Players.LocalPlayer)
        if not item or item.Kind ~= "Gun" then
            return
        end

        local camera = workspace.CurrentCamera
        TweenService:Create(camera, TweenInfo.new(0.1), {FieldOfView = item.Base.AimFOV}):Play()

        SetCameraSensitivity(getSensitivityMultiplier(item.Base.AimFOV))
        if item.Base.HasScope then
            scope:ToggleVisible(true)
        else
            scope:ToggleVisible(false)
        end

        Viewmodel.PlayAnimation(item.Base.AimAnimation, "AimAnimation")
    else
        SetCameraSensitivity(1)
        scope:ToggleVisible(false)

        local camera = workspace.CurrentCamera
        TweenService:Create(camera, TweenInfo.new(0.1), {FieldOfView = 70}):Play()

        Viewmodel.StopAnimation("AimAnimation")
    end
end

local aimRemote = ReplicatedStorage:WaitForChild("ClientServer").AimWeapon :: RemoteEvent
aimRemote.OnClientEvent:Connect(function(aiming: boolean)
    module.IsAiming = aiming
    aim(aiming)
end)

function module.Aim(input: InputObject): Enum.ContextActionResult
    local toggle = SettingsManager.GetSetting("Toggle Aim") :: boolean
    local state = input.UserInputState

    if toggle then
        if state == Enum.UserInputState.End then
            module.IsAiming = not module.IsAiming
            aimRemote:FireServer(module.IsAiming)
            return Enum.ContextActionResult.Sink
        end
        return Enum.ContextActionResult.Pass
    end

    if state == Enum.UserInputState.End then
        module.IsAiming = false
    else
        module.IsAiming = true
    end

    aimRemote:FireServer(module.IsAiming)
    aim(module.IsAiming)
    return Enum.ContextActionResult.Sink
end

return module