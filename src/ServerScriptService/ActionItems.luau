local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local InventoryManager = require(script.Parent.Parent.ReplicatedFirst.InventoryManager)
local Items = require(script.Parent.Parent.ReplicatedFirst.ItemsManager.Items)
local Types = require(script.Parent.Parent.ReplicatedFirst.RoundHandler.Types)
local WeaponsManager = require(script.Parent.WeaponsManager)
local module = {}

type Relationship = "__This" | Types.RoleRelationship | "__Part_"

local counters: {[string]: number?} = {}

local function tweenSlidingDoor(actionItem: Model, door: BasePart): ()
    local cframe = door.CFrame

    actionItem:SetAttribute("Disabled", true)
    TweenService:Create(door, TweenInfo.new(1), {CFrame = cframe * CFrame.new(0, 0, -2.8)}):Play()

    task.delay(5, function() -- Actions must never yield
        local tween = TweenService:Create(door, TweenInfo.new(1), {CFrame = cframe})
        tween.Completed:Once(function()
            actionItem:SetAttribute("Disabled", false)
        end)
        tween:Play()
    end)
end

local function playSlidingDoorSound(door: BasePart): ()
    local sound = door:FindFirstChild("DoorSound") or ServerStorage.DoorSound:Clone()
    assert(sound:IsA("Sound"), "DoorSound must be a Sound")
    sound.Parent = door
    sound:Play()
end

local function getMatchingParticipants(participant: Types.Participant, comparison: Relationship): {Types.Participant}
    if comparison == "__This" then
        return {participant}
    end

    local round = participant.Round

    local participants = {}
    if comparison:sub(1, 7) ~= "__Part_" then
        local validRoles
        if comparison == "__All" then
            validRoles = round.Gamemode.Roles
        else
            validRoles = {}
            for _, v in round.Gamemode.Roles do
                if round:CompareRoles(participant.Role, v, comparison) then
                    table.insert(validRoles, v)
                end
            end
        end
        
        for _, v in validRoles do
            table.move(round:GetParticipantsWithRole(v.Name), 1, 0, 1, participants)
        end
    else
        local part = participant.Round.Map.Map:FindFirstChild(comparison:split("__Part_")[1]) --todo: this should be Map.Dynamic
        assert(part, "Part not found")
        assert(part:IsA("BasePart"), "Part must be a BasePart")
        local function isPointInside(point: Vector3)
            local v3 = part.CFrame:PointToObjectSpace(point)
            return (math.abs(v3.X) <= part.Size.X / 2) and (math.abs(v3.Y) <= part.Size.Y / 2) and (math.abs(v3.Z) <= part.Size.Z / 2)
        end
        for _, v in round.Participants do
            if isPointInside(v.Character:GetPivot().Position) then
                table.insert(participants, v)
            end
        end
    end

    return participants
end

function module.ResetCounters(): ()
    counters = {}
end

module.Actions = {}

function module.Actions.SlidingDoor(actionItem: Model, _, doorName: unknown): ()
    assert(doorName, "Missing Parameter 1")
    assert(typeof(doorName) == "string", "Parameter 1 must be a string")

    local door = actionItem:FindFirstChild(doorName, true)
    assert(door, "Could not find Door")
    assert(door:IsA("BasePart"), "Door must be a BasePart")

    if actionItem:GetAttribute("Disabled") then
        return
    end

    tweenSlidingDoor(actionItem, door)
    playSlidingDoorSound(door)
end

function module.Actions.DoubleSlidingDoor(actionItem: Model, _, door1Name: unknown, door2Name: unknown): ()
    assert(door1Name, "Missing Parameter 1")
    assert(door2Name, "Missing Parameter 2")

    assert(typeof(door1Name) == "string", "Parameter 1 must be a string")
    assert(typeof(door2Name) == "string", "Parameter 2 must be a string")

    local door1 = actionItem:FindFirstChild(door1Name, true)
    local door2 = actionItem:FindFirstChild(door2Name, true)
    assert(door1, "Could not find Door 1")
    assert(door2, "Could not find Door 2")

    assert(door1:IsA("BasePart"), "Door 1 must be a BasePart")
    assert(door2:IsA("BasePart"), "Door 2 must be a BasePart")

    if actionItem:GetAttribute("Disabled") then
        return
    end

    tweenSlidingDoor(actionItem, door1)
    tweenSlidingDoor(actionItem, door2)

    playSlidingDoorSound(door1)
end

function module.Actions.GiveItem(_, participant: Types.Participant, item: unknown): ()
    assert(item, "Missing Parameter 1")
    assert(typeof(item) == "string", "Parameter 1 must be a string")
    assert(Items[item], "Invalid item")

    InventoryManager.NewItem(Items[item], nil, participant)
end

function module.Actions.SpawnProp(_, participant: Types.Participant, prop: unknown): ()
    assert(prop, "Missing Parameter 1")
    assert(typeof(prop) == "string", "Parameter 1 must be a string")

    local props = participant.Round.Map:FindFirstChild("Props")
    assert(props, "Map does not have a props folder!")

    local propInstance = props:FindFirstChild(prop)
    assert(propInstance, `Could not find prop with name {prop}`)

    propInstance = propInstance:Clone()
    propInstance.Parent = props
end

