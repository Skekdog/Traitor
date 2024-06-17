--!strict
-- Based off of GMod TTT.
local ReplicatedFirst = game.ReplicatedFirst
local ReplicatedStorage = (game :: any):GetService("ReplicatedStorage")

local Types = require(ReplicatedFirst.RoundHandler.Types)
local common = require(script.Parent.Common)

local items = ReplicatedStorage.WeaponModels

local module: Types.Gamemode = {
	Name = "Classic Deathmatch",
	Description = "Back to Basics",
	Authors = "@louisd5",

	EngineVersion = "0.0.1",

	MinimumPlayers = 1,
	RecommendedPlayers = 4,
	MaximumPlayers = 8,

	TimeoutVictors = "Fighter 1",
	PhyrricVictors = "Fighter 1",
	
	CalculateRoundHighlights = function(self, round)
	return {}
	end,
	FriendlyFire = false,
	SelfDefense = false,
	UseKarma = false,

	StartingEquipment = {"Crowbar", "Pistol"},
	AvailableEquipment = {
		{
			Name = "Crowbar",
			Description = "Become a Gordonite",
			Icon = "rbxassetid://",
			AttackType = "Blunt",

			Item = items.Crowbar
		},
		{
			Name = "Pistol",
			Description = "Reliable",
			Icon = "rbxassetid://",
			AttackType = "Firearm",

			Item = items.Pistol
		},
		{
			Name = "Assault Rifle",
			Description = "pewpewpew",
			Icon = "rbxassetid://",
			AttackType = "Firearm",

			Item = items["Assault Rifle"]
		},
		{
			Name = "XM1014",
			Description = "bang bang bang",
			Icon = "rbxassetid://",
			AttackType = "Firearm",

			Item = items.XM1014
		}
	} :: {Types.Equipment},

	Roles = {
		{
			Name = "Fighter 1",
			FormattedName = "<font color='#ff0000'>Traitor</font>",
			Description = "You against the rest of the fighters, go beat em all!",
			Colour = Color3.new(1, 0, 0),
			Allies = {"Fighter 1"},
			Allegiance = "Fighter 1",
			VictoryMusic = ReplicatedStorage.VictoryMusic.Traitor:GetChildren() :: any,
			VictoryText = "Fighter 1 has won the round!",
			AnnounceDisconnect = false,
			CanSeeMissing = true,
			Extras = {
				AssignmentPriority = 1,
			}
		},		
		{
			Name = "Fighter 2",
			FormattedName = "<font color='#ff0000'>Traitor</font>",
			Description = "You against the rest of the fighters, go beat em all!",
			Colour = Color3.new(1, 0, 0),
			Allies = {"Fighter 2"},
			Allegiance = "Fighter 2",
			VictoryMusic = ReplicatedStorage.VictoryMusic.Traitor:GetChildren() :: any,
			VictoryText = "Fighter 2 has won the round!",
			AnnounceDisconnect = false,
			CanSeeMissing = true,
			Extras = {
				AssignmentPriority = 2,
			}
		},
		{
			Name = "Fighter 3",
			FormattedName = "<font color='#ff0000'>Traitor</font>",
			Description = "You against the rest of the fighters, go beat em all!",
			Colour = Color3.new(1, 0, 0),
			Allies = {"Fighter 3"},
			Allegiance = "Fighter 3",
			VictoryMusic = ReplicatedStorage.VictoryMusic.Traitor:GetChildren() :: any,
			VictoryText = "Fighter 3 has won the round!",
			AnnounceDisconnect = false,
			CanSeeMissing = true,
			Extras = {
				AssignmentPriority = 3,
			}
		},
		{
			Name = "Fighter 4",
			FormattedName = "<font color='#ff0000'>Traitor</font>",
			Description = "You against the rest of the fighters, go beat em all!",
			Colour = Color3.new(1, 0, 0),
			Allies = {"Fighter 4"},
			Allegiance = "Fighter 4",
			VictoryMusic = ReplicatedStorage.VictoryMusic.Traitor:GetChildren() :: any,
			VictoryText = "Fighter 4 has won the round!",
			AnnounceDisconnect = false,
			CanSeeMissing = true,
			Extras = {
				AssignmentPriority = 4,
			}
		},
		{
			Name = "Fighter 5",
			FormattedName = "<font color='#ff0000'>Traitor</font>",
			Description = "You against the rest of the fighters, go beat em all!",
			Colour = Color3.new(1, 0, 0),
			Allies = {"Fighter 5"},
			Allegiance = "Fighter 5",
			VictoryMusic = ReplicatedStorage.VictoryMusic.Traitor:GetChildren() :: any,
			VictoryText = "Fighter 5 has won the round!",
			AnnounceDisconnect = false,
			CanSeeMissing = true,
			Extras = {
				AssignmentPriority = 5,
			}
		},
		{
			Name = "Fighter 6",
			FormattedName = "<font color='#ff0000'>Traitor</font>",
			Description = "You against the rest of the fighters, go beat em all!",
			Colour = Color3.new(1, 0, 0),
			Allies = {"Fighter 6"},
			Allegiance = "Fighter 6",
			VictoryMusic = ReplicatedStorage.VictoryMusic.Traitor:GetChildren() :: any,
			VictoryText = "Fighter 6 has won the round!",
			AnnounceDisconnect = false,
			CanSeeMissing = true,
			Extras = {
				AssignmentPriority = 6,
			}
		},
		{
			Name = "Fighter 7",
			FormattedName = "<font color='#ff0000'>Traitor</font>",
			Description = "You against the rest of the fighters, go beat em all!",
			Colour = Color3.new(1, 0, 0),
			Allies = {"Fighter 7"},
			Allegiance = "Fighter 7",
			VictoryMusic = ReplicatedStorage.VictoryMusic.Traitor:GetChildren() :: any,
			VictoryText = "Fighter 7 has won the round!",
			AnnounceDisconnect = false,
			CanSeeMissing = true,
			Extras = {
				AssignmentPriority = 7,
			}
		},
		{
			Name = "Fighter 8",
			FormattedName = "<font color='#ff0000'>Traitor</font>",
			Description = "You against the rest of the fighters, go beat em all!",
			Colour = Color3.new(1, 0, 0),
			Allies = {"Fighter 8"},
			Allegiance = "Fighter 8",
			VictoryMusic = ReplicatedStorage.VictoryMusic.Traitor:GetChildren() :: any,
			VictoryText = "Fighter 8 has won the round!",
			AnnounceDisconnect = false,
			CanSeeMissing = true,
			Extras = {
				AssignmentPriority = 8,
			}
		}

	},

	AssignRoles = function(self, participants)
		-- Participants are already shuffled, no need to do it here
		local roles = self.Roles
		-- Sort roles by lowest AssignmentPriority. These roles will be assigned first.
		-- The greatest value for AssignmentPriority is used as a backup role for anyone who did not receive their role.
		-- Lower AssignmentPriority values will be used first, if there are not enough players for a proper round.
		-- e.g, Traitor will be assigned first, then detective. In a one player server, there will only be a Traitor.
		local roleToAssign, roleToAssignIndex = roles[1], 1
		local counter = 1
		for i, v in ipairs(participants) do
			local roleToAssign = "Fighter " .. counter
			v:AssignRole(roles[counter])
			counter = counter + 1
		end
	end,

	OnDeath = function(self, victim)
		local round = victim.Round
		if round:IsRoundOver() then
			return
		end

		local winner = common.TestForOneSurvivingRole(self, round)
		if winner then
			round:EndRound(round:GetRoleFromName(winner))
		end
	end,

	Duration = function(self, numParticipants)
		return 30 + (numParticipants * 30)
	end,

	OnCharacterLoad = function(self, char)
		local healthScript = char:FindFirstChild("Health")
		if healthScript then
			healthScript:Destroy()
		end
	end
}

return module