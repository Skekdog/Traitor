local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Audio = require(ReplicatedStorage.API.Audio)

local module = {}

function module.Play2D(self, sound: Sound): ()
	Audio.Play2D(sound, nil, true)
end

function module.PlayIn(self, sound: Sound, part: BasePart): ()
	Audio.PlayIn(sound, part, nil, true)
end

-- what the fuck is the logic in what has self parameter and what doesn't
function module.PlayAt(sound: Sound, position: Vector3): ()
	Audio.PlayAt(sound, position)
end

return table.freeze(module)