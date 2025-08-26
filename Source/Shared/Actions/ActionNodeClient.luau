local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

export type ActionNodeParams = {
	Adornee: Types.MapThing,
	Title: string,
	Cost: number,
	Cooldown: number,
	Radius: number,
	Action: (user: Types.Participant) -> (),
}



return nil