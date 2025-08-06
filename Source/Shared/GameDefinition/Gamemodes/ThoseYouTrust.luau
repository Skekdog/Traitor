local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StandardHighlights = require(ReplicatedStorage.Shared.GameDefinition.Gamemodes.Common.StandardHighlights)
local C4 = require(ReplicatedStorage.Shared.GameDefinition.Interactables.C4)
local DeathStation = require(ReplicatedStorage.Shared.GameDefinition.Interactables.DeathStation)
local Decoy = require(ReplicatedStorage.Shared.GameDefinition.Interactables.Decoy)
local HealthStation = require(ReplicatedStorage.Shared.GameDefinition.Interactables.HealthStation)
local Radio = require(ReplicatedStorage.Shared.GameDefinition.Interactables.Radio)
local Ammo = require(ReplicatedStorage.Shared.GameDefinition.Items.Ammo)
local Items = require(ReplicatedStorage.Shared.GameDefinition.Items.Items)
local Visualiser = require(ReplicatedStorage.Shared.GameDefinition.Interactables.Visualiser)
local Disguiser = require(ReplicatedStorage.Shared.GameDefinition.Items.Disguiser)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

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

local timeoutMusic: {Sound} = {}
for _, v in ReplicatedStorage.Assets.VictoryMusic.Timeout:GetChildren() do
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
		Color = Color3.fromRGB(211, 20, 20),
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
			Items.Radar,
			Items["Ballistic Vest"],
			Items.Disguiser,
			Items["Decoy"],
			Items["C4"],
			Items["DeathStation"],
			Items["Knife"],
			Items.AWP,
			Items["Silenced Pistol"],
			Items.Grenade,
			Items["Flare Gun"],
			Items["Newton Launcher"],
			Items["Poltergeist"],
			Items["BAR"],
			Items["Radio"],
		},

		CanTeamChat = true,
		CanSeeMissingInAction = true,

		Allies = {"Traitor"},
		RevealedRoles = {"Detective", "Traitor"},
		HighlightedRoles = {"Traitor"},

		DamageKarmaMultiplier = 1.5,
	},

	Innocent = {
		Kind = "RoleDefinition",
		Name = "Innocent",
		Description = "Spy HQ has been infilitrated by Traitors. Work with the Detectives to survive.",
		Color = Color3.fromRGB(29, 237, 29),
		Sound = "rbxassetid://9042819926",

		Allegiance = {Kind = "Role", Role = "Innocent"},
		VictoryText = "The lovable Innocents have won the round!",

		Allies = {"Innocent", "Detective"},
		RevealedRoles = {"Detective"},

		ScoreForFindingBodies = 1,
	},

	Detective = {
		Kind = "RoleDefinition",
		Name = "Detective",
		Description = "Spy HQ has been infilitrated by Traitors. Work with the Innocents to survive.",
		Color = Color3.fromRGB(25, 134, 230),
		Sound = "rbxassetid://9042823666",

		Allegiance = {Kind = "Role", Role = "Innocent"},

		StartingCredits = 2,
		StartingItems = {
			Items["DNAScanner"],
			Items["Ballistic Vest"],
		},

		EquipmentShop = {
			Items["Radar"],
			Items["HealthStation"],
			Items["Teleporter"],
			Items["Golden Gun"],
			Items["UMP"],
			Items["Visualiser"],
			Items["Defuser"],
			Items["Binoculars"],
			Items["Flashbang"],
		},

		AwardCreditsToRolesOnDeath = {
			Traitor = 1,
		},

		CanStealCreditsFromCorpses = true,
		CorpseSearchResultsPublicised = true,

		DamageKarmaMultiplier = 1.5,

		Allies = {"Innocent", "Detective"},
		RevealedRoles = {"Detective"},

		ScoreForFindingBodies = 1,
	}
}

local EXTRA_BETWEEN = vector.create(6, 8)
local function assignRoles(gamemode: Types.Gamemode, participants: {Types.Participant}): ()
	local numDetectives = if #participants >= EXTRA_BETWEEN.x and #participants < EXTRA_BETWEEN.y then 1 else #participants // 8
	local numTraitors = if #participants >= EXTRA_BETWEEN.x and #participants < EXTRA_BETWEEN.y then 2 else math.max(#participants // 4, 1)
	for i, v in participants do
		if i <= numDetectives then
			v:SetRole(roles.Detective)
		elseif i <= numDetectives + numTraitors then
			v:SetRole(roles.Traitor)
		else
			v:SetRole(roles.Innocent)
		end
	end
end

local function awardScoreForKill(attacker: Types.Participant, victim: Types.Participant): ()
	local corpse = assert(victim.Corpse)
	local aR, vR = attacker:GetRole(), victim:GetRole()

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
		elseif role == round:GetRoleFromRoleName("Traitor") then
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
	if not round:IsInProgress() then
        return
    end
	
	local winner = getWinner(round)
	if winner then
		round:Finish(winner)
	end
end

