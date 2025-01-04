local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Map = require(script.Parent.RoundRule.Map)
local Role = require(script.Parent.RoundRule.Role)
local Types = require(script.Parent.RoundRule.Types)
local module = {}

local replicatedData = ReplicatedStorage.RoundRule.ReplicatedData
local remotes = ReplicatedStorage.RoundRule.Remotes

local listeners: {[string]: {() -> ()}?} = {}

type CallbackName = "Map" | "Gamemode" | "Role" | "Paused" | "Phase" | "AdvanceTime" | "Credits" | "PlayerStatus" | "PlayerRole" | "Winner" | "WinnerKind" | "StartTime"

type RoundHighlight = {
    Title: string,
    Description: string
}

type RoundEvent = {
    Timestamp: number,
    Description: string,
    WasFreeKill: boolean?,
    WasSelfDefense: boolean?,
    WasCorrectKill: boolean?,
}

function module.Listen(name: CallbackName, callback: () -> (), runImmediately: boolean?): ()
    if not listeners[name] then
        listeners[name] = {}
    end

    table.insert(listeners[name] :: {}, callback)

    if runImmediately then
        task.defer(callback)
    end
end

local function runCallbacks(name: CallbackName): ()
    if not listeners[name] then
        return
    end

    for _, callback in listeners[name] :: {() -> ()} do
        callback()
    end
end

local gamemode: Types.Gamemode?
function module.GetGamemode()
    return gamemode
end

local function onGamemodeChanged()
    local name = replicatedData:GetAttribute("Gamemode") :: string?
    if not name then
        gamemode = nil
        return runCallbacks("Gamemode")
    end

    local object = ReplicatedStorage.GameDefinition.Gamemodes:FindFirstChild(name)
    if object then
        gamemode = (require)(object)
    else
        gamemode = nil
    end

    runCallbacks("Gamemode")
end

replicatedData:GetAttributeChangedSignal("Gamemode"):Connect(onGamemodeChanged)
onGamemodeChanged()

local function getRoleFromName(name: string?): Types.Role?
    if not name then
        return nil
    end
    
    assert(gamemode, "Gamemode is not loaded")
    return Role.fromDefinition(gamemode.Roles[name] or error("Role not found"))
end

local credits: number = 0
function module.GetCredits(): number
    return credits
end

remotes.UpdateCredits.OnClientEvent:Connect(function(value: number?)
    credits = value or 0
    runCallbacks("Credits")
end)

function module.GetRoundHighlights(): {RoundHighlight}
    local highlights: {RoundHighlight} = {}
    for _, v in replicatedData.Highlights:GetChildren() do
        if v:IsA("StringValue") then
            table.insert(highlights, {
                Title = v.Name,
                Description = v.Value
            })
        end
    end

    return highlights
end

function module.GetOrderedRoundEvents(): {RoundEvent}
    local events: {RoundEvent} = {}
    for _, v in replicatedData.Events:GetChildren() do
        if v:IsA("StringValue") then
            table.insert(events, {
                Timestamp = tonumber(v.Name) or error("Invalid timestamp"),
                Description = v.Value,
                WasFreeKill = v:GetAttribute("WasFreeKill") :: boolean?,
                WasSelfDefense = v:GetAttribute("WasSelfDefense") :: boolean?,
                WasCorrectKill = v:GetAttribute("WasCorrectKill") :: boolean?,
            })
        end
    end

    table.sort(events, function(a, b)
        return a.Timestamp < b.Timestamp
    end)

    return events
end

local roundPhase: Types.RoundPhase = replicatedData:GetAttribute("Phase") :: Types.RoundPhase? or "Waiting"
function module.GetRoundPhase(): Types.RoundPhase
    return roundPhase
end

local advanceTime: number? = replicatedData:GetAttribute("AdvanceTime") :: number?
function module.GetAdvanceTime(): number?
    return advanceTime
end

local winner: string? = replicatedData:GetAttribute("Winner") :: string?
function module.GetWinner(): string?
    return winner
