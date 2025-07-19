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
        if request.Kind ~= "ServerReceive" then
            return
        end
    else
        assert(request.Kind == "ClientInteraction" or request.Kind == "ClientReceive", "Expected ClientInteraction or ClientReceive")
    end

    local door = request.Door
    if request.Kind ~= "ClientReceive" and door:GetAttribute("Opening") then
        return
    end

    local shouldOpen = if request.Kind == "ClientInteraction" then not door:GetAttribute("Open") :: boolean? else request.Open
    door:SetAttribute("Open", shouldOpen)

    local originalDoorCFrame = door.CFrame

    do
        local attribute = door:GetAttribute("OriginalCFrame")
        if typeof(attribute) == "CFrame" then
            originalDoorCFrame = attribute
        elseif IS_SERVER then
            door:SetAttribute("OriginalCFrame", originalDoorCFrame)
        end
    end

    local pivotAttachment = door:FindFirstChild("DoorPivot")
    assert(pivotAttachment and pivotAttachment:IsA("Attachment"), "DoorPivot must be an Attachment")

    if not IS_SERVER then
        local sounds = {}
        for _, v in door:GetChildren() do
            if v:IsA("Sound") and v.Name == if shouldOpen then "OpenSound" else "CloseSound" then
                table.insert(sounds, v)
            end
        end
        sounds[math.random(1, #sounds)]:Play()
    end

    local duration = 0.75

    if shouldOpen then
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

    door:SetAttribute("Opening", true)
    task.delay(duration, door.SetAttribute, door, "Opening", false)

    local hingePosition = CFrame.new(pivotAttachment.Position)

    local targetAngle = if request.Kind == "ClientReceive" then request.TargetAngle else if shouldOpen then math.rad(90) else 0

    if request.Kind ~= "ClientReceive" then
        local axis = pivotAttachment.WorldAxis
        local axisScale = axis.X + axis.Y + axis.Z
        if axisScale >= 0 then
            targetAngle *= -1
        end
    end

    if request.Kind == "ServerReceive" then
        local rotation = CFrame.fromAxisAngle(pivotAttachment.SecondaryAxis, targetAngle)
        local targetCFrame = originalDoorCFrame:ToWorldSpace(hingePosition * rotation * hingePosition:Inverse())

        local clientReceive: ClientReceive = {
            Kind = "ClientReceive" :: "ClientReceive",
            Door = door,
            Open = shouldOpen,
            TargetAngle = targetAngle,
            OriginalCFrame = door.CFrame,
        }

        door.CFrame = targetCFrame

        for _, v in Players:GetPlayers() do
            if v ~= request.Player then
                remotes.ClientServer.OpenDoor:FireClient(v, clientReceive)
            end
        end

        return
    end

    local angle = findOrCreateAngleValue(door)

    if request.Kind == "ClientInteraction" then
        remotes.ClientServer.OpenDoor:FireServer(door, shouldOpen)
    else
        door.CFrame = request.OriginalCFrame
    end

    local tween = TweenService:Create(angle, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Value = targetAngle})
    tween:Play()

    local con: RBXScriptConnection
    con = RunService.PreSimulation:Connect(function()
        local rotation = CFrame.fromAxisAngle(pivotAttachment.SecondaryAxis, angle.Value)
        door.CFrame = originalDoorCFrame:ToWorldSpace(hingePosition * rotation * hingePosition:Inverse())

        if tween.PlaybackState == Enum.PlaybackState.Completed then
            con:Disconnect()
        end
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