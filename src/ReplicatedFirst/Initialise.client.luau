local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ClientWeaponManager = require(script.Parent.WeaponsManagerClient)
local CreateEmptyPart = require(script.Parent.CreateEmptyPart)
local Discombobulate = require(script.Parent.Discombobulate)
local Flashbang = require(script.Parent.Flashbang)
local InventoryManager = require(script.Parent.InventoryManagerClient)
local ItemTypes = require(script.Parent.ItemTypes)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local Types = require(script.Parent.RoundHandler.Types)
local ShatterGlass = require(script.Parent.ShatterGlass)
local StandardDoor = require(script.Parent.StandardDoor)
local UIManager = require(script.Parent.UIManager)
local ShowMessage = require(script.Parent.UIManager.UIScripts.ShowMessage)
local Viewmodel = require(script.Parent.Viewmodel)

local serverClient = ReplicatedStorage:WaitForChild("ServerClient")

serverClient.ShatterGlass.OnClientEvent:Connect(ShatterGlass)

serverClient.TweenProjectile.OnClientEvent:Connect(function(projectile: PVInstance, origin: Vector3, targetPosition: Vector3, speed: number)
    projectile = projectile:Clone()
    projectile:PivotTo(CFrame.lookAt(origin, targetPosition))
    local tween = TweenService:Create(projectile, TweenInfo.new((origin - targetPosition).Magnitude / speed), {Position = targetPosition})
    tween.Completed:Once(function()
        projectile:Destroy()
    end)
    
    tween:Play()
    
    projectile.Parent = workspace.Projectiles
end)

serverClient.TweenSlidingDoor.OnClientEvent:Connect(function(door: BasePart, initialCFrame: CFrame, targetCFrame: CFrame): ()
    door.CFrame = initialCFrame
    TweenService:Create(door, TweenInfo.new(1, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play()
end)

serverClient.TweenStandardDoor.OnClientEvent:Connect(StandardDoor)

serverClient.MakeBulletHole.OnClientEvent:Connect(function(part: BasePart, relativeCFrame: CFrame, normal: Vector3)
    local position = part.CFrame:ToWorldSpace(relativeCFrame).Position
    local impactHole = CreateEmptyPart(CFrame.lookAt(position, position + normal))
    impactHole.Anchored = false
    impactHole.Size = Vector3.new(0.5, 0.5, 0.1)
    
    local impactDecal = Instance.new("Decal")
    impactDecal.Texture = "rbxassetid://130624105"
    impactDecal.Parent = impactHole
    
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = part
    weld.Part1 = impactHole
    weld.Parent = part

    task.delay(5, function()
        if not impactHole:IsDescendantOf(workspace) then
            return
        end
        local tween = TweenService:Create(impactDecal, TweenInfo.new(5), {Transparency = 1})
        tween.Completed:Connect(function()
            if not impactHole:IsDescendantOf(workspace) then
                return
            end
            weld:Destroy()
            impactHole:Destroy()
        end)

        impactHole.Destroying:Once(function()
            if tween.PlaybackState == Enum.PlaybackState.Playing then
                tween:Cancel()
            end
        end)

        tween:Play()
    end)
    
    impactHole.Parent = part
end)

local roundInfo = UIManager.WaitForUI("RoundInfo").Object :: typeof(UIManager.UnregisteredUIs.RoundInfo)
local ammoBar = roundInfo.Frame.AmmoBar

InventoryManager.Listen("Equip", function(item: ItemTypes.Item)
    ammoBar.Visible = item.Kind == "Gun"
end)

-- shitty problems require shitty solutions - Sun Tzu, the art of war
workspace.Corpses.ChildAdded:Connect(function(child)
    while child.Parent do
        for _, v in child:GetDescendants() do
            if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                v.CanCollide = true
            end
        end
        task.wait()
    end
end)

LocalRoundInfo.Listen("RoundPhase", function(phase: Types.RoundPhase)
    if phase == "Destroy" then
        workspace.Projectiles:ClearAllChildren()
        workspace.RadarPoints:ClearAllChildren()
    end
end)

serverClient.AmmoUpdate.OnClientEvent:Connect(ClientWeaponManager.SetAmmo)
serverClient.Discombobulate.OnClientEvent:Connect(Discombobulate)
serverClient.Flashbang.OnClientEvent:Connect(Flashbang)
serverClient.PlayViewmodelAnimation.OnClientEvent:Connect(Viewmodel.PlayAnimation)
serverClient.SetReloadingStatus.OnClientEvent:Connect(ClientWeaponManager.SetReloadingStatus)
ReplicatedStorage:WaitForChild("RoundHandler").SendMessage.OnClientEvent:Connect(ShowMessage)