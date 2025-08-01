local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local StandardDoor = require(ReplicatedStorage.Shared.Actions.StandardDoor)
local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)

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
	self._fire(...)
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
		PlaySound(params.SoundId, nil, SoundService, {
			Volume = params.Volume,
			TimePosition = params.TimePosition,
		}, target)
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
client.Doors = newClientRemote(function(door: BasePart, _: boolean): ()
	StandardDoor({Kind = "ClientInteraction" :: "ClientInteraction", Door = door})
end)

return {
	Server = server,
	Client = client,
}