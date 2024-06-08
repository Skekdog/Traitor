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

local participants: {[string]: Types.PartialParticipant?} = {}
function module.GetParticipantInfo(name: string): Types.PartialParticipant?
    return participants[name]
end

local ownParticipant: Types.Participant?
function module.GetOwnParticipant(): Types.Participant?
    return ownParticipant
end

function module.GetAllParticipants(): {Types.PartialParticipant}
    local list = {}
    for _, v in participants do
        if not v then
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
    return replicatedData.MapFolder.Value :: Types.MapStructure?
end

local equipment
function module.GetAllEquipment(): {Types.Equipment}?
    return equipment
end

local roles
function module.GetAllRoles(): {Types.Role}?
    return roles
end

local roundEndInfo
function module.GetRoundEndInfo(): Types.RoundEndInfo?
    return roundEndInfo
end

type Attribute = "MapAuthors" | "MapName" | "GamemodeAuthors" | "GamemodeName" | "TimeMilestone" | "RoundPhase" | "IsPaused" | "RoundStartTime"
type AttributeValue = (string | number | boolean)?
type ListenerCallback<T> = (newValue: EventValue & T) -> ()
type Event = Attribute | "UpdateParticipant" | "UpdateOwnParticipant" | "UpdateEquipment" | "UpdateRoles" | "UpdateRoundEndInfo"
type EventValue = AttributeValue | Types.Participant | {Types.Equipment} | {Types.Role} | Types.RoundEndInfo | Types.PartialParticipant | nil

local listeners: {[Event]: {ListenerCallback<EventValue>}} = {}
for i in replicatedData:GetAttributes() do
    listeners[i :: Attribute] = {}
end

for _, v in {"UpdateParticipant", "UpdateOwnParticipant", "UpdateEquipment", "UpdateRoles", "UpdateRoundEndInfo"} do
    listeners[v :: Event] = {}
end

--- @returns A function to stop listening for changes
function module.Listen<T>(event: Event, callback: ListenerCallback<T>): () -> ()
    table.insert(listeners[event], callback :: ListenerCallback<EventValue>)
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

replicatedData.AttributeChanged:Connect(function(attr)
    runCallbacks(attr :: Attribute, get(attr :: Attribute))
end)

replicatedData.UpdateParticipant.OnClientEvent:Connect(function(participant: Types.PartialParticipant | string)
    if type(participant) == "string" then
        participants[participant] = nil
        runCallbacks("UpdateParticipant", participant)
        return
    end
    participants[participant.Player.Name] = participant
    runCallbacks("UpdateParticipant", participant)
end)

replicatedData.UpdateOwnParticipant.OnClientEvent:Connect(function(participant: Types.Participant?)
    ownParticipant = participant
    runCallbacks("UpdateOwnParticipant", participant)
end)

replicatedData.UpdateEquipment.OnClientEvent:Connect(function(newEquipment: {Types.Equipment}?)
    equipment = newEquipment
    runCallbacks("UpdateEquipment", newEquipment)
end)

replicatedData.UpdateRoles.OnClientEvent:Connect(function(newRoles: {Types.Role}?)
    roles = newRoles
    runCallbacks("UpdateRoles", newRoles)
end)

replicatedData.UpdateRoundEndInfo.OnClientEvent:Connect(function(newInfo: Types.RoundEndInfo)
    roundEndInfo = newInfo
    runCallbacks("UpdateRoundEndInfo", newInfo)
end)

return module