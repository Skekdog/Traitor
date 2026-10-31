local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local MuzzleFlash = require(ReplicatedStorage.Shared.Combat.MuzzleFlash)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local remote = GetRemote("MuzzleFlash", ReplicatedStorage.Remotes.ServerClient)

remote.OnClientEvent:Connect(function(gun: Types.MapObject?)
	if not gun then
		return
	end

	MuzzleFlash(gun)
end)

return nil