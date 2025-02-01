local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local BulletTracer = require(script.Parent.BulletTracer)
local ClientInventory = require(script.Parent.ClientInventory)
local ClimbLadder = require(script.Parent.ClimbLadder)
local ControlManager = require(script.Parent.ControlManager)
local CreateEmptyPart = require(script.Parent.CreateEmptyPart)
local Discombobulate = require(script.Parent.Discombobulate)
local Flashbang = require(script.Parent.Flashbang)
local HighlightPlayer = require(script.Parent.HighlightPlayer)
local KeybindHintManager = require(script.Parent.KeybindHintManager)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local SettingsManager = require(script.Parent.SettingsManager)
local ShatterGlass = require(script.Parent.ShatterGlass)
local ShowAlert = require(script.Parent.ShowAlert)
local ThemesManager = require(script.Parent.ThemesManager)
local UIManager = require(script.Parent.UIManager)

local serverClient = ReplicatedStorage:WaitForChild("ServerClient")

serverClient.ShatterGlass.OnClientEvent:Connect(ShatterGlass)

ThemesManager.UpdateTheme("Dark")
KeybindHintManager()

serverClient.BulletTracer.OnClientEvent:Connect(BulletTracer)

local notice = UIManager.WaitForUI("Notice") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Notice)}
notice:ToggleVisible(true)

local crosshair = UIManager.WaitForUI("Crosshair") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Crosshair)}

ClientInventory.ConnectEquippedItemChanged(function(item)
    crosshair:ToggleVisible(not not item)
    if not item then
        return
    end

    if item.Kind == "Gun" then
        crosshair.Object.Size = UDim2.new(item.Definition.Spread * 5, 0, item.Definition.Spread * 5, 0) -- todo: these values ain't right
    else
        crosshair.Object.Size = UDim2.new()
    end
end)

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

LocalRoundInfo.Listen("Phase", function()
    if LocalRoundInfo.GetRoundPhase() == "Waiting" then
        for _, v in CollectionService:GetTagged("AllyMarker") do
            v:Destroy()
        end

        for _, v in Players:GetPlayers() do
            v:SetAttribute("Mark", "")
        end

        workspace.Projectiles:ClearAllChildren()
        workspace.RadarPoints:ClearAllChildren()
    end
end)

LocalRoundInfo.Listen("PlayerRole", function()
    for _, v in Players:GetPlayers() do
        if v ~= Players.LocalPlayer then
            HighlightPlayer(v)
        end
    end
end, true)

local function removeFootsteps(player: Player)
    if player == Players.LocalPlayer then
        return
    end
    player.CharacterAdded:Connect(function(char: Model)
        char:WaitForChild("HumanoidRootPart"):WaitForChild("Running"):Destroy()
    end)
end

Players.PlayerAdded:Connect(removeFootsteps)
for _, player in Players:GetPlayers() do
    removeFootsteps(player)
end

serverClient.Discombobulate.OnClientEvent:Connect(Discombobulate)
serverClient.Flashbang.OnClientEvent:Connect(Flashbang)
serverClient.SendAlert.OnClientEvent:Connect(ShowAlert)

LocalRoundInfo.Listen("Map", function()
    local map = LocalRoundInfo.GetMap()
    if not map then
        return
    end

    local bounds = map.Bounds

    for _, v in bounds:GetChildren() do
        if not v:IsA("BasePart") then
            continue
        end
        if v.Name == "Ladder" then
            v.CanTouch = true
            v.Touched:Connect(function(part)
                local char = Players.LocalPlayer.Character
                if char and part:IsDescendantOf(char) and SettingsManager.GetSetting("Snap to Ladders") and ClimbLadder.SnapCooldown < os.clock() then
                    ClimbLadder.SnapCooldown = os.clock() + 3
                    ClimbLadder.Climb(v)
                end
            end)
        end
    end
end, true)

local function onLocalCharacterAdded(char: Model): ()
    ControlManager.Register("Climb Ladder", true, function()
        local char = Players.LocalPlayer.Character
        if not char then
            return Enum.ContextActionResult.Pass
        end
    
        local root = char.PrimaryPart
        if not root then
            return Enum.ContextActionResult.Pass
        end
    
        local map = LocalRoundInfo.GetMap()
        if not map then
            return Enum.ContextActionResult.Pass
        end
    
        local bounds = map.Bounds
        if not bounds then
            return Enum.ContextActionResult.Pass
        end
    
        for _, v in root:GetTouchingParts() do
            if v.Name == "Ladder" and v:IsDescendantOf(bounds) then
                ClimbLadder.Climb(v)
                return Enum.ContextActionResult.Sink
            end
        end
    
        return Enum.ContextActionResult.Pass
    end)
end

local function onLocalCharacterRemoved(char: Model): ()
    ControlManager.Unregister("Climb Ladder")
end

Players.LocalPlayer.CharacterAdded:Connect(onLocalCharacterAdded)
Players.LocalPlayer.CharacterRemoving:Connect(onLocalCharacterRemoved)

if Players.LocalPlayer.Character then
    onLocalCharacterAdded(Players.LocalPlayer.Character)
end

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)