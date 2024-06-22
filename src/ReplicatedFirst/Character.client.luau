local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ControlManager = require(script.Parent.ControlManager)
local InventoryManager = require(script.Parent.InventoryManager)
local ItemTypes = require(script.Parent.ItemsManager.ItemTypes)
local SettingsManager = require(script.Parent.SettingsManager)
local UIManager = require(script.Parent.UIManager)

local roundInfo = UIManager.WaitForUI("RoundInfo").Object :: typeof(UIManager.UnregisteredUIs.RoundInfo)

local activeTween: Tween
local function setHealth(hum: Humanoid)
    local noTransition = not SettingsManager.GetSetting("Animate UI Transitions") :: boolean

    roundInfo.Frame.HealthBar.HealthLabel.Text = tostring(math.round(hum.Health))
    if activeTween then
        activeTween:Cancel()
    end
    activeTween = TweenService:Create(roundInfo.Frame.HealthBar.Background, TweenInfo.new(if noTransition then 0 else 0.1), {Size = UDim2.new(hum.Health / hum.MaxHealth, 0, 1, 0)})
    activeTween:Play()
end

local function onDeath()
    script.Parent.ClientStorage:SetAttribute("IsSpectating", true)
    roundInfo.Frame.HealthBar.Visible = false
end

Players.LocalPlayer.CharacterAdded:Connect(function(char)
    script.Parent.ClientStorage:SetAttribute("IsSpectating", false)

    local hum = char:WaitForChild("Humanoid") :: Humanoid
    hum.Died:Once(onDeath)

    roundInfo.Frame.HealthBar.Visible = true

    setHealth(hum)
    hum:GetPropertyChangedSignal("Health"):Connect(function()
        setHealth(hum)
    end)

    local camera = workspace.CurrentCamera
    while char.Parent do
        task.wait(1 / 60)
        local y, _, _ = camera.CFrame:ToOrientation()
        local neck = char:FindFirstChild("Neck", true) :: Motor6D
        if not neck then
            continue
        end
        ReplicatedStorage.ClientServer.RotateHead:FireServer(y)
    end
end)

InventoryManager.Listen("Equip", function(plr: Player, item: ItemTypes.Item | ItemTypes.Weapon)
    ControlManager.Register("Primary Fire", true, function(action, state, input, toggled)
        while input.UserInputState == Enum.UserInputState.Begin do
            ReplicatedStorage.ClientServer.PrimaryFire:FireServer(workspace.CurrentCamera:ViewportPointToRay(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2, 1))
            task.wait()
        end
        return Enum.ContextActionResult.Sink
    end)
    
    ControlManager.Register("Alternate Fire", true, function(action, state, input, toggled)
        if state ~= Enum.UserInputState.End then
            return Enum.ContextActionResult.Pass
        end
        ReplicatedStorage.ClientServer.AlternateFire:FireServer(workspace.CurrentCamera:ViewportPointToRay(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2, 1))
        return Enum.ContextActionResult.Sink
    end)
    
    ControlManager.Register("Drop", true, function()
        local equipped = InventoryManager.GetEquipped(Players.LocalPlayer)
        if not equipped then
            return Enum.ContextActionResult.Pass
        end
        InventoryManager.Drop(Players.LocalPlayer, equipped, Vector3.zero)
        return Enum.ContextActionResult.Sink
    end)
end)

InventoryManager.Listen("Unequip", function(plr: Player, item: ItemTypes.Item)
    if InventoryManager.GetEquipped(plr) then
        return
    end
    ControlManager.Unregister("Primary Fire")
    ControlManager.Unregister("Alternate Fire")
    ControlManager.Unregister("Drop")
    ControlManager.Unregister("Reload Weapon")

    roundInfo.Frame.AmmoBar.Visible = false
end)

Players.LocalPlayer.CharacterRemoving:Connect(onDeath)