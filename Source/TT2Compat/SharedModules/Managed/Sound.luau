local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local PlaySound = require(ReplicatedStorage.API.PlaySound)

local module = {}

function module.Play2D(self, sound: Sound): ()
	PlaySound(sound, nil, SoundService)
end

function module.PlayIn(self, sound: Sound, part: BasePart): ()
	PlaySound(sound, nil, part)
end

-- what the fuck is the logic in what has self parameter and what doesn't
function module.PlayAt(sound: Sound, position: Vector3): ()
	PlaySound(sound, position)
end

return table.freeze(module)