local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local remotes = ReplicatedStorage.Remotes

local IS_SERVER = RunService:IsServer()

type BaseDoorRequest = {
    Door: Types.MapObject,
}

export type Direction = "In" | "Out"?

export type ClientInteraction = BaseDoorRequest & {
    Kind: "ClientInteraction",
}

export type ServerReceive = BaseDoorRequest & {
    Kind: "ServerReceive",
    Direction: Direction,
    Player: Player,
}

export type ClientReceive = BaseDoorRequest & {
    Kind: "ClientReceive",
    TargetAngle: number,
    OriginalCFrame: CFrame,
}

export type ServerRun = BaseDoorRequest & {
    Kind: "ServerRun",
    Direction: Direction,
}

export type DoorRequest = ClientInteraction | ServerReceive | ClientReceive | ServerRun

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
        if request.Kind ~= "ServerReceive" and request.Kind ~= "ServerRun" then
            return
        end
    else
        assert(request.Kind == "ClientInteraction" or request.Kind == "ClientReceive", "Expected ClientInteraction or ClientReceive")
    end

    local door = request.Door
    if request.Kind ~= "ClientReceive" and door:GetAttribute("Opening") then
        return
    end

    if door:GetAttribute("Locked") then
        if request.Kind ~= "ClientReceive" then
            if IS_SERVER then
                return
            end

            if tick() - (door:GetAttribute("LastPlayedLockedSound") :: number? or 0) < 1 then
                return
            end
            PlaySound(134969396, nil, door)
            door:SetAttribute("LastPlayedLockedSound", tick())
            return
        end
    end

    local shouldOpen = if request.Kind == "ClientInteraction" then not door:GetAttribute("Open") :: boolean? elseif request.Kind == "ClientReceive" then request.TargetAngle ~= 0 else request.Direction ~= nil
    door:SetAttribute("Open", shouldOpen)

    local part = GetPrimaryPart(door)
    local originalDoorCFrame = part.CFrame

    do
        local attribute = door:GetAttribute("OriginalCFrame") or door:GetAttribute("ClientOriginalCFrame")
        if typeof(attribute) == "CFrame" then
            originalDoorCFrame = attribute
        elseif IS_SERVER then
            door:SetAttribute("OriginalCFrame", originalDoorCFrame)
        else
            door:SetAttribute("ClientOriginalCFrame", originalDoorCFrame)
        end
    end

    local pivotAttachment = part:FindFirstChild("DoorPivot")
    assert(pivotAttachment and pivotAttachment:IsA("Attachment"), "DoorPivot must be an Attachment")

    if not IS_SERVER then
        local sounds = {}
        local soundsFolder = door:FindFirstChild("Sounds")
        if soundsFolder then
            local soundFolder = soundsFolder:FindFirstChild(if shouldOpen then "Open" else "Close")
            if soundFolder then
                for _, v in soundFolder:GetChildren() do
                    if v:IsA("Sound") then
                        table.insert(sounds, v)
                    end
                end
            end
        end
        if #sounds == 0 then
            sounds = {PlaySound.MakeSound(if shouldOpen then 316089029 else 316089019, {
                RollOffMinDistance = 6,
                RollOffMaxDistance = 18,
            })}
        end
        PlaySound(sounds, nil, door)
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

    local direction: Direction
    if request.Kind ~= "ClientReceive" and shouldOpen then
        direction = if request.Kind == "ClientInteraction" then
            if pivotAttachment.WorldCFrame.LookVector:Dot(workspace.CurrentCamera.CFrame.LookVector) < 0 then "Out" else "In"
            else request.Direction

        if direction == "Out" then
            targetAngle = -targetAngle
        end
    end

    if request.Kind == "ServerReceive" or request.Kind == "ServerRun" then
        local rotation = CFrame.fromAxisAngle(pivotAttachment.SecondaryAxis, targetAngle)
        local targetCFrame = originalDoorCFrame:ToWorldSpace(hingePosition * rotation * hingePosition:Inverse())

        local clientReceive: ClientReceive = {
            Kind = "ClientReceive" :: "ClientReceive",
            Door = door,
            Open = shouldOpen,
            TargetAngle = targetAngle,
            OriginalCFrame = part.CFrame,
        }

        part.CFrame = targetCFrame

        if request.Kind == "ServerReceive" then
            for _, v in Players:GetPlayers() do
                if v ~= request.Player then
                    remotes.ClientServer.OpenDoor:FireClient(v, clientReceive)
                end
            end
        else
            remotes.ClientServer.OpenDoor:FireAllClients(clientReceive)
        end

        return
    end

    local angle = findOrCreateAngleValue(part)

    if request.Kind == "ClientInteraction" then
        remotes.ClientServer.OpenDoor:FireServer(door, direction)
    else
        part.CFrame = request.OriginalCFrame
    end

    local tween = TweenService:Create(angle, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Value = targetAngle})
    tween:Play()

    local con: RBXScriptConnection
    con = RunService.PreSimulation:Connect(function()
        local rotation = CFrame.fromAxisAngle(pivotAttachment.SecondaryAxis, angle.Value)
        part.CFrame = originalDoorCFrame:ToWorldSpace(hingePosition * rotation * hingePosition:Inverse())

        if tween.PlaybackState == Enum.PlaybackState.Completed then
            con:Disconnect()
        end
    end)
end

if IS_SERVER then
    remotes.ClientServer.OpenDoor.OnServerEvent:Connect(function(plr: Player, door: unknown, direction: unknown): ()
        if typeof(door) ~= "Instance" or (not door:IsA("BasePart") and not door:IsA("Model")) then
            return
        end
        local MapObject = door :: Types.MapObject

        if typeof(direction) ~= "nil" and direction ~= "In" and direction ~= "Out" then
            return
        end

        if not door:HasTag("Door") then
            return
        end

        local doorPart = GetPrimaryPart(MapObject)

        local distance = plr:DistanceFromCharacter(doorPart.Position)
        if distance == 0 or distance > 15 then
            return
        end

        local request: ServerReceive = {
            Kind = "ServerReceive" :: "ServerReceive",
            Player = plr,
            Door = MapObject,
            Direction = direction,
        }
        StandardDoor(request)
    end)
end

if not IS_SERVER then
    remotes.ClientServer.OpenDoor.OnClientEvent:Connect(StandardDoor)
end

return StandardDoor