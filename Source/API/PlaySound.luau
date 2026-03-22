local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)

export type SoundId = number | Sound | string

export type SoundProperties = {
	Volume: number?,
	RollOffMinDistance: number?,
	RollOffMaxDistance: number?,
	SoundGroup: SoundGroup?,
	PlaybackRegion: NumberRange?,
	TimePosition: number?,
	Looped: boolean?,
}

local PlaySound = {}

function PlaySound.PlaySound(sound: SoundId | {SoundId}, position: Vector3?, parent: Instance?, props: SoundProperties?, to: Player?): Sound?
	return _PlaySound.PlaySound(sound, position, parent, props, to)
end

function PlaySound.MakeSound(sound: SoundId | {SoundId}, props: SoundProperties?): Sound
	return _PlaySound.MakeSound(sound, props)
end

setmetatable(PlaySound, {
	__call = function(self, sound: SoundId | {SoundId}, position: Vector3?, parent: Instance?, props: SoundProperties?, to: Player?): Sound?
		return PlaySound.PlaySound(sound, position, parent, props, to)
	end
})

return table.freeze(PlaySound)