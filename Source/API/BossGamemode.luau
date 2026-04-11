local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Audio = require(script.Parent.Audio)
local StandardGame = require(ReplicatedStorage.API.StandardGame)
local Types = require(ReplicatedStorage.API.Types)

local survivorRole: Types.RoleDefinition = {
	Kind = "RoleDefinition",

	Name = "Survivor",
	Description = "Fight for your life!",
	Color = Color3.new(1, 1, 1),
	Sound = Audio.MakeSound({
		Content = Content.fromAssetId(9042823666),
	}),

	Allegiance = {Kind = "Role", Role = "Survivor"},
}

local bossRole: Types.RoleDefinition = {
	Kind = "RoleDefinition",

	Name = "Boss",
	Description = "",
	Color = Color3.new(1, 0, 0),
	Sound = Audio.MakeSound({
		Content = Content.none,
	}),

	Allegiance = {Kind = "Solo"},

	PluralName = "Bosses",
}

local BossGamemode: Types.GamemodeDefinition = {
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

	AssignRoles = function(round, participants)
		for _, participant in participants do
			participant:SetRole(survivorRole)
		end
	end,

	Duration = function(round, numParticipants)
		return 120 + numParticipants * 10
	end,
}

return table.freeze(BossGamemode)