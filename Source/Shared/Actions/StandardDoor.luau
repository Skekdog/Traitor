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
        assert(request.Kind == "ServerReceive", "Expected ServerReceive")
    else
        assert(request.Kind == "ClientInteraction" or request.Kind == "ClientReceive", "Expected ClientInteraction or ClientReceive")
    end

    local door = request.Door
    if door:GetAttribute("Opening") then
        return
    end

    local open = if request.Kind == "ClientInteraction" then not door:GetAttribute("Open") :: boolean? else request.Open
    door:SetAttribute("Open", open)

    local initialCFrame = if request.Kind == "ClientReceive" then request.OriginalCFrame else door.CFrame

    local pivot = CFrame.new(door.Size.X / -2, 0, 0)
    local angleMult = 1

    do
        local pivotObject = door:FindFirstChild("DoorPivot")
        if pivotObject and pivotObject:IsA("Attachment") then
            pivot = pivotObject.WorldCFrame

            local lookVector = pivotObject:GetAttribute("LookVector")
            if typeof(lookVector) ~= "Vector3" then
                lookVector = initialCFrame.LookVector
                pivotObject:SetAttribute("LookVector", lookVector)
            end

            assert(typeof(lookVector) == "Vector3")

            angleMult = if lookVector:Dot(Vector3.one.Unit) > 0 then -1 else 1
        end
    end

    local targetAngle = (if open then 90 else -90) * angleMult
    local rotation = CFrame.Angles(0, math.rad(targetAngle), 0)
    local targetCFrame = pivot * rotation * pivot:Inverse() * initialCFrame

    if not IS_SERVER then
        local sounds = {}
        for _, v in door:GetChildren() do
            if v:IsA("Sound") and v.Name == if open then "OpenSound" else "CloseSound" then
                table.insert(sounds, v)
            end
        end
        sounds[math.random(1, #sounds)]:Play()
    end

    task.delay(1, door.SetAttribute, door, "Opening", false)

    if request.Kind == "ServerReceive" then
        

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
    local targetAngle = if request.Kind == "ClientReceive" then request.TargetAngle else if open then 90 else 0

    remotes.ClientServer.OpenDoor:FireServer(door, open)

    TweenService:Create(angle, TweenInfo.new(1, Enum.EasingStyle.Linear), {Value = targetAngle}):Play()
    RunService.PreSimulation:Connect(function()
        door.CFrame = hingeCFrame * CFrame.Angles(0, math.rad(angle.Value), 0) * offset
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