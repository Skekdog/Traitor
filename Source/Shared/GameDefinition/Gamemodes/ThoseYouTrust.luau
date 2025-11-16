local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Impulse = require(ReplicatedStorage.API.Impulse)
local StandardGame = require(ReplicatedStorage.API.StandardGame)
local Types = require(ReplicatedStorage.API.Types)
local Disguiser = require(ReplicatedStorage.Shared.GameDefinition.Items.Disguiser)
local Ragdoll = require(ReplicatedStorage.Shared.RoundRule.Ragdoll)
local CombineTable = require(ReplicatedStorage.Shared.Util.CombineTable)

local Items = StandardGame.GetItems()

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

local function getVictoryMusic(round: Types.Round, victor: Types.Victor, isTimeout: boolean): Sound
	if isTimeout then
		return timeoutMusic[math.random(#timeoutMusic)]
	end

	assert(victor.Kind == "Role")

	if victor.Definition.Name == "Traitor" then
		return traitorMusic[math.random(#traitorMusic)]
	end
	return innocentMusic[math.random(#innocentMusic)]
end

local TRAITOR_COLOUR = Color3.fromRGB(211, 20, 20)
local INNOCENT_COLOUR = Color3.fromRGB(29, 237, 29)
local DETECTIVE_COLOUR = Color3.fromRGB(25, 134, 230)

local roles: {[string]: Types.RoleDefinition} = {
	Traitor = {
		Kind = "RoleDefinition",
		Name = "Traitor",
		Description = `Work with the other <font color="#{TRAITOR_COLOUR:ToHex()}">Traitors</font> to kill the <font color="#{INNOCENT_COLOUR:ToHex()}">Innocents</font>. Keep your role secret.`,
		Color = TRAITOR_COLOUR,
		Sound = "rbxassetid://9042088276",

		IsEvil = true,

		IsExclamatory = true,
		Allegiance = {Kind = "Role", Role = "Traitor"},

		ShouldAnnounceDisconnect = true,
		CanStealCreditsFromCorpses = true,

		AwardCreditsToRolesOnDeath = {
			Detective = 1,
		},
		CorpseHidesSelfDefense = true,

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
		Description = `Spy HQ has been infilitrated by <font color="#{TRAITOR_COLOUR:ToHex()}">Traitors</font>. Work with the <font color="#{DETECTIVE_COLOUR:ToHex()}">Detectives</font> to survive.`,
		Color = INNOCENT_COLOUR,
		Sound = "rbxassetid://9042819926",

		Allegiance = {Kind = "Role", Role = "Innocent"},

		Allies = {"Innocent", "Detective"},
		RevealedRoles = {"Detective"},

		ScoreForFindingBodies = 1,
	},

	Detective = {
		Kind = "RoleDefinition",
		Name = "Detective",
		Description = `Spy HQ has been infilitrated by <font color='#{TRAITOR_COLOUR:ToHex()}'>Traitors</font>. Use your <font color="#{DETECTIVE_COLOUR:ToHex()}">Equipment</font> to defeat the <font color="#{TRAITOR_COLOUR:ToHex()}">Traitors</font>.`,
		Color = DETECTIVE_COLOUR,
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
local function assignRoles(_, participants: {Types.Participant}): ()
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

local function getVictoryEventText(round: Types.Round, victor: Types.Victor, isTimeout: boolean): string?
	if victor.Kind == "Participant" then
		return nil
	end

	local traitorRole = round:GetRoleFromRoleName("Traitor")
	local innocentRole = round:GetRoleFromRoleName("Innocent")

	if isTimeout then
		return "The " .. traitorRole:FormatString("Traitors") .. " have ran out of time and so the lovable " .. innocentRole:FormatString("Innocents") .. " have won the round!"
	end

	if victor.Definition == roles.Traitor then
		return "The dastardly " .. traitorRole:FormatString("Traitors") .. " have won the round!"
	elseif victor.Definition == roles.Innocent then
		return "The lovable " .. innocentRole:FormatString("Innocents") .. " have won the round!"
	end

	return nil
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

	if attacker == victim then
		return
	end

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

local function disguiseCorpse(participant: Types.Participant, corpse: Types.Corpse, enable: boolean): ()
	local model = corpse.Model
	if not model or not model.PrimaryPart then
		return
	end

	local impulse = participant.Extras.CombatImpulse

	local hum = model:FindFirstChildOfClass("Humanoid")

	local partData: {[BasePart]: {Rope: {Constraint: RopeConstraint, Attachment0: Attachment}?, CFrame: CFrame}} = {}
	for _, part in model:GetChildren() do
		if not part:IsA("BasePart") then
			continue
		end

		partData[part] = {CFrame = part.CFrame}

		local rope = part:FindFirstChild("MagnetoRope")
		if rope and rope:IsA("RopeConstraint") and rope.Attachment0 then
			partData[part].Rope = {
				Constraint = rope:Clone(),
				Attachment0 = rope.Attachment0:Clone(),
			}
		end
	end

	Disguiser.DisguiseServer(participant, enable, model, hum, true)

	model = Ragdoll(model, true)
	corpse.Model = model

	for part, data in partData do
		local newPart = model:FindFirstChild(part.Name)
		if not newPart or not newPart:IsA("BasePart") then
			continue
		end

		newPart.CFrame = data.CFrame

		if data.Rope then
			data.Rope.Constraint.Attachment0 = data.Rope.Attachment0
			data.Rope.Constraint.Parent = newPart
			data.Rope.Attachment0.Parent = newPart
		end
	end

	if enable and impulse then
        Impulse.ApplyImpulse(model.PrimaryPart, impulse, true)
    end
end

local function onDeath(round: Types.Round, victim: Types.Participant, deferVictoryCheck: boolean): ()
	StandardGame.Highlights.OnDeath(round, victim)

	local corpse = victim.Corpse

	if corpse then
		if corpse.Model then
			task.spawn(disguiseCorpse, victim, corpse, true)
		end
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

local gamemode: Types.GamemodeDefinition = {
	Name = "ThoseYouTrust",
	DisplayName = "Traitor!",
	Description = "Spy HQ has been infilitrated by Traitors. Can you separate those you trust, from those you shouldn't?",
	Authors = "@Skekdogs",

	MinimumPlayers = 1,

	RequiredSlayVotes = 2,

	TimeoutVictor = function(round: Types.Round): Types.Victor
		return round:GetRoleFromRoleName("Innocent")
	end,

	RoleCanCallToCorpse = roles.Detective,

	GetRoundEndMusic = getVictoryMusic,
	GetVictoryEventText = getVictoryEventText,

	EnableFriendlyFire = true,
	EnableKarma = true,

	AvailableAmmo = StandardGame.GetAllAmmo(),
	AvailableItems = Items,

	InteractableDefinitions = StandardGame.GetInteractables(),

	StartingItems = {
		Items.Crowbar,
		Items["Magneto Stick"],
	},

	Duration = function(_, numParticipants: number)
		return 120 + 10 * numParticipants
	end,

	Roles = roles,

	AssignRoles = assignRoles,

	OnDeath = onDeath,

	OnIdentifyCorpse = function(round, corpse, searcher)
		if not round:IsPostGame() then
			StandardGame.Highlights.OnIdentifyCorpse(round, corpse, searcher)
		end

		if corpse.Model and corpse.Model:GetAttribute("IsDisguised") then
			disguiseCorpse(corpse.Participant, corpse, false)
		end
	end,

	AddFinishHighlights = function(round)
		StandardGame.Highlights.FinishHighlights(round)
		local awardDeadliestAmongEquals: Types.Participant?
		for _, v in round:GetParticipantsWithRole(round:GetRoleFromRoleName("Traitor")) do
			local corpse = v.Corpse
			if not corpse then
				continue
			end

			local attacker = corpse.Killer
			if not attacker or attacker:GetRole().Definition == roles.Traitor then
				continue
			end

			if awardDeadliestAmongEquals then
				awardDeadliestAmongEquals = nil
				break
			end
			awardDeadliestAmongEquals = attacker
		end

		local awardLoneWolf: Types.Participant?
		local innocentList = CombineTable(round:GetParticipantsWithRole(round:GetRoleFromRoleName("Innocent")), round:GetParticipantsWithRole(round:GetRoleFromRoleName("Detective")))
		for _, v in innocentList do
			local corpse = v.Corpse
			if not corpse then
				continue
			end

			local attacker = corpse.Killer
			if not attacker or attacker:GetRole().Definition ~= roles.Traitor then
				continue
			end

			if awardLoneWolf then
				awardLoneWolf = nil
				break
			end

			awardLoneWolf = attacker
		end

		if awardDeadliestAmongEquals then
			round:AddHighlight({
				Title = "Deadliest Among Equals",
				Description = awardDeadliestAmongEquals:GetFormattedName() .. " was responsible for every traitor death made by the innocents this round.",
				Priority = 2,
				Group = "Innocent Correct Kills",
			})
		end

		if awardLoneWolf then
			round:AddHighlight({
				Title = "Lone Wolf",
				Description = awardLoneWolf:GetFormattedName() .. " was responsible for every innocent death made by a traitor this round.",
				Priority = 2,
				Group = "Traitor Correct Kills",
			})
		end
	end,
}

return gamemode