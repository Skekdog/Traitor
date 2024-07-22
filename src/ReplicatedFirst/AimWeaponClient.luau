local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local InventoryManager = require(script.Parent.InventoryManager)
local SettingsManager = require(script.Parent.SettingsManager)
local UIManager = require(script.Parent.UIManager)

local isAiming = false

local scope = UIManager.WaitForUI("Scope")
local function aim(aiming: boolean): ()
    if aiming then
        local item = InventoryManager.GetEquipped(Players.LocalPlayer)
        if not item or item.Kind ~= "Gun" then
            return
        end

        local camera = workspace.CurrentCamera
        TweenService:Create(camera, TweenInfo.new(0.1), {FieldOfView = item.Base.AimFOV}):Play()

        if item.Base.HasScope then
            scope:ToggleVisible(true)
        else
            scope:ToggleVisible(false)
        end
    else
        scope:ToggleVisible(false)

        local camera = workspace.CurrentCamera
        TweenService:Create(camera, TweenInfo.new(0.1), {FieldOfView = 70}):Play()
    end
end

local aimRemote = ReplicatedStorage:WaitForChild("ClientServer").AimWeapon :: RemoteEvent
aimRemote.OnClientEvent:Connect(function(aiming: boolean)
    isAiming = aiming
    aim(isAiming)
end)

return function(input: InputObject): Enum.ContextActionResult
    local toggle = SettingsManager.GetSetting("Toggle Aim") :: boolean
    local state = input.UserInputState

    print(isAiming)
    if toggle then
        if state == Enum.UserInputState.End then
            isAiming = not isAiming
            aimRemote:FireServer(isAiming)
            return Enum.ContextActionResult.Sink
        end
        return Enum.ContextActionResult.Pass
    end

    if state == Enum.UserInputState.End then
        isAiming = false
    else
        isAiming = true
    end

    aimRemote:FireServer(isAiming)
    aim(isAiming)
    return Enum.ContextActionResult.Sink
end
