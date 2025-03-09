require(script.Parent.Settings.LoadSettings)
require(script.Parent.KeybindHintManager)

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local CreateEmptyPart = require(ReplicatedStorage.RoundRule.Common.CreateEmptyPart)
local BulletTracer = require(script.Parent.BulletTracer)
local Discombobulate = require(script.Parent.Discombobulate)
local Flashbang = require(script.Parent.Flashbang)
local HighlightPlayer = require(script.Parent.HighlightPlayer)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local ShatterGlass = require(script.Parent.ShatterGlass)
local ShowAlert = require(script.Parent.ShowAlert)
local ThemesManager = require(script.Parent.ThemesManager)
local UIManager = require(script.Parent.UIManager)

local serverClient = ReplicatedStorage:WaitForChild("ServerClient")

serverClient.ShatterGlass.OnClientEvent:Connect(ShatterGlass)

ThemesManager.UpdateTheme("Dark")

serverClient.BulletTracer.OnClientEvent:Connect(BulletTracer)

local notice = UIManager.WaitForUI("Notice") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Notice)}
notice:ToggleVisible(true)

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

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)