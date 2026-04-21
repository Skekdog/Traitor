local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Audio = require(ReplicatedStorage.API.Audio)
local Types = require(ReplicatedStorage.API.Types)

local infected: Types.RoleDefinition = {
	Kind = "RoleDefinition",

	Name = "Infected",
	PluralName = "Infected",
	Description = "Infect everyone.",
	Color = Color3.fromRGB(42, 195, 42),
	Sound = Audio.MakeSound({
		Content = Content.fromAssetId(9042819926),
	}),

	Allegiance = {Kind = "Role", Role = "Infected"},
	Allies = {"Infected"},
	RevealedRoles = {"Survivor", "Infected"},
	HighlightedRoles = {"Survivor"},

	CanDoSuspiciousActions = true,
	CanSeeMissingInAction = true,
	CanUseActionNodes = true,
	CanTeamChat = true,
	IsEvil = true,

	WalkSpeed = 18,
	JumpPower = 22,
}

return table.freeze(infected)