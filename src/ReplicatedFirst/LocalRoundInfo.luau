local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Types = require(script.Parent.RoundRule.Types)
local module = {}

local replicatedData = ReplicatedFirst.RoundRule.ReplicatedData
local remotes = ReplicatedFirst.RoundRule.Remotes

local listeners: {[string]: {() -> ()}?} = {}

type CallbackName = "Gamemode" | "Role" | "RoundPhase" | "Credits"

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

remotes.AssignRole.OnClientEvent:Connect(function(name: string?)
    if not name then
        role = nil
        return runCallbacks("Role")
    end

    assert(gamemode, "Gamemode is not loaded")
    role = gamemode.Roles[name] or error("Role not found")

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
    runCallbacks("RoundPhase")
end)

return module