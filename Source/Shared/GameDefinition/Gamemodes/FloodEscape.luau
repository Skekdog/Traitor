local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Audio = require(ReplicatedStorage.API.Audio)
local StandardGame = require(ReplicatedStorage.API.StandardGame)
local Types = require(ReplicatedStorage.API.Types)

local survivorRole: Types.RoleDefinition = {
	Kind = "RoleDefinition",

	Name = "Survivor",
	Description = "You can run but you can't hide.",
	Color = Color3.fromRGB(200, 255, 200),
	Sound = Audio.MakeSound({
		Content = Content.fromAssetId(9042819926),
	}),

	Allegiance = {Kind = "Role", Role = "Survivor"},

	Allies = {"Survivor"},
	RevealedRoles = {"Survivor"},

	CanDoSuspiciousActions = true,
	CanSeeMissingInAction = true,
}

local floodRole: Types.RoleDefinition = {
	Kind = "RoleDefinition",

	Name = "Flood",
	Description = "Glub glub",
	Color = Color3.fromRGB(26, 46, 221),
	Sound = Audio.MakeSound({
		Content = Content.fromAssetId(9042088276),
	}),

	Allegiance = {Kind = "Role", Role = "Flood"},
}

local floodMusic: {Sound} = {}
for _, v in ReplicatedStorage.Assets.VictoryMusic.Traitor:GetChildren() do
	if v:IsA("Sound") then
		table.insert(floodMusic, v)
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

local function getVictoryMusic(round: Types.Round, victor: Types.Victor, isTimeout: boolean): Sound
	if isTimeout then
		return survivorMusic[math.random(#survivorMusic)]
	end

	assert(victor.Kind == "Role")

	if victor.Definition == floodRole then
		return floodMusic[math.random(#floodMusic)]
	end

	return survivorMusic[math.random(#survivorMusic)]
end

local function getTimeoutVictor(round: Types.Round): Types.Role
	return round:GetRoleFromRoleName("Survivor")
end

local function OnStart(round: Types.Round): ()
	local map = round:GetMap().Structure

	local water = Instance.new("Part")
	water.Anchored = true
	water.Size = Vector3.new(2048, 1, 2048)
	water.Position = Vector3.new(0, -100, 0)
	water.Material = Enum.Material.Marble
	water.Transparency = 0.3
	water.Color = Color3.fromRGB(0, 94, 255)
	water.Name = "_FloodEscape_Water"
	water:AddTag("Water")
	water.CanCollide = false
	water.CollisionGroup = "Bounds"
	water.Parent = map.Dynamic

	TweenService:Create(water, TweenInfo.new(600), {
		Size = Vector3.new(2048, 1024, 2048),
		Position = Vector3.new(0, 502, 0),
	}):Play()
end

local function UnloadGamemode(round: Types.Round): ()
	local map = round:GetMap()
	local water = map.Structure.Dynamic:FindFirstChild("_FloodEscape_Water")

	if water then
		water:Destroy()
	end
end

local function getWinner(round: Types.Round): Types.Role?
    for _, participant in round:GetParticipants() do
        if participant:IsAlive() and participant:GetRole().Definition == survivorRole then
            return nil
        end
    end

    return round:GetRoleFromRoleName("Flood")
end

local function tryFinishRound(round: Types.Round): ()
    local winner = getWinner(round)
    if winner then
        round:Finish(winner)
    end
end

local function OnDeath(round: Types.Round, participant: Types.Participant): ()
    StandardGame.Highlights.OnDeath(round, participant)
	tryFinishRound(participant.Round)
end

local function AssignRoles(_, participants: {Types.Participant}): ()
	for _, participant in participants do
		participant:SetRole(survivorRole)
	end
end

local gamemode: Types.GamemodeDefinition = {
	Name = "FloodEscape",
	DisplayName = "Flood Escape",
	Authors = "@Skekdogs",
	Description = "Lol",
	MinimumPlayers = 1,

	Roles = {
		Survivor = survivorRole,
		Flood = floodRole,
	},

	Duration = function()
		return 60
	end,

	AvailableAmmo = StandardGame.GetAllAmmo(),
	AvailableItems = StandardGame.GetItems(),
	InteractableDefinitions = StandardGame.GetInteractables(),

	StartingItems = {
		StandardGame.GetItem("Crowbar"),
	},

	GetRoundEndMusic = getVictoryMusic,
	TimeoutVictor = getTimeoutVictor,

	OnStart = OnStart,
	UnloadGamemode = UnloadGamemode,

	AssignRoles = AssignRoles,

	OnDeath = OnDeath,
}

return gamemode