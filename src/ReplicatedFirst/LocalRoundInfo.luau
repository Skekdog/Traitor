local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Map = require(script.Parent.RoundRule.Map)
local Types = require(script.Parent.RoundRule.Types)
local module = {}

local replicatedData = ReplicatedFirst.RoundRule.ReplicatedData
local remotes = ReplicatedFirst.RoundRule.Remotes

local listeners: {[string]: {() -> ()}?} = {}

type CallbackName = "Map" | "Gamemode" | "Role" | "Phase" | "Credits" | "PlayerStatus" | "PlayerRole"

function module.Listen(name: CallbackName, callback: () -> ())
    if not listeners[name] then
        listeners[name] = {}
    end

    table.insert(listeners[name] :: {}, callback)
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

    local object = ReplicatedFirst.GameDefinition.Gamemodes:FindFirstChild(name)
    if object then
        gamemode = (require)(object)
    else
        gamemode = nil
    end

    runCallbacks("Gamemode")
end

replicatedData:GetAttributeChangedSignal("Gamemode"):Connect(onGamemodeChanged)
onGamemodeChanged()

local role: Types.Role?
function module.GetRole(): Types.Role?
    return role
end

local function getRoleFromName(name: string): Types.Role
    assert(gamemode, "Gamemode is not loaded")
    return gamemode.Roles[name] or error("Role not found")
end

remotes.AssignRole.OnClientEvent:Connect(function(name: string?)
    if not name then
        role = nil
        return runCallbacks("Role")
    end

    role = getRoleFromName(name)

    runCallbacks("Role")
end)

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

remotes.UpdatePlayerStatus.OnClientEvent:Connect(function(player: Player, status: Types.ParticipantStatus?)
    playerStatuses[player] = status
    runCallbacks("PlayerStatus")
end)

local playerRoles: {[Player]: Types.Role?} = {}
function module.GetPlayerRole(player: Player): Types.Role?
    return playerRoles[player]
end

remotes.UpdatePlayerRole.OnClientEvent:Connect(function(player: Player, name: string)
    playerRoles[player] = getRoleFromName(name)
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