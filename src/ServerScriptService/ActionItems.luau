local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CreateEmptyPart = require(script.Parent.Parent.ReplicatedFirst.CreateEmptyPart)
local InventoryManager = require(script.Parent.Parent.ReplicatedFirst.InventoryManager)
local Items = require(script.Parent.Parent.ReplicatedFirst.ItemsManager.Items)
local Types = require(script.Parent.Parent.ReplicatedFirst.RoundHandler.Types)
local module = {}

local serverClient = ReplicatedStorage.ServerClient

type Relationship = "__This" | Types.RoleRelationship | "__Part_"

local counters: {[string]: number?} = {}

local function tweenSlidingDoor(actionItem: Model, door: BasePart, mult: number?): ()
    actionItem:SetAttribute("Disabled", true)

    mult = mult or -1
    assert(mult)

    local cframe = door.CFrame
    local target = cframe * CFrame.new(0, 0, mult * 2.8)

    door.CFrame = target -- on the server we just set it instantly, the client will tween it
    serverClient.TweenSlidingDoor:FireAllClients(door, cframe, target)

    task.delay(5, function() -- Actions must never yield
        door.CFrame = cframe
        serverClient.TweenSlidingDoor:FireAllClients(door, target, cframe)
        task.wait(1)
        actionItem:SetAttribute("Disabled", false)
    end)
end

local function playSlidingDoorSound(door: BasePart): ()
    local sound = door:FindFirstChild("SlidingDoorSound") or ServerStorage.SlidingDoorSound:Clone()
    assert(sound:IsA("Sound"), "DoorSound must be a Sound");
    (sound :: Sound).Parent = door
    sound.Ended:Once(function()
        sound:Destroy()
    end)
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

