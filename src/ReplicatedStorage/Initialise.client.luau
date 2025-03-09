require(script.Parent.Settings.LoadSettings)
require(script.Parent.KeybindHintManager)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Flashbang = require(script.Parent.Flashbang)
local ThemesManager = require(script.Parent.ThemesManager)
local UIManager = require(script.Parent.UIManager)

require(script.Parent.MakeBulletHole)
require(script.Parent.Discombobulate)
require(script.Parent.ShowAlert)
require(script.Parent.BulletTracer)
require(script.Parent.ShatterGlass)
require(script.Parent.CorpseCollisionFix)
require(script.Parent.RemoveDefaultFootsteps)

local serverClient = ReplicatedStorage:WaitForChild("ServerClient")

ThemesManager.UpdateTheme("Dark")

local notice = UIManager.WaitForUI("Notice") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Notice)}
notice:ToggleVisible(true)

serverClient.Flashbang.OnClientEvent:Connect(Flashbang)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)