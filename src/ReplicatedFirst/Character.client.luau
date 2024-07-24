local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AimWeaponClient = require(script.Parent.AimWeaponClient)
local ControlManager = require(script.Parent.ControlManager)
local InventoryManager = require(script.Parent.InventoryManager)
local ItemTypes = require(script.Parent.ItemsManager.ItemTypes)
local Items = require(script.Parent.ItemsManager.Items)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local UIAnimation = require(script.Parent.UIAnimation)
local UIManager = require(script.Parent.UIManager)
local Viewmodel = require(script.Parent.Viewmodel)

local roundInfo = UIManager.WaitForUI("RoundInfo").Object :: typeof(UIManager.UnregisteredUIs.RoundInfo)

local function setHealth(hum: Humanoid)
    roundInfo.Frame.HealthBar.HealthLabel.Text = tostring(math.round(hum.Health))
    UIAnimation.Slider(roundInfo.Frame.HealthBar.Background, false, hum.Health, hum.MaxHealth)
end

local function onDeath()
    LocalRoundInfo.SetSpectating(true)
    roundInfo.Frame.HealthBar.Visible = false
end

local clientServer = ReplicatedStorage:WaitForChild("ClientServer")

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
        clientServer.RotateHead:FireServer(y)
    end
end)

local function getCenterRay(): Ray
    local camera = workspace.CurrentCamera
    return camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
end

InventoryManager.Listen("Equip", function(plr: Player, item: ItemTypes.Item)
    Viewmodel.Show(item)
    
    local base = Items[item.Base.Name] :: ItemTypes.ItemDefinition & ItemTypes.GunDefinition
    if (item.Kind == "Item" and base.PrimaryFire) or (item.Kind == "Gun" or item.Kind == "Grenade" or item.Kind == "Melee") then
        ControlManager.Register("Primary Fire", true, function(action, _, input)
            if item.Kind == "Item" and base.Toggled then
                if input.UserInputState == Enum.UserInputState.End then
                    clientServer.PrimaryFire:InvokeServer(getCenterRay())
                end
            else
                while input.UserInputState == Enum.UserInputState.Begin do
                    if clientServer.PrimaryFire:InvokeServer(getCenterRay()) and item.Kind ~= "Item" then
                        LocalRoundInfo.PrimaryFire(item)
                    end
                    task.wait()
                    if item.Kind == "Gun" then
                        if LocalRoundInfo.Ammo and LocalRoundInfo.Ammo <= 0 then
                            clientServer.ReloadWeapon:FireServer()
                        end
                    end
                end
            end
            return Enum.ContextActionResult.Sink
        end)
    else
        ControlManager.Unregister("Primary Fire")
    end
    
    if (item.Kind == "Item" and base.AlternateFire) or (item.Kind == "Gun") then
        ControlManager.Register("Alternate Fire", true, function(action, state, input)
            if item.Kind == "Gun" then
                return AimWeaponClient.Aim(input)
            elseif item.Kind == "Item" then
                if item.Base.ToggledAlt then
                    if input.UserInputState == Enum.UserInputState.End then
                        clientServer.AlternateFire:FireServer(getCenterRay())
                        return Enum.ContextActionResult.Sink
                    else
                        return Enum.ContextActionResult.Pass
                    end
                end
                
                clientServer.AlternateFire:FireServer(getCenterRay())
                return Enum.ContextActionResult.Sink
            end
            return Enum.ContextActionResult.Sink
        end)
    else
        ControlManager.Unregister("Alternate Fire")
    end
    
    if base.CanDrop then
        ControlManager.Register("Drop", true, function()
            local equipped = InventoryManager.GetEquipped(plr)
            if not equipped then
                return Enum.ContextActionResult.Pass
            end
            InventoryManager.Drop(plr, equipped, Vector3.zero)
            return Enum.ContextActionResult.Sink
        end)
    else
        ControlManager.Unregister("Drop")
    end

    if item.Kind == "Gun" and base.AmmoType then
        ControlManager.Register("Reload Weapon", true, function()
            local equipped = InventoryManager.GetEquipped(plr)
            if not equipped then
                return Enum.ContextActionResult.Pass
            end
            clientServer.ReloadWeapon:FireServer()
            return Enum.ContextActionResult.Sink
        end)

        ControlManager.Register("Drop Ammo", true, function(action, state, input)
            local equipped = InventoryManager.GetEquipped(plr)
            if not equipped then
                return Enum.ContextActionResult.Pass
            end
            clientServer.DropAmmo:FireServer()
            return Enum.ContextActionResult.Sink
        end)
    else
        ControlManager.Unregister("Reload Weapon")
        ControlManager.Unregister("Drop Ammo")
    end
end)

InventoryManager.Listen("Unequip", function(plr: Player, item: ItemTypes.Item)
    if InventoryManager.GetEquipped(plr) then
        return
    end
    ControlManager.Unregister("Primary Fire")
    ControlManager.Unregister("Alternate Fire")
    ControlManager.Unregister("Drop")
    ControlManager.Unregister("Reload Weapon")
    ControlManager.Unregister("Drop Ammo")

    Viewmodel.Hide()

    roundInfo.Frame.AmmoBar.Visible = false
end)

Players.LocalPlayer.CharacterRemoving:Connect(onDeath)