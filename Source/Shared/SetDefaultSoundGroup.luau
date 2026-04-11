local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Audio = require(ReplicatedStorage.API.Audio)

Audio.SetDefaultSoundGroup(SoundService.AllSounds)

return nil