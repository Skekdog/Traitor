local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Epilogue = require(script.GamePhase.Epilogue)
local PlaySound = require(ReplicatedStorage.API.PlaySound)
local ScreenMessage = require(ReplicatedStorage.API.ScreenMessage)
local StandardGame = require(ReplicatedStorage.API.StandardGame)
local Face = require(script.GameState.Face)
local FramedItems = require(script.FramedItems)
local FramedNotification = require(script.Interface.FramedNotification)
local GetRelation = require(script.Roles.GetRelation)
local HasteMode = require(script.GamePhase.HasteMode)
local Health = require(script.GameState.Health)
local Mistakes = require(script.GameState.Mistakes)
local RedHanded = require(script.GameState.RedHanded)
local Targets = require(script.GameState.Targets)
local Highlights = require(script.Highlights)
local Types = require(ReplicatedStorage.API.Types)

require(script.GameState.HighlightCharacter)

if RunService:IsClient() then
	require(script.GameState.Mirror)
end

local RED_HANDED_ITEMS = {"Magneto Stick"}

local function isItemIllegal(item: Types.AnyItem): boolean
	return item.Kind ~= "Item" or table.find(RED_HANDED_ITEMS, item.Definition.Name) ~= nil
end

local framedItems = {}
for i, v in StandardGame.GetItems() do
	framedItems[i] = v
end

for i, v in FramedItems do
	framedItems[i] = v
end

local Items = framedItems

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

	EquipmentShop = {Items.Flashbang, Items.Knife, Items.AWP, Items["Newton Launcher"], Items.BAR, Items["Silenced Pistol"], Items.Radar, Items.Intel},
	StartingItems = {Items.TargetChecker, Items.Mirror},

	RevealedRoles = {"Police"},
	HighlightedRoles = {"Police"},

	CanSeeMissingInAction = true,
}

local policeRole: Types.RoleDefinition = {
	Kind = "RoleDefinition",

	Name = "Police",
	PluralName = "Police",
	Description = "Kill anyone red-handed. Work with the Undercover.",
	Color = Color3.fromRGB(16, 108, 172),
	Sound = "rbxassetid://1848271643",

	Allegiance = {Kind = "Role", Role = "Police"},

	EquipmentShop = {Items.Flashbang, Items.AWP, Items["Newton Launcher"], Items.UMP, Items["Ballistic Vest"]},
	StartingItems = {Items.PoliceBadge},

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

	EquipmentShop = {Items.Flashbang, Items.AWP, Items["Newton Launcher"], Items.UMP, Items["Ballistic Vest"]},
	StartingItems = {Items.FakeTargetChecker, Items.PoliceBadge},

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

local function OnStart(round: Types.Round): ()
	local framed = round:GetParticipantsWithRole(round:GetRoleFromRoleName("Framed"))

	for _, participant in framed do
		local char = participant:GetCharacter()
		if char then
			local head = char:FindFirstChild("Head")
			if head and head:IsA("BasePart") then
				Face.SetFace(round, head)
			end
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

		local item = participant:GetEquippedItem()
		if item and (item.Kind ~= "Item" or table.find(RED_HANDED_ITEMS, item.Definition.Name)) then
			RedHanded.Start(participant)
		end
	end

	Targets.LoadFirstTargets(framed)

	local music
	local function playMusic()
		music = PlaySound(backgroundMusic)
		assert(music)

		round.Extras.FramedBackgroundMusic = music

		music.Ended:Once(playMusic)
	end

	playMusic()
end

local function OnFinish(round: Types.Round): ()
	Epilogue.Finish()
	if round.Extras.FramedBackgroundMusic then
		round.Extras.FramedBackgroundMusic:Destroy()
	end

	for _, participant in round:GetParticipants() do
		local item = participant:GetEquippedItem()
		if item and isItemIllegal(item) then
			RedHanded.StopImmediately(participant)
		end
	end
end

local function OnDeath(round: Types.Round, participant: Types.Participant, defer: boolean): ()
	local corpse = participant.Corpse
	if not corpse then
		return
	end

	Highlights.OnDeath(round, participant)

	local attacker = corpse.Killer
	if attacker then
		local relation: GetRelation.Relation = GetRelation(attacker, participant)
		if relation ~= "RDM" then
			attacker:AddCredits(1)
			FramedNotification(attacker, `+1 Credit, Killed {relation}!`)
			Health.TriggerHeal(attacker)
		else
			FramedNotification(attacker, "⚠️ Mistake! Police are hunting you!")
			Mistakes.MistakeMade(attacker)
		end
	end

	if participant:GetRole().Definition ~= framedRole then
		return
	end

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
	if not isItemIllegal(item) or not participant.Round:IsInProgress() or participant:GetRole().Definition ~= framedRole then
		return
	end

	if equipped then
		RedHanded.Start(participant)
	else
		RedHanded.Stop(participant)
	end
end

local function BeforeHitParticipant(_, participant: Types.Participant, params: Types.DamageParams): boolean
	local round = participant.Round
	local attacker = params.Attacker
	if not attacker then
		return true
	end

	if participant:GetRole().Definition == policeRole then
		if HasteMode.IsHasteMode(round) then
			return true
		end

		ScreenMessage("⚠️ Police cannot be hurt yet!", "Warn", nil, attacker.Player)
		return false
	elseif participant:GetRole().Definition == framedRole then
		if attacker:GetRole().Definition == policeRole or attacker:GetRole().Definition == undercoverRole then
			if RedHanded.IsRedHanded(participant) or Mistakes.HasMadeMistake(participant) or Epilogue.IsEpilogue(round) then
				return true
			end

			ScreenMessage("⚠️ Don't hurt innocents!", "Warn", nil, attacker.Player)
			return false
		end
		return true
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

local function getVictoryMusic(round: Types.Round, victor: Types.Victor, isTimeout: boolean): Sound
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

	TimeoutVictor = function(round)
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

	AvailableAmmo = StandardGame.GetAllAmmo(),
	AvailableItems = framedItems,
	InteractableDefinitions = StandardGame.GetInteractables(),

	AssignRoles = AssignRoles,

	GetRoundEndMusic = getVictoryMusic,

	AddFinishHighlights = function(round)
		Highlights.AddQuote(round)
	end,

	OnDeath = OnDeath,

	Duration = function()
		return 240
	end,

	OnStart = OnStart,
	OnFinish = OnFinish,

	OnItemEquipped = OnItemEquipped,

	BeforeDamageParticipant = BeforeHitParticipant,
}

return gamemode