local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FaceIt = require(script.FaceIt)
local Health = require(script.Health)
local Types = require(ReplicatedStorage.API.Types)
local Interactables = require(ReplicatedStorage.Shared.GameDefinition.Interactables.Interactables)
local Ammo = require(ReplicatedStorage.Shared.GameDefinition.Items.Ammo)
local Items = require(ReplicatedStorage.Shared.GameDefinition.Items.Items)

local framedRole: Types.RoleDefinition = {
	Kind = "RoleDefinition",

	Name = "Framed",
	Description = "Find and kill your targets. Don't get caught red-handed.",
	Color = Color3.fromRGB(200, 44, 28),
	Sound = "rbxassetid://1848271648",

	Allegiance = {Kind = "Solo"},

	EquipmentShop = {},
	StartingItems = {},

	RevealedRoles = {"Police"},
	HighlightedRoles = {"Police"},

	CanSeeMissingInAction = true,
}

local policeRole: Types.RoleDefinition = {
	Kind = "RoleDefinition",

	Name = "Police",
	Description = "Kill anyone red-handed. Work with the Undercover.",
	Color = Color3.fromRGB(16, 108, 172),
	Sound = "rbxassetid://1848271643",

	Allegiance = {Kind = "Role", Role = "Police"},

	EquipmentShop = {},
	StartingItems = {},

	Allies = {"Police", "Undercover"},
	RevealedRoles = {"Police", "Undercover"},
	HighlightedRoles = {"Police", "Undercover"},

	CanSeeMissingInAction = true,
}

local undercoverRole: Types.RoleDefinition = {
	Kind = "RoleDefinition",

	Name = "Undercover",
	Description = "Kill anyone red-handed. Keep your identity secret.",
	Color = Color3.fromRGB(40, 140, 36),
	Sound = "rbxassetid://1839098267",

	Allegiance = {Kind = "Role", Role = "Police"},

	EquipmentShop = {},
	StartingItems = {},

	Allies = {"Police", "Undercover"},
	RevealedRoles = {"Police", "Undercover"},
	HighlightedRoles = {"Police", "Undercover"},

	CanSeeMissingInAction = true,
}

local threshold1 = 5
local threshold2 = 8
local threshold3 = 10
local function AssignRoles(_, participants: {Types.Participant}): ()
	if #participants <= threshold1 then
		for i, v in participants do
			v:SetRole(framedRole)
		end
	elseif #participants <= threshold2 then
		for i, v in participants do
			if i == 1 then
				v:SetRole(policeRole)
			else
				v:SetRole(framedRole)
			end
		end
	elseif #participants <= threshold3 then
		for i, v in participants do
			if i == 1 then
				v:SetRole(undercoverRole)
			elseif i == 2 then
				v:SetRole(policeRole)
			else
				v:SetRole(framedRole)
			end
		end
	else
		for i, v in participants do
			if i == 1 then
				v:SetRole(undercoverRole)
			elseif i == 2 or i == 3 then
				v:SetRole(policeRole)
			else
				v:SetRole(framedRole)
			end
		end
	end
end

local function OnStart(_, round: Types.Round): ()
	for _, participant in round:GetParticipantsWithRole(round:GetRoleFromRoleName("Framed")) do
		local char = participant:GetCharacter()
		if char then
			FaceIt(char)
		end

		local hum = participant:GetHumanoid()
		if hum then
			for _, accessory in hum:GetAccessories() do
				if accessory.AccessoryType == Enum.AccessoryType.Face then
					accessory:Destroy()
				end
			end
		end

		Health.InitHeal(participant)
	end
end

local gamemode: Types.GamemodeDefinition = {
	Name = "Framed",
	Description = "Find and kill your targets. Don't get caught red-handed.",
	Authors = "@pa00",

	MinimumPlayers = 1,

	TimeoutVictor = function(_, round)
		return round:GetRoleFromRoleName("Police")
	end,

	EnableFriendlyFire = false,
	EnableKarma = true,

	StartingItems = {},

	Roles = {
		Framed = framedRole,
		Police = policeRole,
		Undercover = undercoverRole,
	},

	AvailableAmmo = Ammo,
	AvailableItems = Items,
	InteractableDefinitions = Interactables,

	DeathSounds = {
		"rbxassetid://9125652432",
		"rbxassetid://9125651099",
		"rbxassetid://9125651607",
		"rbxassetid://9125652452",
		"rbxassetid://9125651373",
		"rbxassetid://9125652147",
		"rbxassetid://9125652675"
	},

	AssignRoles = AssignRoles,

	GetRoundEndMusic = function()
		local music = script:FindFirstChild("VictoryMusic")
		assert(not music or music:IsA("Sound"), "VictoryMusic must be a Sound instance")

		if not music then
			local newMusic = Instance.new("Sound")
			newMusic.Name = "VictoryMusic"
			newMusic.SoundId = "rbxassetid://1847685521"
			newMusic.Parent = script
			music = newMusic
		end

		assert(music, "VictoryMusic must be a Sound instance")

		return music
	end,

	OnDeath = function() end,

	Duration = function()
		return 240
	end,

	OnCharacterAdded = function() end,
	OnStart = OnStart,
}

return gamemode