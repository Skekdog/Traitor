local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsLabs = require(ReplicatedStorage.Shared.Places.IsLabs)

const Ban = {}

const KARMA_BAN_DURATION = 3600

function Ban.Temp(player: Player, duration: number, displayReason: string, privateReason: string): ()
	assert(not IsLabs, "Banning is not possible in labs")

	task.spawn(Players.BanAsync, Players, {
		UserIds = {player.UserId},
		ApplyToUniverse = true,
		Duration = duration,

		DisplayReason = displayReason,
		PrivateReason = privateReason,
	})
end

function Ban.Perm(player: Player, displayReason: string, privateReason: string): ()
	assert(not IsLabs, "Banning is not possible in labs")

	task.spawn(Players.BanAsync, Players, {
		UserIds = {player.UserId},
		ApplyToUniverse = true,
		Duration = -1,

		DisplayReason = displayReason,
		PrivateReason = privateReason,
	})
end

function Ban.Karma(player: Player): ()
	assert(not IsLabs, "Banning is not possible in labs")

	Ban.Temp(player, KARMA_BAN_DURATION, "Your karma is too low.", "Karma ban")
end

function Ban.Unban(userId: number): ()
	assert(not IsLabs, "Banning is not possible in labs")

	task.spawn(Players.UnbanAsync, Players, {
		UserIds = {userId},
		ApplyToUniverse = true,
	})
end

return table.freeze(Ban)