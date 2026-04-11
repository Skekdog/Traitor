local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Audio = require(ReplicatedStorage.API.Audio)

local module = {}

function module.Create(self, soundData: {Ids: {number}?, Volume: number?, Looped: boolean?, TimePosition: number?}, _: "Game"): Sound
	if not soundData.Ids then
		return Instance.new("Sound")
	end

	local id = soundData.Ids[math.random(#soundData.Ids)]

	return Audio.MakeSound({
		Content = Content.fromAssetId(id),
		Volume = soundData.Volume,
		Looped = soundData.Looped,
		TimePosition = soundData.TimePosition,
	})
end

return table.freeze(module)