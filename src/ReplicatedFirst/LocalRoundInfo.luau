local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(script.Parent.RoundHandler.Types)
local replicatedData = ReplicatedStorage:WaitForChild("RoundHandler") :: typeof(ReplicatedStorage.RoundHandler) -- Yes this is in ReplicatedFirst, but it's nice to have few containers for scripts

local module = {}

local function get(attr: Attribute)
    return replicatedData:GetAttribute(attr)
end

function module.IsPaused(): boolean
    return get("IsPaused")
end

function module.GetTimeMilestone(): number
    return get("TimeMilestone")
end

function module.GetStartTime(): number
    return get("RoundStartTime")
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
        if not v then -- what?
            continue
        end
        table.insert(list, v)
    end
    return list
end

function module.GetRoundPhase(): Types.RoundPhase
    return get("RoundPhase")
end

function module.GetMap(): Types.MapStructure?
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

type Attribute = "MapAuthors" | "MapName" | "GamemodeAuthors" | "GamemodeName" | "TimeMilestone" | "RoundPhase" | "IsPaused" | "RoundStartTime"
type AttributeValue = (string | number | boolean)?
type ListenerCallback = (newValue: EventValue) -> ()
type Event = Attribute | "UpdateParticipant" | "UpdateOwnParticipant" | "UpdateEquipment" | "UpdateRoles" | "UpdateRoundEndInfo" | "IsSpectating"
type EventValue = AttributeValue | Types.ClientParticipant | {Types.Equipment} | {Types.Role} | Types.RoundEndInfo | Types.ClientOwnParticipant | nil

local listeners: {[Event]: {ListenerCallback}} = {}
for i in replicatedData:GetAttributes() do
    listeners[i :: Attribute] = {}
end

for _, v in {"UpdateParticipant", "UpdateOwnParticipant", "UpdateEquipment", "UpdateRoles", "UpdateRoundEndInfo", "IsSpectating"} do
    listeners[v :: Event] = {}
end

--- @returns A function to stop listening for changes
function module.Listen(event: Event, callback: ListenerCallback): () -> ()
    table.insert(listeners[event], callback :: ListenerCallback)
    local pos = #listeners[event]
    return function()
        listeners[event][pos] = nil
    end
end

local function runCallbacks(event: Event, newValue: EventValue)
    for _, v in listeners[event :: Event] do
        v(newValue)
    end
end

local isSpectating = false
function module.IsSpectating(): boolean
    return isSpectating
end

function module.SetSpectating(value: boolean): ()
    isSpectating = value
    runCallbacks("IsSpectating", value)
end

replicatedData.AttributeChanged:Connect(function(attr)
    runCallbacks(attr :: Attribute, get(attr :: Attribute))
end)

replicatedData.UpdateParticipant.OnClientEvent:Connect(function(participant: Types.ClientParticipant | string)
    if type(participant) == "string" then
        participants[participant] = nil
        runCallbacks("UpdateParticipant", participant)
        return
    end
    participants[participant.Player.Name] = participant
    runCallbacks("UpdateParticipant", participant)
end)

replicatedData.UpdateOwnParticipant.OnClientEvent:Connect(function(participant: Types.ClientOwnParticipant?)
    ownParticipant = participant
    runCallbacks("UpdateOwnParticipant", participant)
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