end

local winnerKind: "Role" | "Participant"? = replicatedData:GetAttribute("WinnerKind") :: "Role" | "Participant"?
function module.GetWinnerKind(): "Role" | "Participant"?
    return winnerKind
end

local paused: boolean = replicatedData:GetAttribute("Paused") :: boolean
function module.IsPaused(): boolean
    return paused
end

local startTime: number? = replicatedData:GetAttribute("StartTime") :: number?
function module.GetRoundStartTime(): number?
    return startTime
end

replicatedData:GetAttributeChangedSignal("Winner"):Connect(function()
    winner = replicatedData:GetAttribute("Winner") :: string?
    runCallbacks("Winner")
end)

replicatedData:GetAttributeChangedSignal("WinnerKind"):Connect(function()
    winnerKind = replicatedData:GetAttribute("WinnerKind") :: "Role" | "Participant"?
    runCallbacks("WinnerKind")
end)

replicatedData:GetAttributeChangedSignal("Phase"):Connect(function()
    roundPhase = replicatedData:GetAttribute("Phase") :: Types.RoundPhase? or "Waiting"
    runCallbacks("Phase")
end)

replicatedData:GetAttributeChangedSignal("Paused"):Connect(function()
    paused = replicatedData:GetAttribute("Paused") :: boolean
    runCallbacks("Paused")
end)

replicatedData:GetAttributeChangedSignal("StartTime"):Connect(function()
    startTime = replicatedData:GetAttribute("StartTime") :: number?
    runCallbacks("StartTime")
end)

replicatedData:GetAttributeChangedSignal("AdvanceTime"):Connect(function()
    advanceTime = replicatedData:GetAttribute("AdvanceTime") :: number?
    runCallbacks("AdvanceTime")
end)

local playerStatuses: {[Player]: Types.ParticipantStatus?} = {}
function module.GetPlayerStatus(player: Player): Types.ParticipantStatus
    return playerStatuses[player] or "Spectating"
end

local function getPlayerFromName(name: string): Player?
    for _, player in Players:GetPlayers() do
        if player.Name == name then
            return player
        end
    end

    return nil
end

remotes.UpdatePlayerStatus.OnClientEvent:Connect(function(name: string, status: Types.ParticipantStatus?)
    local player = getPlayerFromName(name)
    if not player then
        return
    end

    playerStatuses[player] = status
    runCallbacks("PlayerStatus")
end)

local playerRoles: {[Player]: Types.Role?} = {}
function module.GetPlayerRole(player: Player): Types.Role?
    return playerRoles[player]
end

remotes.UpdatePlayerRole.OnClientEvent:Connect(function(name: string, roleName: string?)
    local player = getPlayerFromName(name)
    if not player then
        return
    end

    playerRoles[player] = getRoleFromName(roleName)
    runCallbacks("PlayerRole")
end)

function module.GetPlayerScores(): {[Player]: Types.ScoreTable}
    local playerScores: {[Player]: Types.ScoreTable} = {}
    for _, v in replicatedData.Scores:GetChildren() do
        if v:IsA("StringValue") then
            local player = getPlayerFromName(v.Name)
            if not player then
                continue
            end

            playerScores[player] = {}
            for reason, value in v:GetAttributes() do
                playerScores[player][reason] = value :: number
            end
        end
    end

    return playerScores
end

local map: Types.Map?
local mapScript = workspace:FindFirstChild("Map")
if mapScript then
    if mapScript:IsA("ModuleScript") then
        map = Map.fromModuleScript(mapScript)
    end
end

workspace.ChildAdded:Connect(function(child)
    if not child:IsA("ModuleScript") or child.Name ~= "Map" then
        return
    end

    if #child:GetChildren() < 1 then
        child.ChildAdded:Wait()
    end

    map = Map.fromModuleScript(child)
    runCallbacks("Map")
end)

function module.GetMap(): Types.Map?
    return map
end

return module