local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StandardGame = require(ReplicatedStorage.API.StandardGame)
local Types = require(ReplicatedStorage.API.Types)

local survivorRole: Types.RoleDefinition = {
	Kind = "RoleDefinition",

	Name = "Survivor",
	Description = "Fight for your life!",
	Color = Color3.new(1, 1, 1),
	Sound = "rbxassetid://9042823666",

	Allegiance = {Kind = "Role", Role = "Survivor"},
}

local bossRole: Types.RoleDefinition = {
	Kind = "RoleDefinition",

	Name = "Boss",
	Description = "",
	Color = Color3.new(1, 0, 0),
	Sound = "",

	Allegiance = {Kind = "Solo"},

	PluralName = "Bosses",
}

local gamemode: Types.GamemodeDefinition = {
	Name = "Boss",
	Description = "Why do I hear boss music?",
	Authors = "",

	MinimumPlayers = 1,

	TimeoutVictor = function(round)
		return round:GetRoleFromRoleName("Boss")
	end,

	EnableFriendlyFire = false,
	EnableKarma = false,

	GetRoundEndMusic = function()
		return nil
	end,

	AvailableItems = StandardGame.GetItems(),
	AvailableAmmo = StandardGame.GetAllAmmo(),
	InteractableDefinitions = StandardGame.GetInteractables(),

	Roles = {
		Boss = bossRole,
		Survivor = survivorRole,
	},

	StartingItems = {
		StandardGame.GetItem("Crowbar"),
		StandardGame.GetItem("Magneto Stick"),
	},

	Duration = function(round, numParticipants)
		return 120 + numParticipants * 10
	end,
}

return gamemode