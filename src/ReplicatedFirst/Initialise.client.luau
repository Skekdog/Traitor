local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local InventoryManager = require(script.Parent.InventoryManager)
local ItemTypes = require(script.Parent.ItemsManager.ItemTypes)
local SettingsManager = require(script.Parent.SettingsManager)
local ShatterGlass = require(script.Parent.ShatterGlass)
local UIManager = require(script.Parent.UIManager)

local serverClient = ReplicatedStorage:WaitForChild("ServerClient") :: typeof(ReplicatedStorage.ServerClient)

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

serverClient.MakeBulletHole.OnClientEvent:Connect(function(part: BasePart, position: Vector3, normal: Vector3)
    local impactHole = Instance.new("Part")
    impactHole.Anchored = false
    impactHole.Transparency = 1
    impactHole.Size = Vector3.new(0.5, 0.5, 0.1)
    impactHole.CFrame = CFrame.lookAt(position, position + normal)
    
    impactHole.CanCollide = false
    impactHole.CanTouch = false
    impactHole.CanQuery = false
    
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
local activeTween: Tween
local function setAmmo(current: number, magazineSize: number, reserve: number, noTransition: boolean?)
    if noTransition == nil then
        noTransition = not SettingsManager.GetSetting("Animate UI Transitions") :: boolean
    end

    ammoBar.AmmoLabel.Text = `{current} / {magazineSize} + {reserve}`
    if activeTween then
        activeTween:Cancel()
    end
    activeTween = TweenService:Create(ammoBar.Background, TweenInfo.new(if noTransition then 0 else 0.1), {Size = UDim2.new(current / magazineSize, 0, 1, 0)})
    activeTween:Play()
end

InventoryManager.Listen("Equip", function(plr: Player, item: ItemTypes.Item | ItemTypes.Weapon)
    if item.Base.Kind == "Item" then
        ammoBar.Visible = false
        return
    end

    local weapon = item :: ItemTypes.Weapon

    local isInf = weapon.CurrentAmmo == math.huge
	if isInf then
        ammoBar.Visible = false
		return
	end

    ammoBar.Visible = true
end)

serverClient.AmmoUpdate.OnClientEvent:Connect(setAmmo)