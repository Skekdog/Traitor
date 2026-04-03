local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)

export type ActionNodeParams = {
	Adornee: Types.MapObject,
	Title: string,
	Cost: number,
	Cooldown: number,
	Radius: number,
	Action: (user: Types.Participant) -> (),
}

return nil