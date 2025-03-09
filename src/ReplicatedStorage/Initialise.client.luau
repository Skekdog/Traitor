require(script.Parent.Settings.LoadSettings)
require(script.Parent.KeybindHintManager)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Flashbang = require(script.Parent.Flashbang)

require(script.Parent.MakeBulletHole)
require(script.Parent.Discombobulate)
require(script.Parent.ShowAlert)
require(script.Parent.BulletTracer)
require(script.Parent.ShatterGlass)
require(script.Parent.CorpseCollisionFix)
require(script.Parent.RemoveDefaultFootsteps)
require(script.Parent.ResetRound)
require(script.Parent.InitialiseUI)

local serverClient = ReplicatedStorage:WaitForChild("ServerClient")
serverClient.Flashbang.OnClientEvent:Connect(Flashbang)