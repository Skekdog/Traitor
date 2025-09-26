local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Epilogue = require(script.Epilogue)
local PlaySound = require(ReplicatedStorage.API.PlaySound)
local FaceIt = require(script.FaceIt)
local FramedItems = require(script.FramedItems)
local FramedNotification = require(script.FramedNotification)
local GetRelation = require(script.GetRelation)
local HasteMode = require(script.HasteMode)
local Health = require(script.Health)
local Mistakes = require(script.Mistakes)
local RedHanded = require(script.RedHanded)
local Targets = require(script.Targets)
local Types = require(ReplicatedStorage.API.Types)
local Interactables = require(ReplicatedStorage.Shared.GameDefinition.Interactables.Interactables)
local Ammo = require(ReplicatedStorage.Shared.GameDefinition.Items.Ammo)
local Items = require(ReplicatedStorage.Shared.GameDefinition.Items.Items)

require(script.HighlightCharacter)

local backgroundMusic = {
	1843504945,
	1843505232,
	1847799241,
	1847245265,
	1847798833,
	1838974004,
	1837472332,
	1838973846,
	1848209564,
	1838730828,
	1846614488,
}

local framedRole: Types.RoleDefinition = {
	Kind = "RoleDefinition",

	Name = "Framed",
	Description = "Find and kill your targets. Don't get caught red-handed.",
	Color = Color3.fromRGB(200, 44, 28),
	Sound = "rbxassetid://1848271648",

	Allegiance = {Kind = "Solo"},

	EquipmentShop = {Items.Flashbang},
	StartingItems = {FramedItems.TargetChecker},

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

	EquipmentShop = {Items.Flashbang},
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

	EquipmentShop = {Items.Flashbang},
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
			FaceIt.FaceIt(char)
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

	round.Extras.FramedBackgroundMusic = PlaySound(backgroundMusic)
end

local function OnFinish(_, round: Types.Round): ()
	Epilogue.Finish()
	if round.Extras.FramedBackgroundMusic then
		round.Extras.FramedBackgroundMusic:Destroy()
	end
end

local function OnDeath(_, participant: Types.Participant, defer: boolean): ()
	if participant:GetRole().Definition.Name ~= "Framed" then
		return
	end

	local corpse = participant.Corpse
	if not corpse then
		return
	end

	local attacker = corpse.Killer
	if attacker then
		local relation: GetRelation.Relation = GetRelation(attacker, participant)
		if relation ~= "RDM" then
			attacker:AddCredits(1)
			FramedNotification(attacker, `+1 Credit, {relation} Killed!`)
		else
			FramedNotification(attacker, "Mistake! Police are hunting you!")
			Mistakes.MistakeMade(attacker)
		end
	end

	local round = participant.Round

	local framedAlive: {Types.Participant} = {}
	for _, v in round:GetParticipantsWithRole(round:GetRoleFromRoleName("Framed")) do
		if v:IsAlive() and v ~= participant then
			table.insert(framedAlive, v)
		end
	end

	if #framedAlive == 0 then
		round:Finish(round:GetRoleFromRoleName("Police"))
		return
	elseif #framedAlive == 1 then
		Epilogue.Begin(framedAlive[1])
	elseif #framedAlive <= 3 then
		HasteMode.Start(round)
	end

	Targets.OnDeath(participant)
end

local function OnItemEquipped(_, participant: Types.Participant, item: Types.AnyItem, equipped: boolean): ()
	if item.Kind == "Item" or participant:GetRole().Definition ~= framedRole then
		return
	end

	if equipped then
		RedHanded.Start(participant)
	else
		RedHanded.Stop(participant)
	end
end

local BeforeHitParticipant: Types.BeforeHitParticipant
function BeforeHitParticipant(item, round, participant, params)
	local attacker = params.Attacker
	if not attacker then
		return true
	end

	if participant:GetRole().Definition == policeRole then
		return HasteMode.IsHasteMode(round)
	elseif participant:GetRole().Definition == framedRole then
		return RedHanded.IsRedHanded(participant) or Mistakes.HasMadeMistake(participant) or Epilogue.IsEpilogue(round)
	end

	local willDie = params.Amount >= participant:GetHealth()
	if willDie and GetRelation(attacker, participant) == "RDM" and Mistakes.HasMadeMistake(attacker) then
		if Mistakes.TrySlayForMistakes(participant) then
			return false
		end
	end

	return true
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

local framedItems = {}
for i, v in Items do
	framedItems[i] = v
end

for i, v in FramedItems do
	framedItems[i] = v
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

	StartingItems = {Items["Magneto Stick"]},

	Roles = {
		Framed = framedRole,
		Police = policeRole,
		Undercover = undercoverRole,
	},

	AvailableAmmo = Ammo,
	AvailableItems = framedItems,
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

	OnDeath = OnDeath,

	Duration = function()
		return 240
	end,

	OnCharacterAdded = function() end,
	OnStart = OnStart,
	OnFinish = OnFinish,

	OnItemEquipped = OnItemEquipped,

	BeforeHitParticipant = BeforeHitParticipant,
}

return gamemode