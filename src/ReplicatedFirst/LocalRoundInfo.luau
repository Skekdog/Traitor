local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Types = require(script.Parent.RoundRule.Types)
local module = {}

local replicatedData = ReplicatedFirst.RoundRule.ReplicatedData
local remotes = ReplicatedFirst.RoundRule.Remotes

local gamemode: Types.Gamemode?
function module.GetGamemode()
    return gamemode
end

local function onGamemodeChanged()
    local name = replicatedData:GetAttribute("Gamemode") :: string?
    if not name then
        gamemode = nil
        return
    end

    local object = ReplicatedFirst.GameDefinition.Gamemodes:FindFirstChild(name)
    if object then
        gamemode = (require)(object)
    end
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
        return
    end

    assert(gamemode, "Gamemode is not loaded")
    role = gamemode.Roles[name] or error("Role not found")
end)

local credits: number = 0
function module.GetCredits(): number
    return credits
end

remotes.UpdateCredits.OnClientEvent:Connect(function(value: number?)
    credits = value or 0
end)

local roundPhase: Types.RoundPhase = replicatedData:GetAttribute("Phase") :: Types.RoundPhase? or "Waiting"
function module.GetRoundPhase(): Types.RoundPhase
    return roundPhase
end

replicatedData:GetAttributeChangedSignal("Phase"):Connect(function()
    roundPhase = replicatedData:GetAttribute("Phase") :: Types.RoundPhase? or "Waiting"
end)



return module