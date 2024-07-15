local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local API = require(script.Parent.API)
local ControlManager = require(script.Parent.ControlManager)
local InventoryManager = require(script.Parent.InventoryManager)
local ItemTypes = require(script.Parent.ItemsManager.ItemTypes)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local UIManager = require(script.Parent.UIManager)

local roundInfo = UIManager.WaitForUI("RoundInfo").Object :: typeof(UIManager.UnregisteredUIs.RoundInfo)

local activeTween: Tween?
local function setHealth(hum: Humanoid)
    roundInfo.Frame.HealthBar.HealthLabel.Text = tostring(math.round(hum.Health))
    if activeTween then
        activeTween:Cancel()
    end
    activeTween = API.Animate(roundInfo.Frame.HealthBar.Background, TweenInfo.new(0.1),  {Size = UDim2.new(hum.Health / hum.MaxHealth, 0, 1, 0)})
end

local function onDeath()
    LocalRoundInfo.SetSpectating(true)
    roundInfo.Frame.HealthBar.Visible = false
end

Players.LocalPlayer.CharacterAdded:Connect(function(char: Model)
    LocalRoundInfo.SetSpectating(false)

    local hum = char:WaitForChild("Humanoid") :: Humanoid
    hum.Died:Once(onDeath)

    roundInfo.Frame.HealthBar.Visible = true

    setHealth(hum)
    hum:GetPropertyChangedSignal("Health"):Connect(function()
        setHealth(hum)
    end)

    hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)
    
    local root = char:WaitForChild("HumanoidRootPart", 2)
    if root then
        local run = root:WaitForChild("Running", 1)
        local death = root:WaitForChild("Died", 1)
        
        if run then
            run:Destroy()
        end
        if death then
            death:Destroy()
        end
    end

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
        if item.Kind == "Item" and item.Base.Toggled then
            if input.UserInputState == Enum.UserInputState.End then
                ReplicatedStorage.ClientServer.PrimaryFire:FireServer(workspace.CurrentCamera:ViewportPointToRay(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2, 1))
            end
        else
            while input.UserInputState == Enum.UserInputState.Begin do
                ReplicatedStorage.ClientServer.PrimaryFire:FireServer(workspace.CurrentCamera:ViewportPointToRay(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2, 1))
                task.wait()
            end
        end
        return Enum.ContextActionResult.Sink
    end)
    
    ControlManager.Register("Alternate Fire", true, function(action, state, input, toggled)
        ReplicatedStorage.ClientServer.AlternateFire:FireServer(workspace.CurrentCamera:ViewportPointToRay(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2, 1))
        return Enum.ContextActionResult.Sink
    end)
    
    ControlManager.Register("Drop", true, function()
        local equipped = InventoryManager.GetEquipped(plr)
        if not equipped then
            return Enum.ContextActionResult.Pass
        end
        InventoryManager.Drop(plr, equipped, Vector3.zero)
        return Enum.ContextActionResult.Sink
    end)

    ControlManager.Register("Reload Weapon", true, function()
        local equipped = InventoryManager.GetEquipped(plr)
        if not equipped then
            return Enum.ContextActionResult.Pass
        end
        ReplicatedStorage.ClientServer.ReloadWeapon:FireServer()
        return Enum.ContextActionResult.Sink
    end)

    ControlManager.Register("Drop Ammo", true, function(action, state, input, toggled)
        local equipped = InventoryManager.GetEquipped(plr)
        if not equipped then
            return Enum.ContextActionResult.Pass
        end
        ReplicatedStorage.ClientServer.DropAmmo:FireServer()
        return Enum.ContextActionResult.Sink
    end)
end)

InventoryManager.Listen("Unequip", function(plr: Player, item: ItemTypes.Item | ItemTypes.Weapon)
    if InventoryManager.GetEquipped(plr) then
        return
    end
    ControlManager.Unregister("Primary Fire")
    ControlManager.Unregister("Alternate Fire")
    ControlManager.Unregister("Drop")
    ControlManager.Unregister("Reload Weapon")
    ControlManager.Unregister("Drop Ammo")

    roundInfo.Frame.AmmoBar.Visible = false
end)

Players.LocalPlayer.CharacterRemoving:Connect(onDeath)