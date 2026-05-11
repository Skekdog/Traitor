local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Audio = require(ReplicatedStorage.API.Audio)
local StandardGame = require(ReplicatedStorage.API.StandardGame)
local Types = require(ReplicatedStorage.API.Types)

local survivor: Types.RoleDefinition = {
	Kind = "RoleDefinition",

	Name = "Survivor",
	Description = "Survive the end of the world...",
	Color = Color3.fromRGB(240, 0, 136),
	Sound = Audio.MakeSound({
		Content = Content.fromAssetId(9042819926),
	}),

	Allegiance = {Kind = "Role", Role = "Survivor"},
	Allies = {"Survivor"},
	RevealedRoles = {"Survivor", "Infected"},

	CanDoSuspiciousActions = true,
	CanSeeMissingInAction = true,
	CanTeamChat = true,

	AwardCreditsToRolesOnDeath = {
		Infected = 1,
	},

	EquipmentShop = {
		StandardGame.GetItem("HealthStation"),
		StandardGame.GetItem("Radar"),
		StandardGame.GetItem("Cheeze"),
		StandardGame.GetItem("Pigeon"),
		StandardGame.GetItem("BAR"),
		StandardGame.GetItem("Spoon"),
		StandardGame.GetItem("AWP"),
		StandardGame.GetItem("NyanGun"),
		StandardGame.GetItem("UMP"),
	}
}

return table.freeze(survivor)