local function killHighlights(attacker: Types.Participant, victim: Types.Participant): ()
	local attackerRole = attacker:GetRole().Definition
	local victimRole = victim:GetRole().Definition
	local corpse = victim.Corpse
	local round = victim.Round

	if not corpse then
		return
	end

	if attackerRole == roles.Traitor then
		if victimRole ~= roles.Traitor then
			if not round.Extras.FirstBloodAwarded then
				round:AddHighlight({
					Title = "First Blood",
					Description = attacker:GetFormattedName() .. " delivered the first innocent death at a traitor's hands.",
					Priority = 1,
					Group = "First Blood",
				})
				attacker.Extras.CorrectInnocentKills = 1
				round.Extras.FirstBloodAwarded = true
			else
				attacker.Extras.CorrectInnocentKills = (attacker.Extras.CorrectInnocentKills or 0) + 1
				local kills = attacker.Extras.CorrectInnocentKills

				if kills == 1 then
					round:AddHighlight({
						Title = "I Got One, Boss!",
						Description = attacker:GetFormattedName() .. " managed to kill a single innocent. Sweet!",
						Group = "Traitor Correct Kills",
						Priority = 1,
					})
				elseif kills == 2 then
					round:AddHighlight({
						Title = "A Bullet For Two",
						Description = attacker:GetFormattedName() .. " showed the first one was not a lucky shot by killing another.",
						Group = "Traitor Correct Kills",
						Priority = 2,
					})
				elseif kills == 3 then
					round:AddHighlight({
						Title = "Serial Traitor",
						Description = attacker:GetFormattedName() .. " ended three innocent lives of espionage today.",
						Group = "Traitor Correct Kills",
						Priority = 3,
					})
				elseif kills > 3 and kills < 7 then
					round:AddHighlight({
						Title = "Wolf Among More Sheep-Like Wolves",
						Description = attacker:GetFormattedName() .. ` eats innocent spies for dinner. A dinner of {kills} courses.`,
						Group = "Traitor Correct Kills",
						Priority = 4,
					})
				else
					round:AddHighlight({
						Title = "Counter-Espionage Operative",
						Description = attacker:GetFormattedName() .. " gets paid per kill. Can now buy another luxury yacht.",
						Group = "Traitor Correct Kills",
						Priority = 5,
					})
				end
			end
		elseif victimRole == roles.Traitor and not corpse.WasCorrectKill and not round.Extras.AnyKillsHappened then
			round:AddHighlight({
				Title = "First Bloody Stupid Kill",
				Description = attacker:GetFormattedName() .. " scored the first kill by shooting a fellow traitor. Good job.",
				Priority = 5,
				Group = "Teamkilling",
			})
		end
	else
		if not round.Extras.AnyKillsHappened then
			if not corpse.WasCorrectKill then
				round:AddHighlight({
					Title = "First Blooper",
					Description = attacker:GetFormattedName() .. " was the first to kill. Too bad it was an innocent comrade.",
					Priority = 1,
					Group = "Teamkilling",
				})
			else
				round:AddHighlight({
					Title = "First Blow",
					Description = attacker:GetFormattedName() .. " struck the first blow for the innocent spies by making the first death a traitor's.",
					Priority = 1,
					Group = "Correct kills",
				})
				attacker.Extras.CorrectTraitorKills = 1
			end
		elseif victimRole == roles.Traitor then
			attacker.Extras.CorrectTraitorKills = (attacker.Extras.CorrectTraitorKills or 0) + 1
			local kills = attacker.Extras.CorrectTraitorKills

			if kills == 1 then
				round:AddHighlight({
					Title = "Betray This",
					Description = attacker:GetFormattedName() .. " found a traitor. Shot a traitor. Easy.",
					Priority = 2,
					Group = "Innocent Correct Kills",
				})
			elseif kills == 2 then
				round:AddHighlight({
					Title = "Applied to the Justice Squad",
					Description = attacker:GetFormattedName() .. " escorted two traitors to the great beyond.",
					Priority = 3,
					Group = "Innocent Correct Kills",
				})
			elseif kills == 3 then
				round:AddHighlight({
					Title = "Do Traitors Dream of Traitorous Sheep?",
					Description = attacker:GetFormattedName() .. " put three traitors to rest.",
					Priority = 4,
					Group = "Innocent Correct Kills",
				})
			else
				round:AddHighlight({
					Title = "Internal Affairs Employee",
					Description = attacker:GetFormattedName() .. " gets paid per kill. Can now order their fifth swimming pool.",
					Priority = 5,
					Group = "Innocent Correct Kills",
				})
			end
		end
	end

	round.Extras.AnyKillsHappened = true
end

local function onDeath(gamemode: Types.Gamemode, victim: Types.Participant, deferVictoryCheck: boolean): ()
	StandardHighlights.OnDeath(gamemode, victim, deferVictoryCheck)

	victim.Extras.CorpseDisguiseData = {
		Participant = victim,
	}
	Disguiser.DisguiseServer(victim.Extras.CorpseDisguiseData, true)

	local corpse = victim.Corpse

	if corpse then
		local attacker = corpse.Killer

		if attacker then
			killHighlights(attacker, victim)
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

	RoleCanCallToCorpse = roles.Detective,

	GetRoundEndMusic = getVictoryMusic,

	EnableFriendlyFire = true,
	EnableKarma = true,

	AvailableAmmo = Ammo,
	AvailableItems = Items,

	InteractableDefinitions = {
		C4 = C4.Interactable,
		HealthStation = HealthStation.Interactable,
		DeathStation = DeathStation,
		Decoy = Decoy.Interactable,
		Visualiser = Visualiser,
		Radio = Radio,
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

	OnIdentifyCorpse = function(gamemode, corpse, searcher)
		StandardHighlights.OnIdentifyCorpse(gamemode, corpse, searcher)
		Disguiser.DisguiseServer(corpse.Participant.Extras.CorpseDisguiseData, false)
	end
}

return gamemode