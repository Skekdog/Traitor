local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Audio = require(ReplicatedStorage.API.Audio)

return {
	Audio.MakeSound({
		Content = Content.fromAssetId(77825123688975),
		RolloffStart = 25,
		RolloffEnd = 50,
		Volume = 1
	}),

	Audio.MakeSound({
		Content = Content.fromAssetId(90810570393244),
		RolloffStart = 25,
		RolloffEnd = 50,
		Volume = 1
	}),

	Audio.MakeSound({
		Content = Content.fromAssetId(112769182475221),
		RolloffStart = 25,
		RolloffEnd = 50,
		Volume = 1
	}),

	Audio.MakeSound({
		Content = Content.fromAssetId(122713299649326),
		RolloffStart = 25,
		RolloffEnd = 50,
		Volume = 1
	}),

	Audio.MakeSound({
		Content = Content.fromAssetId(80965191101874),
		RolloffStart = 25,
		RolloffEnd = 50,
		Volume = 1
	}),

	Audio.MakeSound({
		Content = Content.fromAssetId(104406691271280),
		RolloffStart = 25,
		RolloffEnd = 50,
		Volume = 1
	}),
}