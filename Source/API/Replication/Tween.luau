local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GetRemote = require(ReplicatedStorage.API.GetRemote)

local Tween = {}

local remote = GetRemote("ClientTween", ReplicatedStorage.Remotes.ServerClient)
function Tween.Tween(instance: Instance, tweenInfo: TweenInfo, propertyTable: {[string]: unknown}): ()
	remote:FireAllClients(instance, tweenInfo, propertyTable)
end

if RunService:IsClient() then
	remote.OnClientEvent:Connect(function(instance: Instance?, tweenInfo: TweenInfo, propertyTable: {[string]: unknown}): ()
		if not instance then
			return
		end

		TweenService:Create(instance, tweenInfo, propertyTable):Play()
	end)
end

return table.freeze(Tween)