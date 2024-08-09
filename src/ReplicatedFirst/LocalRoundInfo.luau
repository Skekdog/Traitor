local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemTypes = require(script.Parent.ItemTypes)
local Types = require(script.Parent.RoundHandler.Types)
local replicatedData = ReplicatedStorage:WaitForChild("RoundHandler")

local module = {}

local function get(attr)
    return replicatedData:GetAttribute(attr)
end

function module.IsPaused(): boolean
    return get("IsPaused") :: boolean
end

function module.GetTimeMilestone(): number
    return get("TimeMilestone") :: number
end

function module.GetStartTime(): number
    return get("RoundStartTime") :: number
end

local participants: {[string]: Types.ClientParticipant?} = {}
function module.GetParticipantInfo(name: string): Types.ClientParticipant?
    return participants[name]
end

local ownParticipant: Types.ClientOwnParticipant?
function module.GetOwnParticipant(): Types.ClientOwnParticipant?
    return ownParticipant
end

local roles: {[Types.GamemodeRoleString]: Types.Role} = {}
function module.GetRole(name: Types.GamemodeRoleString): Types.Role
    return roles[name]
end

function module.GetAllParticipants(): {Types.ClientParticipant}
    local list = {}
    for _, v in participants do
        assert(v) -- todo: check that this doesn't error
        table.insert(list, v)
    end
    return list
end

function module.GetRoundPhase(): Types.RoundPhase
    return get("RoundPhase") :: Types.RoundPhase
end

function module.GetMap(): Types.MapStructureCast?
    return replicatedData.MapFolder.Value :: Types.MapStructureCast?
end

local equipment
function module.GetAllEquipment(): {Types.Equipment}?
    return equipment
end

function module.GetAllRoles(): {Types.Role}
    local returnRoles = {}
    for _, v in roles do
        table.insert(returnRoles, v)
    end
    return returnRoles
end

local roundEndInfo
function module.GetRoundEndInfo(): Types.RoundEndInfo?
    return roundEndInfo
end

local listeners: {[string]: {(any, any) -> ()}} = {}
for i in replicatedData:GetAttributes() do
    listeners[i] = {}
end

for _, v in {"UpdateParticipant", "UpdateOwnParticipant", "UpdateEquipment", "UpdateRoles", "UpdateRoundEndInfo", "IsSpectating", "PrimaryFire"} do
    listeners[v] = {}
end

type Ret = () -> ()
type Listen =
    (("UpdateParticipant", (Player, Types.ClientParticipant?) -> ()) -> Ret) &
    (("UpdateOwnParticipant", (Player, Types.ClientOwnParticipant?) -> ()) -> Ret) &
    (("UpdateEquipment", ({Types.Equipment}) -> ()) -> Ret) &
    (("UpdateRoles", ({Types.Role}) -> ()) -> Ret) &
    (("UpdateRoundEndInfo", (Types.RoundEndInfo) -> ()) -> Ret) &

    (("IsSpectating", (boolean) -> ()) -> Ret) &

    (("MapAuthors", ((string) -> ()), boolean?) -> Ret) &
    (("MapName", ((string) -> ()), boolean?) -> Ret) &
    (("GamemodeAuthors", ((string) -> ()), boolean?) -> Ret) &
    (("GamemodeName", ((string) -> ()), boolean?) -> Ret) &

    (("TimeMilestone", ((number) -> ()), boolean?) -> Ret) &
    (("RoundPhase", ((Types.RoundPhase) -> ()), boolean?) -> Ret) &
    (("IsPaused", ((boolean) -> ()), boolean?) -> Ret) &
    (("RoundStartTime", ((number) -> ()), boolean?) -> Ret) &
    
    (("PrimaryFire", (ItemTypes.Weapon) -> ()) -> Ret)

--- @returns A function to stop listening for changes
module.Listen = function(event, callback, runInstant: boolean?)
    table.insert(listeners[event], callback)
    local pos = #listeners[event]

    if runInstant then
        callback(get(event))
    end

    return function()
        listeners[event][pos] = nil
    end
end :: Listen

local function runCallbacks(event, ...)
    for _, v in listeners[event] do
        v(...)
    end
end

function module.PrimaryFire(item: ItemTypes.Weapon): ()
    runCallbacks("PrimaryFire", item)
end

local isSpectating = false
function module.IsSpectating(): boolean
    return isSpectating
end

module.DNACharge = 1000

function module.SetSpectating(value: boolean): ()
    isSpectating = value
    runCallbacks("IsSpectating", value)
end

replicatedData.AttributeChanged:Connect(function(attr)
    runCallbacks(attr, get(attr))
end)

replicatedData.UpdateParticipant.OnClientEvent:Connect(function(player: Player, participant: Types.ClientParticipant?)
    participants[player.Name] = participant
    runCallbacks("UpdateParticipant", player, participant)
end)

replicatedData.UpdateOwnParticipant.OnClientEvent:Connect(function(player: Player, participant: Types.ClientOwnParticipant?)
    ownParticipant = participant
    runCallbacks("UpdateOwnParticipant", player, participant)
end)

replicatedData.UpdateEquipment.OnClientEvent:Connect(function(newEquipment: {Types.Equipment}?)
    equipment = newEquipment
    runCallbacks("UpdateEquipment", newEquipment)
end)

replicatedData.UpdateRoles.OnClientEvent:Connect(function(gamemodeName: string?, newRoles: {Types.Role}?)
    if not newRoles or not gamemodeName then
        roles = {}
    else
        for _, v in newRoles do
            roles[gamemodeName.."__"..v.Name] = v
        end
        roles[gamemodeName.."__"] = {
            Kind = "Role",
            Name = "",
            Colour = Color3.new(),
        }
    end
    runCallbacks("UpdateRoles", newRoles)
end)

replicatedData.UpdateRoundEndInfo.OnClientEvent:Connect(function(newInfo: Types.RoundEndInfo)
    roundEndInfo = newInfo
    runCallbacks("UpdateRoundEndInfo", newInfo)
end)

return module