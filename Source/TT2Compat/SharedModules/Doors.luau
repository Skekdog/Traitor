local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StandardDoor = require(ReplicatedStorage.Shared.Actions.StandardDoor)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local module = {}

function module.Use(self, door: Types.MapObject, counterClockwise: boolean): ()
	if RunService:IsServer() then
		StandardDoor({
			Door = door,
			Kind = "ServerRun" :: "ServerRun",
			Receive = {
				Kind = "HingeDoorServerReceive" :: "HingeDoorServerReceive",
				Direction = (if door:GetAttribute("Open") then nil else if not counterClockwise then "Clockwise" else "CounterClockwise") :: StandardDoor.Direction
			},
		})
		return
	end
	StandardDoor({Kind = "ClientInteraction" :: "ClientInteraction", Door = door})
end

return module