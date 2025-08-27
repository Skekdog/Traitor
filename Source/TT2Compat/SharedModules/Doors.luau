local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StandardDoor = require(ReplicatedStorage.Shared.Actions.StandardDoor)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local module = {}

function module.Use(self, door: Types.MapThing, _: boolean): ()
	if RunService:IsServer() then
		StandardDoor({
			Door = door,
			Kind = "ServerRun" :: "ServerRun",
			Open = not door:GetAttribute("Open"),
		})
		return
	end
	StandardDoor({Kind = "ClientInteraction" :: "ClientInteraction", Door = door})
end

return module