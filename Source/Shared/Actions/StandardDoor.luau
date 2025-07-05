local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local remotes = ReplicatedStorage.Remotes

local IS_SERVER = RunService:IsServer()

type BaseDoorRequest = {
    Door: BasePart,
}

export type ClientInteraction = BaseDoorRequest & {
    Kind: "ClientInteraction",
}

type BaseReceive = BaseDoorRequest & {
    Open: boolean,
}

export type ServerReceive = BaseReceive & {
    Kind: "ServerReceive",
    Player: Player,
}

export type ClientReceive = BaseReceive & {
    Kind: "ClientReceive",
    TargetAngle: number,
    OriginalCFrame: CFrame,
}

export type DoorRequest = ClientInteraction | ServerReceive | ClientReceive

local function findOrCreateAngleValue(door: BasePart): NumberValue
    local angle = door:FindFirstChild("DoorAngle")
    if not angle then
        local newAngle = Instance.new("NumberValue")
        newAngle.Name = "DoorAngle"
        newAngle.Parent = door
        angle = newAngle
    end
    assert(angle and angle:IsA("NumberValue"), "DoorAngle must be a NumberValue")
    return angle
end

local function StandardDoor(request: DoorRequest): ()
    if IS_SERVER then
        if false then -- don't throw on the server, but keep the assert to keep the type checker happy
            assert(request.Kind == "ServerReceive", "Expected ServerReceive")
        end
    else
        assert(request.Kind == "ClientInteraction" or request.Kind == "ClientReceive", "Expected ClientInteraction or ClientReceive")
    end

    local door = request.Door
    if door:GetAttribute("Opening") then
        return
    end

    local open = if request.Kind == "ClientInteraction" then not door:GetAttribute("Open") :: boolean? else request.Open
    door:SetAttribute("Open", open)

    local originalCFrame: CFrame
    do
        local value = door:GetAttribute("OriginalCFrame")
        if typeof(value) == "CFrame" then
            originalCFrame = value
        else
            originalCFrame = door.CFrame
            door:SetAttribute("OriginalCFrame", originalCFrame)
        end
    end

    local initialCFrame = if request.Kind == "ClientReceive" then request.OriginalCFrame else door.CFrame

    local pivotObject: Attachment

    do
        local foundPivotObject = door:FindFirstChild("DoorPivot")
        if foundPivotObject and foundPivotObject:IsA("Attachment") then
            pivotObject = foundPivotObject
        else
            local newPivotObject = Instance.new("Attachment")

            newPivotObject.CFrame = CFrame.new(door.Size.X / -2, 0, 0)
            newPivotObject.Axis = Vector3.new(1, 0, 0)
            newPivotObject.SecondaryAxis = Vector3.new(0, 1, 0)

            newPivotObject.Name = "DoorPivot"
            newPivotObject.Parent = door

            pivotObject = newPivotObject
        end
    end

    if not IS_SERVER then
        local sounds = {}
        for _, v in door:GetChildren() do
            if v:IsA("Sound") and v.Name == if open then "OpenSound" else "CloseSound" then
                table.insert(sounds, v)
            end
        end
        sounds[math.random(1, #sounds)]:Play()
    end

    local duration = 0.75

    if open then
        local configOpenDuration = door:GetAttribute("Opening_Duration")
        if typeof(configOpenDuration) == "number" then
            duration = configOpenDuration
        end
    else
        local configCloseDuration = door:GetAttribute("Closing_Duration")
        if typeof(configCloseDuration) == "number" then
            duration = configCloseDuration
        end
    end

    task.delay(duration, door.SetAttribute, door, "Opening", false)

    local targetAngle = math.rad(if open then 90 else -90)

    if request.Kind == "ServerReceive" then
        local rotation = CFrame.Angles(0, targetAngle, 0) -- initialCFrame:ToWorldSpace(CFrame.fromAxisAngle(axis, targetAngle)).Rotation
        local targetCFrame = pivotObject.WorldCFrame * rotation * pivotObject.CFrame:Inverse()

        door.CFrame = targetCFrame

        local clientReceive: ClientReceive = {
            Kind = "ClientReceive" :: "ClientReceive",
            Door = door,
            Open = open,
            TargetAngle = if open then 90 else 0,
            OriginalCFrame = initialCFrame,
        }

        for _, v in Players:GetPlayers() do
            if v ~= request.Player then
                remotes.ClientServer.OpenDoor:FireClient(v, clientReceive)
            end
        end

        door:SetAttribute("Opening", true)

        return
    else
        return remotes.ClientServer.OpenDoor:FireServer(door, open)
    end

    door:SetAttribute("Opening", true)

    local angle = findOrCreateAngleValue(door)

    if request.Kind == "ClientInteraction" then
        remotes.ClientServer.OpenDoor:FireServer(door, open)
    end

    TweenService:Create(angle, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Value = math.deg(targetAngle)}):Play()
    RunService.PreSimulation:Connect(function()
        door.CFrame = pivotObject.WorldCFrame * CFrame.Angles(0, math.rad(angle.Value), 0) * pivotObject.CFrame:Inverse()
    end)
end

if IS_SERVER then
    remotes.ClientServer.OpenDoor.OnServerEvent:Connect(function(plr: Player, door: unknown, open: unknown): ()
        if typeof(door) ~= "Instance" or not door:IsA("BasePart") then
            return
        end

        if typeof(open) ~= "boolean" then
            return
        end

        local ServerScriptService = game:GetService("ServerScriptService")
        local RoundHandler = require(ServerScriptService.RoundHandler)
        if not door.Parent or door.Parent.Name ~= "Doors" or not door:IsDescendantOf(RoundHandler.GetRound():GetMap().DynamicMap) then
            return
        end

        local distance = plr:DistanceFromCharacter(door.Position)
        if distance == 0 or distance > 15 then
            return
        end

        local request: ServerReceive = {
            Kind = "ServerReceive" :: "ServerReceive",
            Player = plr,
            Door = door,
            Open = open,
        }
        StandardDoor(request)
    end)
end

if not IS_SERVER then
    remotes.ClientServer.OpenDoor.OnClientEvent:Connect(StandardDoor)
end

return StandardDoor