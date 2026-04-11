local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Audio = require(ReplicatedStorage.API.Audio)
local Doors = require(ReplicatedStorage.SharedModules.Doors)

type FireServerRemote = (targets: Player?, ...any) -> ()
type ServerRemote = {
	Fire: (ServerRemote, ...any) -> (),
	FireAllExcept: (ServerRemote, except: Player, ...any) -> (),

	_fire: FireServerRemote,
}

type FireClientRemote = (...any) -> ()
type ClientRemote = {
	Use: (ClientRemote, ...any) -> (),
	_fire: FireClientRemote,
}

local function UseClientRemote(self: ClientRemote, ...: any): ()
	self:_fire(...)
end

local function newClientRemote(fire: FireClientRemote): ClientRemote
	return {
		Use = UseClientRemote,
		_fire = fire,
	}
end

local function FireServerRemote(self: ServerRemote, ...: any): ()
	self._fire(nil, ...)
end

local function FireAllExcept(self: ServerRemote, except: Player, ...: any): ()
	local targets = Players:GetPlayers()

	for _, v in targets do
		if v ~= except then
			self._fire(v, ...)
		end
	end
end

local function newServerRemote(fire: FireServerRemote): ServerRemote
	return {
		Fire = FireServerRemote,
		FireAllExcept = FireAllExcept,

		_fire = fire
	}
end

local server = {}

local itemService = {}
server.ItemService = itemService

itemService.RelaySoundIn = newServerRemote(function(target: Player?, params: {SoundId: string, Volume: number, TimePosition: number}): ()
	local targets: {Player} = if target then {target} else Players:GetPlayers()
	for _, v in targets do
		local sound = Audio.MakeSound({
			Content = Content.fromUri(params.SoundId),
			Volume = params.Volume,
			TimePosition = params.TimePosition,
		})
		Audio.Play2D(sound, nil, nil, target)
	end
end)

local gamemodeService = {}
server.GamemodeService = gamemodeService

gamemodeService.SetCredits = newServerRemote(function(target: Player?, amount: number): ()
	return
	-- leave unimplemented because the only usage of this is traitor node callbacks.
	-- our implementation of traitor nodes will deduct credits directly, not within the callback.
end)


local client = {}
client.Doors = newClientRemote(Doors.Use)

return {
	Server = server,
	Client = client,
}