function module.Actions.TriggerVictory(_, participant: Types.Participant, team: unknown): ()
    assert(team, "Missing Parameter 1")
    assert(typeof(team) == "string", "Parameter 1 must be __This, __ThisParticipant, or a role name")

    local round = participant.Round

    if team == "__This" then
        round:EndRound(participant)
    elseif team == "__ThisRole" then
        round:EndRound(participant.Role)
    else
        round:EndRound(round:GetRoleFromName(team))
    end
end

function module.Actions.ExplosiveBarrel(actionItem: Model, participant: Types.Participant): ()
    WeaponsManager.CreateExplosion(actionItem:GetPivot().Position, {
        Kind = "Explosion",
        Radius = 25,
        Pressure = 50,
        Damage = 150,
    }, participant)
end

function module.Actions.IncrementCounter(_, _, name: unknown, amount: unknown): ()
    assert(name, "Missing Parameter 1")
    assert(typeof(name) == "string", "Parameter 1 must be a string")

    if not amount then
        amount = 1
    end
    assert(typeof(amount) == "number", "Parameter 2 must be a number")

    local counter = counters[name]
    if counter then
        counter += amount
    else
        counters[name] = amount
    end
end

--todo: This should use Map.Dynamic, not Map.Map
function module.Actions.MoveMapElement(_, participant: Types.Participant, name: unknown, cframe: unknown): ()
    assert(name, "Missing Parameter 1")
    assert(typeof(name) == "string", "Parameter 1 must be a string")

    assert(cframe, "Missing Parameter 2")
    assert(typeof(cframe) == "CFrame", "Parameter 2 must be a CFrame")

    local element = participant.Round.Map.Map:FindFirstChild(name, true)
    assert(element, `Map element with name {name} was not found!`)
    assert(element:IsA("PVInstance"), `Map element with name {name} is not a moveable Instance (PVInstance)! Check that there are no elements with an identical name.`)

    element:PivotTo(cframe)
end

function module.Actions.Teleport(_, participant: Types.Participant, targets: unknown, location: unknown): ()
    assert(targets, "Missing Parameter 1")
    assert(typeof(targets) == "string", "Parameter 1 must be __All, __Ally, __Enemy, __This, or a role name")

    assert(location, "Missing Parameter 2")
    assert(typeof(location) == "Vector3", "Parameter 2 must be a Vector3")

    local participants = getMatchingParticipants(participant, targets)

    for _, v in participants do
        v.Character:PivotTo(CFrame.new(location))
    end
end

function module.Actions.Kill(_, participant: Types.Participant, targets: unknown, cause: unknown, credit: unknown): ()
    assert(targets, "Missing Parameter 1")
    assert(typeof(targets) == "string", "Parameter 1 must be __All, __Ally, __Enemy, __This, or a role name")

    assert(table.find({"Blade", "Blunt", "Burn", "Crush", "Drown", "Explosion", "Fall", "Firearm", "Mutation", "Suicide"}, cause :: string), "Parameter 2 must be one of: Blade, Blunt, Burn, Crush, Drown, Explosion, Fall, Firearm, Mutation, Suicide")
    assert(typeof(credit) == "nil" or typeof(credit) == "boolean", "Parameter 3 must be a boolean or nil")

    local participants = getMatchingParticipants(participant, targets)
    for _, v in participants do
        v:TakeDamage(math.huge, if credit then participant else nil, cause :: any)
    end
end

function module.Actions.Wait(_, _, duration: unknown): ()
    assert(duration, "Missing Parameter 1")
    assert(typeof(duration) == "number")

    task.wait(duration)
end

function module.Actions.DeductCredits(_, participant: Types.Participant, amount: unknown): ()
    assert(amount, "Missing Parameter 1")
    assert(typeof(amount) == "number")

    participant:SetCredits(participant:GetCredits() - amount)
end

function module.Actions.PlaySound(actionItem: Model, participant: Types.Participant, soundName: unknown): ()
    assert(soundName, "Missing Parameter 1")
    assert(typeof(soundName) == "string", "Parameter 1 must be a string")

    local sound = actionItem:FindFirstChild(soundName, true)
    assert(sound, "Could not find Sound")
    assert(sound:IsA("Sound"), "Sound must be a Sound")

    sound:Play()
end

function module.Actions.Toggle(actionItem: Model): ()
    actionItem:SetAttribute("Disabled", not actionItem:GetAttribute("Disabled"))
end

module.Conditions = {}

local function getCounter(participant: Types.Participant, counter: string): number
    if counter == "Credits" then
        return participant:GetCredits()
    elseif counter == "Health" then
        return participant:GetHealth()
    end
    return counters[counter] or 0
end

function module.Conditions.CounterEq(participant: Types.Participant, counter: string, target: number): boolean
    return getCounter(participant, counter) == target
end

function module.Conditions.CounterGT(participant: Types.Participant, counter: string, target: number): boolean
    return getCounter(participant, counter) > target
end

function module.Conditions.CounterLT(participant: Types.Participant, counter: string, target: number): boolean
    return getCounter(participant, counter) < target
end

function module.Conditions.CounterLTE(participant: Types.Participant, counter: string, target: number): boolean
    return getCounter(participant, counter) <= target
end

function module.Conditions.CounterGTE(participant: Types.Participant, counter: string, target: number): boolean
    return getCounter(participant, counter) >= target
end

function module.Conditions.TeamIs(participant: Types.Participant, team: string): boolean
    return participant.Role.Allegiance == team
end

function module.Conditions.RoundInProgress(round: Types.Round): boolean
    return round:IsRoundInProgress()
end