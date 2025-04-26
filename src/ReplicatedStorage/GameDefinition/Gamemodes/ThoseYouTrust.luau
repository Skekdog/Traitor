local ReplicatedStorage = game:GetService("ReplicatedStorage")
local C4 = require(ReplicatedStorage.GameDefinition.Interactables.C4)
local Ammo = require(ReplicatedStorage.GameDefinition.Items.Ammo)
local Items = require(ReplicatedStorage.GameDefinition.Items.Items)
local Types = require(ReplicatedStorage.RoundRule.Types)

local traitorMusic: {Sound} = {}
for _, v in ReplicatedStorage.VictoryMusic.Traitor:GetChildren() do
	if v:IsA("Sound") then
		table.insert(traitorMusic, v)
	end
end

local innocentMusic: {Sound} = {}
for _, v in ReplicatedStorage.VictoryMusic.Innocent:GetChildren() do
	if v:IsA("Sound") then
		table.insert(innocentMusic, v)
	end
end

local timeoutMusic: {Sound} = {}
for _, v in ReplicatedStorage.VictoryMusic.Timeout:GetChildren() do
	if v:IsA("Sound") then
		table.insert(timeoutMusic, v)
	end
end

local function getVictoryMusic(_, round: Types.Round, victor: Types.Victor, isTimeout: boolean): Sound
	if isTimeout then
		return timeoutMusic[math.random(#timeoutMusic)]
	end
	
	assert(victor.Kind == "Role")

	if victor.Definition.Name == "Traitor" then
		return traitorMusic[math.random(#traitorMusic)]
	end
	return innocentMusic[math.random(#innocentMusic)]
end

local roles: {[string]: Types.RoleDefinition} = {
	Traitor = {
		Kind = "RoleDefinition",
		Name = "Traitor",
		Description = "Work with the other Traitors to kill the Innocents. Keep your role secret.",
		Color = Color3.fromRGB(255, 0, 0),
		Sound = "rbxassetid://9042088276",

		IsBadGuys = true,

		IsExclamatory = true,
		Allegiance = {Kind = "Role", Role = "Traitor"},

		VictoryText = "The dastardly Traitors have won the round!",

		ShouldAnnounceDisconnect = true,
		CanStealCreditsFromCorpses = true,
		
		AwardCreditsToRolesOnDeath = {
			Detective = 1,
		},

		StartingCredits = 2,

		StartingItems = {},
		EquipmentShop = {
			Items.AWP,
			Items["Silenced Pistol"],
			Items.Radar,
			Items.Grenade,
			Items["Ballistic Vest"],
			Items["Flare Gun"],
			Items["Newton Launcher"],
			Items["Poltergeist"],
			Items["C4"],
		},

		CanTeamChat = true,
		CanSeeMissingInAction = true,

		Allies = {"Traitor"},
		RevealedRoles = {"Detective", "Traitor"},
		HighlightedRoles = {"Traitor"},

		Health = 100,
		WalkSpeed = 16,
		JumpPower = 18,

		Accessories = {},
		DamageKarmaMultiplier = 1.5,
	},

	Innocent = {
		Kind = "RoleDefinition",
		Name = "Innocent",
		Description = "Spy HQ has been infilitrated by Traitors. Work with the Detectives to survive.",
		Color = Color3.fromRGB(0, 255, 0),
		Sound = "rbxassetid://9042819926",

		Allegiance = {Kind = "Role", Role = "Innocent"},
		VictoryText = "The lovable Innocents have won the round!",

		Accessories = {},
		AwardCreditsToRolesOnDeath = {},
		DamageKarmaMultiplier = 1,

		Allies = {"Innocent", "Detective"},
		RevealedRoles = {"Detective"},

		ScoreForFindingBodies = 1,

		Health = 100,
		WalkSpeed = 16,
		JumpPower = 18,
	},

	Detective = {
		Kind = "RoleDefinition",
		Name = "Detective",
		Description = "Spy HQ has been infilitrated by Traitors. Work with the Innocents to survive.",
		Color = Color3.fromRGB(0, 0, 255),
		Sound = "rbxassetid://9042823666",

		Allegiance = {Kind = "Role", Role = "Innocent"},

		StartingItems = {
			Items["DNA Scanner"],
			Items["Ballistic Vest"],
		},

		EquipmentShop = {
			Items["Golden Gun"],
			Items["Radar"],
			Items["Flashbang"],
			Items["UMP"],
		},

		AwardCreditsToRolesOnDeath = {
			Traitor = 1,
		},

		CanStealCreditsFromCorpses = true,
		CorpseSearchResultsPublicised = true,

		Accessories = {},
		DamageKarmaMultiplier = 1,

		Allies = {"Innocent", "Detective"},
		RevealedRoles = {"Detective"},

		ScoreForFindingBodies = 1,

		Health = 100,
		WalkSpeed = 16,
		JumpPower = 18,
	}
}

local function assignRoles(gamemode: Types.Gamemode, participants: {Types.Participant}): ()
	local numDetectives = #participants // 8
	local numTraitors = numDetectives + math.max(#participants // 4, 1)
	for i, v in participants do
		if i <= numDetectives then
			v:SetRole(roles.Detective)
		elseif i <= numTraitors then
			v:SetRole(roles.Traitor)
		else
			v:SetRole(roles.Innocent)
		end
	end
end

local function awardScoreForKill(attacker: Types.Participant, victim: Types.Participant): ()
	local corpse = assert(victim:GetCorpse())
	local aR, vR = attacker:GetRole(), victim:GetRole()
	if not aR or not vR then
		return
	end

	local attackerRole, victimRole = aR.Definition.Name, vR.Definition.Name

	if attacker == victim then
		attacker:AddScore("Suicide", -2)
	elseif attackerRole == "Traitor" then
		if victimRole == "Traitor" and not corpse.WasCorrectKill then
			attacker:AddScore("Killed Traitor", -10)
		elseif victimRole == "Innocent" then
			attacker:AddScore("Killed Innocent", 1)
		elseif victimRole == "Detective" then
			attacker:AddScore("Killed Detective", 3)
		end
	elseif attackerRole == "Innocent" or attackerRole == "Detective" then
		if victimRole == "Traitor" then
			attacker:AddScore("Killed Traitor", 4)
		elseif victimRole == "Innocent" and not corpse.WasCorrectKill then
			attacker:AddScore("Killed Innocent", -2)
		elseif victimRole == "Detective" and not corpse.WasCorrectKill then
			attacker:AddScore("Killed Detective", -5)
		end
	end
end

local function getWinner(round: Types.Round): Types.Role?
	local traitors, innocents = 0, 0
	for _, v in round:GetParticipants() do
		assert(v)

		if not v:IsAlive() then
			continue
		end

		local role = v:GetRole()
		if role == round:GetRoleFromRoleName("Innocent") or role == round:GetRoleFromRoleName("Detective") then
			innocents += 1
		elseif v:GetRole() == round:GetRoleFromRoleName("Traitor") then
			traitors += 1
		end
	end
	
	if innocents == 0 then
		return round:GetRoleFromRoleName("Traitor")
	elseif traitors == 0 then
		return round:GetRoleFromRoleName("Innocent")
	end

	return nil
end

local function tryEndRound(round: Types.Round): ()
	local winner = getWinner(round)
	if winner then
		round:EndRound(winner)
	end
end

local function onDeath(gamemode: Types.Gamemode, victim: Types.Participant, deferVictoryCheck: boolean): ()
	local corpse = victim:GetCorpse()

	if corpse then
		local attacker = corpse.Killer

		if attacker then
			awardScoreForKill(attacker, victim)
		end
	end
	
	if deferVictoryCheck then
		task.defer(tryEndRound, victim.Round)
	else
		tryEndRound(victim.Round)
	end
end

local gamemode: Types.Gamemode = {
	Name = "ThoseYouTrust",
	DisplayName = "Those You Trust",
	Description = "Spy HQ has been infilitrated by Traitors. Can you separate those you trust, from those you shouldn't?",
	Authors = "@Scelly_Dog",

	MinimumPlayers = 1,

	RequiredSlayVotes = 2,

	TimeoutVictor = function(gamemode: Types.Gamemode, round: Types.Round): Types.Victor
		return round:GetRoleFromRoleName("Innocent")
	end,

	GetRoundEndMusic = getVictoryMusic,

	EnableFriendlyFire = true,
	EnableKarma = true,

	AvailableAmmo = Ammo,
	AvailableItems = Items,

	InteractableDefinitions = {
		C4 = C4,
	},

	StartingItems = {
		Items.Crowbar,
		Items["Magneto Stick"],
	},

	Duration = function(numParticipants: number)
		return 120 + 10 * numParticipants
	end,

	Roles = roles,

	AssignRoles = assignRoles,

	DeathSounds = {
		"rbxassetid://9125652432",
		"rbxassetid://9125651099",
		"rbxassetid://9125651607",
		"rbxassetid://9125652452",
		"rbxassetid://9125651373",
		"rbxassetid://9125652147",
		"rbxassetid://9125652675"
	},

	OnCharacterAdded = function() end,
	OnDeath = onDeath,
}

return gamemode