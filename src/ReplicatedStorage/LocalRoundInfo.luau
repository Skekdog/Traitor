local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Map = require(script.Parent.RoundRule.Map)
local Role = require(script.Parent.RoundRule.Role)
local Types = require(script.Parent.RoundRule.Types)
local module = {}

local replicatedData = ReplicatedStorage.RoundRule.ReplicatedData
local remotes = ReplicatedStorage.RoundRule.Remotes

local listeners: {[string]: {() -> ()}?} = {}

type CallbackName = "Map" | "Gamemode" | "Role" | "Phase" | "Credits" | "PlayerStatus" | "PlayerRole"

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

local function getRoleFromName(name: string): Types.Role
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

local roundPhase: Types.RoundPhase = replicatedData:GetAttribute("Phase") :: Types.RoundPhase? or "Waiting"
function module.GetRoundPhase(): Types.RoundPhase
    return roundPhase
end

replicatedData:GetAttributeChangedSignal("Phase"):Connect(function()
    roundPhase = replicatedData:GetAttribute("Phase") :: Types.RoundPhase? or "Waiting"
    runCallbacks("Phase")
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

remotes.UpdatePlayerRole.OnClientEvent:Connect(function(name: string, roleName: string)
    local player = getPlayerFromName(name)
    if not player then
        return
    end

    playerRoles[player] = getRoleFromName(roleName)
    runCallbacks("PlayerRole")
end)

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