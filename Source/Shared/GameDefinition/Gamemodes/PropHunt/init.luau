local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PropHuntItems = require(script.PropHuntItems)
local StandardGame = require(ReplicatedStorage.API.StandardGame)
local Types = require(ReplicatedStorage.API.Types)

local Ammo = StandardGame.GetAllAmmo()
local Interactables = StandardGame.GetInteractables()

local items = {}
for i, v in StandardGame.GetItems() do
	items[i] = v
end

for i, v in PropHuntItems do
	items[i] = v
end

local ROUND_DURATION = 300
local HIDE_TIME = 30

local Items = items

local roles: {[string]: Types.RoleDefinition} = {
    Hunter = {
        Kind = "RoleDefinition",
        Name = "Hunter",
        Description = "Eliminate the Props!",
        Sound = "rbxassetid://9042088276",
        Color = Color3.fromRGB(229, 53, 13),

        Allegiance = {Kind = "Role", Role = "Hunter"},

        StartingItems = {},
        StartingCredits = 1,

        EquipmentShop = {
            Items["Jetpack"],
        },

        CanSeeMissingInAction = true,
        CanStealCreditsFromCorpses = true,

        RevealedRoles = {"Hunter", "Prop"},
    },

    Prop = {
        Kind = "RoleDefinition",
        Name = "Prop",
        Description = "Hide from the Hunters! They have Radars.",
        Sound = "rbxassetid://9042088276",
        Color = Color3.fromRGB(13, 197, 229),

        Allegiance = {Kind = "Role", Role = "Prop"},

        StartingItems = {Items.Propper},
        StartingCredits = 1,

        EquipmentShop = {
            Items["Radar"]
        },

        CanSeeMissingInAction = true,
        CanStealCreditsFromCorpses = false,

        RevealedRoles = {"Hunter", "Prop"},
    }
}

local function onStart(round: Types.Round): ()
    local map = round:GetMap()
    local platform = map.Structure.Dynamic:FindFirstChild("_PropHunt_Platform") :: typeof(ReplicatedStorage.Assets.Gamemode.PropHunt._PropHunt_Platform)?

    if not platform then
        local new = ReplicatedStorage.Assets.Gamemode.PropHunt._PropHunt_Platform:Clone()
        new:PivotTo(CFrame.new(-10000, 10000, 10000))
        new.Parent = map.Structure.Dynamic :: any
        platform = new
    end
    assert(platform)

    for _, hunter in round:GetParticipantsWithRole(round:GetRoleFromRoleName("Hunter")) do
        local char = hunter:GetCharacter()
        if char then
            char:PivotTo(platform.CFrame)
        end
    end

    round:SetPhase("Playing", HIDE_TIME, function()
        round:SetPhase("Playing", ROUND_DURATION - HIDE_TIME)
        for _, hunter in round:GetParticipantsWithRole(round:GetRoleFromRoleName("Hunter")) do
            hunter:MoveToSpawn()
        end
    end)
end

local gamemode: Types.GamemodeDefinition = {
    Name = "PropHunt",
    DisplayName = "Prop Hunt",
    Description = "Hide from hunters as props.",

    Authors = "@Skekdogs",

    MinimumPlayers = 1,

    TimeoutVictor = function(round) return round:GetRoleFromRoleName("Prop") end,
    GetRoundEndMusic = function() return nil end,

    AssignRoles = function(i, participants: {Types.Participant})
        for i, v in participants do
            if i % 2 == 1 then
                v:SetRole(roles.Hunter)
            else
                v:SetRole(roles.Prop)
            end
        end
    end,

    GetVictoryEventText = function(round: Types.Round, victor: Types.Victor, isTimeout: boolean): string?
        if isTimeout then
            return "The time has run out and the player with the highest score has won."
        end
        return if victor.Kind == "Participant" then victor:GetFormattedName() .. " has won the round!" else nil
    end,

    EnableFriendlyFire = false,
    EnableKarma = false,

    AvailableItems = Items,
    AvailableAmmo = Ammo,

    InteractableDefinitions = Interactables,

    StartingItems = {},

    Duration = function(_, numParticipants: number)
		return 0
	end,

    Roles = roles,

    OnDeath = function(round, participant: Types.Participant, deferVictoryCheck: boolean)
        StandardGame.Highlights.OnDeath(round, participant)

        local corpse = participant.Corpse
        local attacker = if corpse then corpse.Killer else nil
        if attacker then
            if attacker == participant then
                attacker:AddScore("Suicide", -2)
            else
                attacker:AddScore("Killed Player", 1)
                if not participant.Round.Extras.AnyKillsHappened then
                    participant.Round.Extras.AnyKillsHappened = true
                    participant.Round:AddHighlight({
                        Title = "First Blood",
                        Description = attacker:GetFormattedName() .. " drew the first blood of the round.",
                        Priority = 2,
                        Group = "First Blood",
                    })
                end
            end
        end

        if deferVictoryCheck then
            task.defer(function(_) end, participant.Round)
        else
            (function(_) end)(participant.Round)
        end
    end,

    AddFinishHighlights = function(round)
        StandardGame.Highlights.FinishHighlights(round)
    end,

    OnStart = onStart,
}

return gamemode