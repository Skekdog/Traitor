local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AimWeaponClient = require(script.Parent.AimWeaponClient)
local ClientWeaponManager = require(script.Parent.WeaponsManagerClient)
local ControlManager = require(script.Parent.ControlManager)
local InventoryManager = require(script.Parent.InventoryManagerClient)
local ItemHint = require(script.Parent.ItemHint)
local ItemTypes = require(script.Parent.ItemTypes)
local Items = require(script.Parent.Items)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local Types = require(script.Parent.RoundHandler.Types)
local ShowAlert = require(script.Parent.ShowAlert)
local UIAnimation = require(script.Parent.UIAnimation)
local UIManager = require(script.Parent.UIManager)
local Viewmodel = require(script.Parent.Viewmodel)

local roundInfo = UIManager.WaitForUI("RoundInfo").Object :: typeof(UIManager.UnregisteredUIs.RoundInfo)

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
        local death = root:WaitForChild("Died", 1)
        
        if death then
            death:Destroy()
        end
    end

    local camera = workspace.CurrentCamera
    while char.Parent do
        task.wait(1 / 20)
        local y = camera.CFrame:ToOrientation()
        local neck = char:FindFirstChild("Neck", true) :: Motor6D?
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

local function isDropObstructed(char: Model?): boolean
    if not char or not char.PrimaryPart then
        return true
    end

    local pos = char.PrimaryPart.Position

    local params = RaycastParams.new()
    params.IgnoreWater = true
    params.FilterDescendantsInstances = {LocalRoundInfo.GetMap() :: Types.MapStructureCast}
    params.FilterType = Enum.RaycastFilterType.Include
    params.RespectCanCollide = true
    params.CollisionGroup = "DroppedWeapons"

    local result = workspace:Raycast(pos, getCenterRay().Direction.Unit * 10, params)
    if result then
        ShowAlert("There is no room to drop anything here!")
        return true
    end
    return false
end

InventoryManager.Listen("Equip", function(item: ItemTypes.Item)
    ItemHint()
    Viewmodel.Show(item)

    if item.Kind == "Item" then
        ItemHint(item.Base.PrimaryHint, item.Base.AlternateHint)
    end
    
    local base = Items[item.Base.Name] :: ItemTypes.ItemDefinition & ItemTypes.GunDefinition
    if (item.Kind == "Item" and base.PrimaryFire) or (item.Kind == "Gun" or item.Kind == "Grenade" or item.Kind == "Melee") then
        ControlManager.Register("Primary Fire", true, function(action, _, input)
            if item.Kind == "Item" and base.Toggled then
                if input.UserInputState == Enum.UserInputState.End then
                    ClientWeaponManager.PrimaryFire(item)
                end
            else
                while input.UserInputState == Enum.UserInputState.Begin and InventoryManager.Equipped == item do
                    task.wait(ClientWeaponManager.PrimaryFire(item))
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
            local equipped = InventoryManager.Equipped
            if not equipped or isDropObstructed(Players.LocalPlayer.Character) then
                return Enum.ContextActionResult.Pass
            end
            InventoryManager.Drop(equipped, getCenterRay())
            return Enum.ContextActionResult.Sink
        end)
    else
        ControlManager.Unregister("Drop")
    end

    if item.Kind == "Gun" and base.AmmoType then
        ControlManager.Register("Reload Weapon", true, function()
            ClientWeaponManager.Reload(item)
            return Enum.ContextActionResult.Sink
        end)

        ControlManager.Register("Drop Ammo", true, function(action, state, input)
            local equipped = InventoryManager.Equipped
            if isDropObstructed(Players.LocalPlayer.Character) or not equipped then
                return Enum.ContextActionResult.Pass
            end
            clientServer.DropAmmo:FireServer(getCenterRay())
            return Enum.ContextActionResult.Sink
        end)
    else
        ControlManager.Unregister("Reload Weapon")
        ControlManager.Unregister("Drop Ammo")
    end
end)

InventoryManager.Listen("Unequip", function(item: ItemTypes.Item)
    if InventoryManager.Equipped then
        return
    end
    ControlManager.Unregister("Primary Fire")
    ControlManager.Unregister("Alternate Fire")
    ControlManager.Unregister("Drop")
    ControlManager.Unregister("Reload Weapon")
    ControlManager.Unregister("Drop Ammo")

    Viewmodel.Hide()
    ItemHint()

    roundInfo.Frame.AmmoBar.Visible = false
end)

Players.LocalPlayer.CharacterRemoving:Connect(onDeath)