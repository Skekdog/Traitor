local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Highlights = require(script.Highlights)
local DamageSource = require(ReplicatedStorage.API.DamageSource)
local Message = require(ReplicatedStorage.API.Interface.Message)
local StandardGame = require(ReplicatedStorage.API.StandardGame)
local Infected = require(script.Roles.Infected)
local Survivor = require(script.Roles.Survivor)
local Types = require(ReplicatedStorage.API.Types)

local RESPAWN_TIME = 5
local ZOMBIE = ReplicatedStorage.Assets.Gamemode.Infection.Zombie

local infectionItems = {}
for i, v in StandardGame.GetItems() do
	infectionItems[i] = v
end

-- for i, v in nil do
-- 	infectionItems[i] = v
-- end

local Items = infectionItems

local infectedMusic: {Sound} = {}
for _, v in ReplicatedStorage.Assets.VictoryMusic.Traitor:GetChildren() do
	if v:IsA("Sound") then
		table.insert(infectedMusic, v)
	end
end

local survivorMusic: {Sound} = {}
for _, v in ReplicatedStorage.Assets.VictoryMusic.Innocent:GetChildren() do
	if v:IsA("Sound") then
		table.insert(survivorMusic, v)
	end
end

for _, v in ReplicatedStorage.Assets.VictoryMusic.Timeout:GetChildren() do
	if v:IsA("Sound") then
		table.insert(survivorMusic, v)
	end
end

local function Duration(_, numParticipants: number): number
	return 120 + (numParticipants * 5)
end

local function TimeoutVictor(round: Types.Round): Types.Role
	return round:GetRoleFromRoleName("Survivor")
end

local function GetRoundEndMusic(round: Types.Round, victor: Types.Victor): Sound
	assert(victor.Kind == "Role")

	if victor.Definition == Infected then
		return infectedMusic[math.random(#infectedMusic)]
	end

	return survivorMusic[math.random(#survivorMusic)]
end

local function onSurvivorDeath(round: Types.Round, participant: Types.Participant): ()
	local infectedRole = round:GetRoleFromRoleName("Infected")
	local survivorRole = round:GetRoleFromRoleName("Survivor")

	participant:SetRole(Infected)

	if #round:GetParticipantsWithRole(survivorRole) == 0 then
		round:Finish(infectedRole)
	end
end

local function OnDeath(round: Types.Round, participant: Types.Participant): ()
	StandardGame.Highlights.OnDeath(round, participant)

	local corpse = participant.Corpse
	if corpse and corpse.Killer then
		Highlights.Kills(corpse.Killer, participant)
	end

	if participant:GetRole().Definition == Survivor then
		onSurvivorDeath(round, participant)
	end

	task.delay(RESPAWN_TIME, participant.SpawnCharacter, participant, ZOMBIE:Clone())
end

local function AssignRoles(round: Types.Round, participants: {Types.Participant}): ()
	if #participants == 1 then
		participants[1]:SetRole(Survivor)
		return
	end

	for i, participant in participants do
		if i == 1 then
			participant:SetRole(Infected)
			continue
		end
		participant:SetRole(Survivor)
	end
end

local function allowGunUsage(params: Types.DamageParams): boolean
	local participant = params.Attacker
	if not participant then
		return true
	end

	if participant:GetRole().Definition == Infected and DamageSource.IsFirearm(params.Source) then
		Message.Screen("⚠️ Infected can't use firearms!", "Warn", nil, participant.Player)
		return false
	end

	return true
end

local function BeforeDamageParticipantOrProp(_, _, params: Types.DamageParams): boolean
	return allowGunUsage(params)
end

local gamemode: Types.GamemodeDefinition = {
	Name = "Infection",
	Description = "Plague upon ye!",
	Authors = "@Skekdogs",
	MinimumPlayers = 1,

	Roles = {
		Infected = Infected,
		Survivor = Survivor,
	},

	AvailableAmmo = StandardGame.GetAllAmmo(),
	InteractableDefinitions = StandardGame.GetInteractables(),
	AvailableItems = Items,

	StartingItems = {
		Items.Crowbar,
		Items["Magneto Stick"],
	},

	Duration = Duration,
	TimeoutVictor = TimeoutVictor,
	GetRoundEndMusic = GetRoundEndMusic,

	AssignRoles = AssignRoles,
	OnDeath = OnDeath,

	BeforeDamageParticipant = BeforeDamageParticipantOrProp,
	BeforeDamageProp = BeforeDamageParticipantOrProp,
}

return gamemode