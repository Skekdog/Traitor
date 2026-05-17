local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Audio = require(ReplicatedStorage.API.Audio)
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local Gamepass = require(ReplicatedStorage.Shared.Monetisation.Gamepass)
local GamepassIDs = require(ReplicatedStorage.Shared.Monetisation.GamepassIDs)

local remote = GetRemote("SoundPlayer", ReplicatedStorage)

remote.OnServerEvent:Connect(function(player, id: unknown): ()
	if typeof(id) ~= "number" then
		return
	end

	local char = player.Character
	if not char then
		return
	end

	local root = char.PrimaryPart
	if not root then
		return
	end

	if not Gamepass.IsOwned(GamepassIDs["Sound Player"], player) then
		return
	end

	local lastSound = root:FindFirstChild("SoundPlayer")
	if lastSound then
		lastSound:Destroy()
	end

	local sound = Audio.MakeSound({
		Name = "SoundPlayer",
		Content = Content.fromAssetId(id),
		RolloffStart = 10,
		RolloffEnd = 35,
	})

	sound.Archivable = false

	Audio.PlayIn(sound, root, true, true)
end)

return nil