local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaySound = require(ReplicatedStorage.API.PlaySound)
local Types = require(ReplicatedStorage.API.Types)

local function BreakSound(sound: Sound?): ()
	return function(prop: Types.Prop): ()
		PlaySound(sound or ReplicatedStorage.Assets.InteractableSounds.Broken, prop.Model:GetPivot().Position)
	end
end

return BreakSound