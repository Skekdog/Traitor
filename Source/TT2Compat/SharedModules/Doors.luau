local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StandardDoor = require(ReplicatedStorage.Shared.Actions.StandardDoor)

local module = {}

function module.Use(self, door: BasePart, _: boolean): ()
	StandardDoor({Kind = "ClientInteraction" :: "ClientInteraction", Door = door})
end

return module