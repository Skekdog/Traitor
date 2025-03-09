require(script.Parent.Settings.LoadSettings)
require(script.Parent.KeybindHintManager)

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Flashbang = require(script.Parent.Flashbang)
local HighlightPlayer = require(script.Parent.HighlightPlayer)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local ShatterGlass = require(script.Parent.ShatterGlass)
local ThemesManager = require(script.Parent.ThemesManager)
local UIManager = require(script.Parent.UIManager)

require(script.Parent.MakeBulletHole)
require(script.Parent.Discombobulate)
require(script.Parent.ShowAlert)
require(script.Parent.BulletTracer)

local serverClient = ReplicatedStorage:WaitForChild("ServerClient")

serverClient.ShatterGlass.OnClientEvent:Connect(ShatterGlass)

ThemesManager.UpdateTheme("Dark")

local notice = UIManager.WaitForUI("Notice") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Notice)}
notice:ToggleVisible(true)

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

serverClient.Flashbang.OnClientEvent:Connect(Flashbang)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)