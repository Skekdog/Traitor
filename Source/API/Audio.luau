local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local CreateEmptyPart = require(ReplicatedStorage.Shared.RoundRule.Common.CreateEmptyPart)

local Audio = {}

type AudioProperties = {
	Content: Content,

	Name: string?,

	Volume: number?,

	RolloffStart: number?,
	RolloffEnd: number?,

	PlaybackRegion: NumberRange?,

	Effects: {SoundEffect}?,
}

local defaultSoundGroup: SoundGroup?
function Audio.SetDefaultSoundGroup(soundGroup: SoundGroup): ()
	defaultSoundGroup = soundGroup
end

local function applyBaseProperties(sound: Sound): ()
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	if not sound.SoundGroup and defaultSoundGroup then
		sound.SoundGroup = defaultSoundGroup
	end
end

--- Creates a `Sound` given input properties.
function Audio.MakeSound(properties: AudioProperties): Sound
	local sound = Instance.new("Sound")

	applyBaseProperties(sound)

	sound.AudioContent = properties.Content

	sound.Volume = properties.Volume or 0.5

	sound.RollOffMinDistance = properties.RolloffStart or 10
	sound.RollOffMaxDistance = properties.RolloffEnd or 10000

	if properties.PlaybackRegion then
		sound.PlaybackRegion = properties.PlaybackRegion
		sound.PlaybackRegionsEnabled = true
	end

	if properties.Effects then
		for _, effect in properties.Effects do
			effect:Clone().Parent = sound
		end
	end

	return sound
end

--- Plays a sound at the given position. A copy of the `Sound` is created.
function Audio.PlayAt(sound: Sound, position: Vector3, noClone: boolean?): ()
	if not noClone then
		sound = sound:Clone()
	end

	applyBaseProperties(sound)

	debug.profilebegin("CreatePart")
	local part = CreateEmptyPart(CFrame.new(position), {sound :: Instance})
	part.Parent = workspace.Projectiles
	debug.profileend()

	sound.Ended:Once(function()
		part:Destroy()
	end)

	debug.profilebegin("Play")
	sound:Play()
	debug.profileend()
end

local instanceCache: {[Instance]: {[string]: Sound?}?} = {}

--- Plays a sound in an instance. A copy will be created if it is not cached.
function Audio.PlayIn(sound: Sound, instance: BasePart | Attachment | SoundService, noClone: boolean?, cacheId: string?): ()
	if not instance.Parent then
		return
	end

	local cachedSound: Sound?
	if cacheId then
		local cache = instanceCache[instance]
		if cache then
			cachedSound = cache[cacheId]
		end
	end

	if not cachedSound then
		if not noClone then
			sound = sound:Clone()
		end
		applyBaseProperties(sound)

		sound.Name = cacheId or "Sound"
		sound.Parent = instance

		if cacheId then
			local cache = instanceCache[instance] or {}
			cache[cacheId] = sound
			instanceCache[instance] = cache
		else
			sound.Ended:Once(function()
				sound:Destroy()
			end)
		end
	else
		sound = cachedSound
	end

	sound:Play()
end

--- Plays a 2D sound. A copy will be created if it is not cached.
function Audio.Play2D(sound: Sound, noClone: boolean?, cacheName: string?): ()
	Audio.PlayIn(sound, SoundService, noClone, cacheName)
end

return table.freeze(Audio)