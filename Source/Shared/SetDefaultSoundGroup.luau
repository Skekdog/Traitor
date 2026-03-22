local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)

PlaySound.SetDefaultSoundGroup(SoundService.AllSounds)

return nil