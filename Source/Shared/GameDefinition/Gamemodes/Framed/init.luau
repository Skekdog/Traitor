local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FaceIt = require(script.FaceIt)
local Health = require(script.Health)
local Targets = require(script.Targets)
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
	local framed = round:GetParticipantsWithRole(round:GetRoleFromRoleName("Framed"))

	for _, participant in framed do
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

	Targets.LoadFirstTargets(framed)
end

local traitorMusic: {Sound} = {}
for _, v in ReplicatedStorage.Assets.VictoryMusic.Traitor:GetChildren() do
	if v:IsA("Sound") then
		table.insert(traitorMusic, v)
	end
end

local innocentMusic: {Sound} = {}
for _, v in ReplicatedStorage.Assets.VictoryMusic.Innocent:GetChildren() do
	if v:IsA("Sound") then
		table.insert(innocentMusic, v)
	end
end

local function getVictoryMusic(_, round: Types.Round, victor: Types.Victor, isTimeout: boolean): Sound
	if victor.Kind == "Participant" then
		return traitorMusic[math.random(#traitorMusic)]
	end
	return innocentMusic[math.random(#innocentMusic)]
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

	GetRoundEndMusic = getVictoryMusic,

	OnDeath = function() end,

	Duration = function()
		return 240
	end,

	OnCharacterAdded = function() end,
	OnStart = OnStart,
}

return gamemode