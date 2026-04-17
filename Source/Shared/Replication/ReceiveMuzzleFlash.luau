local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local MuzzleFlash = require(ReplicatedStorage.Shared.Combat.MuzzleFlash)

local remote = GetRemote("MuzzleFlash", ReplicatedStorage.Remotes.ServerClient)

remote.OnClientEvent:Connect(MuzzleFlash)

return nil