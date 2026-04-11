local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Audio = require(ReplicatedStorage.API.Audio)
local Types = require(ReplicatedStorage.API.Types)

local function BreakSound(sound: Sound?): ()
	return function(prop: Types.Prop): ()
		Audio.PlayAt(sound or ReplicatedStorage.Assets.InteractableSounds.Broken, prop.Model:GetPivot().Position)
	end
end

return BreakSound