local function interpretStringParameter(parameter: string): string
    local split = parameter:split(" ")
    if split[1] == "ONEOF" and #split > 1 then
        return split[math.random(2, #split)]
    end
    return parameter
end

function module.ResetCounters(): ()
    counters = {}
end

module.Actions = {}

function module.Actions.SlidingDoor(actionItem: Model, _, doorName: unknown): ()
    assert(doorName, "Missing Parameter 1")
    assert(typeof(doorName) == "string", "Parameter 1 must be a string")

    doorName = interpretStringParameter(doorName)

    local door = actionItem:FindFirstChild(doorName, true)
    assert(door, "Could not find Door "..doorName)
    assert(door:IsA("BasePart"), "Door must be a BasePart "..doorName)

    tweenSlidingDoor(actionItem, door)
    playSlidingDoorSound(door)
end

function module.Actions.DoubleSlidingDoor(actionItem: Model, _, door1Name: unknown, door2Name: unknown): ()
    assert(door1Name, "Missing Parameter 1")
    assert(door2Name, "Missing Parameter 2")

    assert(typeof(door1Name) == "string", "Parameter 1 must be a string")
    assert(typeof(door2Name) == "string", "Parameter 2 must be a string")

    door1Name = interpretStringParameter(door1Name)
    door2Name = interpretStringParameter(door2Name)

    local door1 = actionItem:FindFirstChild(door1Name, true)
    local door2 = actionItem:FindFirstChild(door2Name, true)
    assert(door1, "Could not find Door 1 "..door1Name)
    assert(door2, "Could not find Door 2 "..door2Name)

    assert(door1:IsA("BasePart"), "Door 1 must be a BasePart "..door1Name)
    assert(door2:IsA("BasePart"), "Door 2 must be a BasePart "..door2Name)

    tweenSlidingDoor(actionItem, door1)
    tweenSlidingDoor(actionItem, door2, 1)

    playSlidingDoorSound(door1)
end

function module.Actions.GiveItem(actionItem: Model, participant: Types.Participant, item: unknown): ()
    assert(item, "Missing Parameter 1")
    assert(typeof(item) == "string", "Parameter 1 must be a string")

    item = interpretStringParameter(item)

    assert(Items[item], "Invalid item "..item)

    InventoryManager.NewItem(Items[item], nil, participant)
end

function module.Actions.SpawnProp(actionItem: Model, participant: Types.Participant, prop: unknown): ()
    assert(prop, "Missing Parameter 1")
    assert(typeof(prop) == "string", "Parameter 1 must be a string")

    local props = participant.Round.Map:FindFirstChild("Props")
    assert(props, "Map does not have a props folder")

    prop = interpretStringParameter(prop)

    local propInstance = props:FindFirstChild(prop) :: PVInstance?
    assert(propInstance, `Could not find prop with name {prop}`)

    propInstance = propInstance:Clone()
    propInstance:PivotTo(actionItem:GetPivot())
    propInstance.Parent = props
end

function module.Actions.TriggerVictory(_, participant: Types.Participant, team: unknown): ()
    assert(team, "Missing Parameter 1")
    assert(typeof(team) == "string", "Parameter 1 must be __This, __ThisParticipant, or a role name")

    team = interpretStringParameter(team)

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
    local WeaponsManager = require(script.Parent.WeaponsManager)
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

    name = interpretStringParameter(name)

    assert(name:sub(1, 2) ~= "__", "Parameter 1 invalid as counters starting with '__' are reserved "..name)

    if not amount then
        amount = 1
    end
    assert(typeof(amount) == "number", "Parameter 2 must be a number or nil")

    local counter = counters[name]
    if counter then
        counters[name] = counter + amount -- Unable to use += here because of whacky type-checking
    else
        counters[name] = amount
    end
end

--todo: This should use Map.Dynamic, not Map.Map
function module.Actions.MoveMapElement(actionItem: Model, participant: Types.Participant, name: unknown, cframe: unknown): ()
    assert(name, "Missing Parameter 1")
    assert(typeof(name) == "string", "Parameter 1 must be a string")

    name = interpretStringParameter(name)

    assert(cframe, "Missing Parameter 2")
    assert(typeof(cframe) == "CFrame", "Parameter 2 must be a CFrame")

    local element = if name == "__This" then actionItem else participant.Round.Map.Map:FindFirstChild(name, true)
    assert(element, `Map element with name {name} was not found`)
    assert(element:IsA("PVInstance"), `Map element with name {name} is not a moveable Instance (PVInstance)! Check that there are no elements with an identical name.`)

    element:PivotTo(cframe)
end

--todo: This should use Map.Dynamic, not Map.Map
function module.Actions.MoveMapElementRelative(actionItem: Model, participant: Types.Participant, name: unknown, cframe: unknown): ()
    assert(name, "Missing Parameter 1")
    assert(typeof(name) == "string", "Parameter 1 must be a string")

    name = interpretStringParameter(name)

    assert(cframe, "Missing Parameter 2")
    assert(typeof(cframe) == "CFrame", "Parameter 2 must be a CFrame")

    local element = if name == "__This" then actionItem else participant.Round.Map.Map:FindFirstChild(name, true)
    assert(element, `Map element with name {name} was not found`)
    assert(element:IsA("PVInstance"), `Map element with name {name} is not a moveable Instance (PVInstance)! Check that there are no elements with an identical name.`)

    element:PivotTo(element:GetPivot() * cframe)
end

function module.Actions.Teleport(_, participant: Types.Participant, targets: unknown, location: unknown): ()
    assert(targets, "Missing Parameter 1")
    assert(typeof(targets) == "string", "Parameter 1 must be __All, __Ally, __Enemy, __This, or a role name")

    targets = interpretStringParameter(targets)

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

    targets = interpretStringParameter(targets)

    assert(cause, "Missing Parameter 2")
    assert(table.find({"Blade", "Blunt", "Burn", "Crush", "Drown", "Explosion", "Fall", "Firearm", "Mutation", "Suicide"}, cause :: string), "Parameter 2 must be one of: Blade, Blunt, Burn, Crush, Drown, Explosion, Fall, Firearm, Mutation, Suicide")
    assert(typeof(credit) == "nil" or typeof(credit) == "boolean", "Parameter 3 must be a boolean or nil")

    local participants = getMatchingParticipants(participant, targets)
    for _, v in participants do
        v:TakeDamage(math.huge, if credit then participant else nil, cause :: any)
    end
end

function module.Actions.Wait(_, _, duration: unknown): ()
    assert(duration, "Missing Parameter 1")
    assert(typeof(duration) == "number", "Parameter 1 must be a number")

    task.wait(duration)
end

function module.Actions.DeductCredits(_, participant: Types.Participant, amount: unknown): ()
    assert(amount, "Missing Parameter 1")
    assert(typeof(amount) == "number", "Parameter 1 must be a number")

    participant:SetCredits(participant:GetCredits() - amount)
end

function module.Actions.PlaySound(actionItem: Model, participant: Types.Participant, soundName: unknown): ()
    assert(soundName, "Missing Parameter 1")
    assert(typeof(soundName) == "string", "Parameter 1 must be a string")

    soundName = interpretStringParameter(soundName)

    local sound = actionItem:FindFirstChild(soundName, true)
    assert(sound, "Could not find Sound "..soundName)
    assert(sound:IsA("Sound"), "Sound must be a Sound "..soundName)

    sound = sound:Clone()
    local part = CreateEmptyPart(actionItem:GetPivot(), {sound :: Instance})
    part.Parent = workspace.Projectiles

    sound.Ended:Once(function()
        part:Destroy()
    end)

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
    elseif counter == "RoundInProgress" then
        return if participant.Round:IsRoundInProgress() then 1 else 0
    end
    return counters[counter] or 0
end

local function getRoleEq(role: Types.Role, operator: "==" | "?=" | string): Types.RoleName
    if operator == "?=" then
        return role.Allegiance or role.Name
    elseif operator == "==" then
        return role.Name
    end
    error("Invalid operator for role comparison")
end

local function getConditionalParameterValue(participant: Types.Participant, parameter: string, operator: string): Types.RoleName | number
    if tonumber(parameter) then
        return tonumber(parameter) :: number
    elseif parameter:sub(1, 1) == `"` and parameter:sub(-1) == `"` then
        return getRoleEq(participant.Round:GetRoleFromName(parameter:sub(2, -2)), operator)
    elseif parameter:sub(1, 2) == "__" then
        if parameter == "__This" then
            return getRoleEq(participant.Role, operator)
        end
    else
        return getCounter(participant, parameter)
    end
    error("Invalid parameter")
end

local operations = {">", ">=", "<", "<=", "==", "?="}
function module.InterpretConditional(participant: Types.Participant, conditional: string): boolean
    local split = conditional:split(" ")

    local pass = true
    for i, v in split do
        if table.find(operations, v) then
            local lhs = split[i - 1]
            local rhs = split[i + 1]
            assert(lhs and rhs, "Invalid syntax")

            local lhsValue = getConditionalParameterValue(participant, lhs, v)
            local rhsValue = getConditionalParameterValue(participant, rhs, v)

            -- It is tempting to use loadstring() here, but remember why this module exists in the first place (to prevent arbitrary code execution)
            -- And also ?= would mess it up anyway
            if v == ">" then
                pass = lhsValue > rhsValue
            elseif v == ">=" then
                pass = lhsValue >= rhsValue
            elseif v == "<" then
                pass = lhsValue < rhsValue
            elseif v == "<=" then
                pass = lhsValue <= rhsValue
            elseif v == "==" or v == "?=" then
                pass = lhsValue == rhsValue
            end
        end
    end

    return pass
end

function module.Execute(actionItem: Model, participant: Types.Participant): ()
    if not participant then
        error("Participant must be set")
    end
    if actionItem:GetAttribute("Disabled") then
        return
    end
	local attributes = actionItem:GetAttributes() :: {[string]: string | number | CFrame}

	local actions: {[string]: string} = {}
	local actionParameters: {[string]: {string | number | CFrame}?} = {}
	local actionOrder: {string} = {}

	local conditions: {[string]: string} = {}
	for i, v in attributes do
		local split = i:split("_")
		if split[2] and split[2]:sub(1, 9) == "Parameter" then
			local action = actionParameters[split[1]]
			if not action then
				action = {}
				actionParameters[split[1]] = action
			end
			assert(action)

			local index = tonumber(split[2]:sub(10, -1))
			assert(index, `Expected number after parameter name ({i})`)

			table.insert(action, index, v)
		elseif split[2] and split[2]:sub(1, 9) == "Condition" then
			assert(typeof(v) == "string", `Condition {i} must be a string`)
			conditions[split[1]] = v
		elseif i:sub(1, 6) == "Action" and tonumber(i:sub(7, -1)) then
			if not module.Actions[v] or typeof(v) ~= "string" then
				error(`Expected ActionName for {i}`)
			end

			actions[i] = v
			table.insert(actionOrder, i)
		end
	end
	
	for i in conditions do
		if not table.find(actionOrder, i) then
			warn(`No Action is associated with condition for {i}`)
		end
	end
	
	for i in actionParameters do
        if not table.find(actionOrder, i) then
            warn(`No Action is associated with {i}`)
        end
	end

	table.sort(actionOrder, function(a, b)
		return tonumber(a:sub(7, -1)) < tonumber(b:sub(7, -1))
	end)
	
	for _, v in actionOrder do
        if conditions[v] and not module.InterpretConditional(participant, conditions[v]) then
            break
        end
		module.Actions[actions[v]](actionItem, participant, table.unpack(actionParameters[v] or {}))
	end
end

return module