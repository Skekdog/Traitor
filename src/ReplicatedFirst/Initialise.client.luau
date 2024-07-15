local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local API = require(script.Parent.API)
local Discombobulate = require(script.Parent.Discombobulate)
local Flashbang = require(script.Parent.Flashbang)
local InventoryManager = require(script.Parent.InventoryManager)
local ItemTypes = require(script.Parent.ItemsManager.ItemTypes)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local Types = require(script.Parent.RoundHandler.Types)
local ShatterGlass = require(script.Parent.ShatterGlass)
local StandardDoor = require(script.Parent.StandardDoor)
local UIManager = require(script.Parent.UIManager)

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

serverClient.MakeBulletHole.OnClientEvent:Connect(function(part: BasePart, position: Vector3, normal: Vector3)
    local impactHole = Instance.new("Part")
    impactHole.Anchored = false
    impactHole.Transparency = 1
    impactHole.Size = Vector3.new(0.5, 0.5, 0.1)
    impactHole.CFrame = CFrame.lookAt(position, position + normal)
    
    impactHole.CanCollide = false
    impactHole.CanTouch = false
    impactHole.CanQuery = false
    impactHole.Massless = true
    
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
local activeTween: Tween?
local function setAmmo(current: number, magazineSize: number, reserve: number, noTransition: boolean?)
    ammoBar.AmmoLabel.Text = `{current} / {magazineSize} + {reserve}`
    if activeTween then
        activeTween:Cancel()
    end
    activeTween = API.Animate(ammoBar.Background, TweenInfo.new(0.1), {Size = UDim2.new(current / magazineSize, 0, 1, 0)}, noTransition)
end

InventoryManager.Listen("Equip", function(plr: Player, item: ItemTypes.Item)
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

LocalRoundInfo.Listen("RoundPhase", function(p)
    local phase: Types.RoundPhase = p :: Types.RoundPhase
    if phase == "Destroy" then
        workspace.Projectiles:ClearAllChildren()
        workspace.RadarPoints:ClearAllChildren()
    end
end)

serverClient.AmmoUpdate.OnClientEvent:Connect(setAmmo)
serverClient.Discombobulate.OnClientEvent:Connect(Discombobulate)
serverClient.Flashbang.OnClientEvent:Connect(Flashbang)