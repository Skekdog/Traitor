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
	TimePosition: number?,

	Effects: {SoundEffect}?,

	RollOffMinDistance: nil,
	RollOffMaxDistance: nil,
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

	sound.Name = properties.Name or "Sound"
	sound.AudioContent = properties.Content

	sound.Volume = properties.Volume or 0.5

	sound.RollOffMinDistance = properties.RolloffStart or 10
	sound.RollOffMaxDistance = properties.RolloffEnd or 10000

	sound.TimePosition = properties.TimePosition or 0

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
--- If possible, prefer to use `Audio.PlayIn()` for better performance and caching.
function Audio.PlayAt(referenceSound: Sound, position: Vector3, noClone: boolean?, to: Player?): ()
	local sound = if noClone then referenceSound else referenceSound:Clone()
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

-- Caches by reference sound to instances mapped to the actual sound that should play
local soundCache: {[Sound]: {[Instance]: Sound?}?} = {}

--- Plays a sound in an instance. Unless specified, the sound will be cloned and cached.
function Audio.PlayIn(referenceSound: Sound, instance: BasePart | Attachment | SoundService, noClone: boolean?, noCache: boolean?, to: Player?): ()
	if not instance.Parent then
		return
	end

	local cachedSound: Sound?
	if not noCache then
		local cache = soundCache[referenceSound]
		if cache then
			cachedSound = cache[instance]
		end
	end

	if cachedSound then
		cachedSound:Play()
		return
	end

	local sound = if noClone then referenceSound else referenceSound:Clone()
	applyBaseProperties(sound)

	sound.Parent = instance

	if not noCache then
		local cache: {[Instance]: Sound?}? = soundCache[referenceSound]
		if not cache then
			cache = {}

			referenceSound.Destroying:Once(function()
				-- We can't use the same cache reference here, as InvalidateCache would remove it.
				-- That's not a problem here, but it means it will never be GC'ed until this event runs.
				local currentCache = soundCache[referenceSound]
				if not currentCache then
					return
				end

				for _, cachedSound in currentCache do
					assert(cachedSound)
					cachedSound:Destroy()
				end
				soundCache[referenceSound] = {}
			end)

			if instance ~= SoundService then
				instance.Destroying:Once(function()
					local currentCache = soundCache[referenceSound]
					if not currentCache then
						return
					end

					currentCache[instance] = nil
				end)
			end
		end

		assert(cache)

		cache[instance] = sound
		soundCache[referenceSound] = cache
	else
		sound.Ended:Once(function()
			sound:Destroy()
		end)
	end

	sound:Play()
end

--- Plays a 2D sound. A copy will be created if it is not cached.
function Audio.Play2D(referenceSound: Sound, noClone: boolean?, noCache: boolean?, to: Player?): ()
	Audio.PlayIn(referenceSound, SoundService, noClone, noCache)
end

--- Invalidates cache for the reference sound.
function Audio.InvalidateCache(referenceSound: Sound): ()
	local cache = soundCache[referenceSound]
	if not cache then
		return
	end

	for _, cachedSound in cache do
		assert(cachedSound)
		cachedSound:Destroy()
	end

	soundCache[referenceSound] = {}
end

return table.freeze(Audio)