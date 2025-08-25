local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StandardDoor = require(ReplicatedStorage.Shared.Actions.StandardDoor)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local module = {}

function module.Use(self, door: Types.MapThing, _: boolean): ()
	if RunService:IsServer() then
		local open = not door:GetAttribute("Open")
		local request: StandardDoor.ClientReceive = {
			Kind = "ClientReceive" :: "ClientReceive",
			Door = door,
			Open = open,
			TargetAngle = if open then math.rad(90) else 0,
			OriginalCFrame = door:GetAttribute("OriginalCFrame") :: CFrame? or GetPrimaryPart(door).CFrame,
		}
		ReplicatedStorage.Remotes.ClientServer.OpenDoor:FireAllClients(request)
		return
	end
	StandardDoor({Kind = "ClientInteraction" :: "ClientInteraction", Door = door})
end

return module