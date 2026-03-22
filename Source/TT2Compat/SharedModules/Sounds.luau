local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)

local module = {}

function module.Create(self, soundData: {Ids: {number}?, Volume: number?, Looped: boolean?, TimePosition: number?}, _: "Game"): Sound
	return PlaySound.MakeSound(soundData.Ids or {}, {
		Volume = soundData.Volume,
		Looped = soundData.Looped,
		TimePosition = soundData.TimePosition,
	})
end

return table.freeze(module)