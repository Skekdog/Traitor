local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local PlaySound = require(ReplicatedStorage.API.PlaySound)
local Types = require(ReplicatedStorage.API.Types)

local remotes = ReplicatedStorage.Remotes

local IS_SERVER = RunService:IsServer()

local DEFAULT_HINGE_OPEN_SOUND = 316089029
local DEFAULT_HINGE_CLOSE_SOUND = 316089019

local DEFAULT_SLIDE_OPEN_SOUND = 927222098
local DEFAULT_SLIDE_CLOSE_SOUND = 927222098

export type HingeDoorServerReceive = {
    Kind: "HingeDoorServerReceive",
    Direction: Direction,
}

export type HingeDoorClientReceive = {
    Kind: "HingeDoorClientReceive",
    TargetAngle: number,
}

export type SlideDoorServerReceive = {
    Kind: "SlideDoorServerReceive",
    Open: boolean,
}

export type SlideDoorClientReceive = {
    Kind: "SlideDoorClientReceive",
    Open: boolean,
}

type BaseDoorRequest = {
    Door: Types.MapObject,
}

export type Direction = "Clockwise" | "CounterClockwise"?

export type ClientInteraction = BaseDoorRequest & {
    Kind: "ClientInteraction",
}

export type ServerReceive<ServerReceiveType = HingeDoorServerReceive | SlideDoorServerReceive> = BaseDoorRequest & {
    Kind: "ServerReceive",
    Receive: ServerReceiveType,
    Player: Player,
}

export type ClientReceive<ClientReceiveType = HingeDoorClientReceive | SlideDoorClientReceive> = BaseDoorRequest & {
    Kind: "ClientReceive",
    Receive: ClientReceiveType,
    OriginalCFrame: CFrame,
}

export type ServerRun<ServerReceiveType = HingeDoorServerReceive | SlideDoorServerReceive> = BaseDoorRequest & {
    Kind: "ServerRun",
    Receive: ServerReceiveType,
    Force: boolean?,
}

export type DoorRequest<ReceiveType = HingeDoorClientReceive | HingeDoorServerReceive | SlideDoorClientReceive | SlideDoorServerReceive> = ClientInteraction | ServerReceive<ReceiveType> | ClientReceive<ReceiveType> | ServerRun<ReceiveType>

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

local function sendToClients(request: DoorRequest<HingeDoorServerReceive | SlideDoorServerReceive>, receive: ClientReceive): ()
    if request.Kind == "ServerReceive" then
        for _, v in Players:GetPlayers() do
            if v ~= request.Player then
                remotes.ClientServer.OpenDoor:FireClient(v, receive)
            end
        end
    else
        remotes.ClientServer.OpenDoor:FireAllClients(receive)
    end
end

local function getTweenInfo(door: Types.MapObject, duration: number): TweenInfo
    local easingStyleName = door:GetAttribute("EasingStyle")
    if typeof(easingStyleName) ~= "string" then
        easingStyleName = "Linear"
    end
    assert(typeof(easingStyleName) == "string")
    local easingStyle = Enum.EasingStyle:FromName(easingStyleName)

    local easingDirectionName = door:GetAttribute("EasingDirection")
    if typeof(easingDirectionName) ~= "string" then
        easingDirectionName = "In"
    end
    assert(typeof(easingDirectionName) == "string")
    local easingDirection = Enum.EasingDirection:FromName(easingDirectionName)

    return TweenInfo.new(duration, easingStyle, easingDirection)
end

local function hingeDoor(request: DoorRequest<HingeDoorClientReceive | HingeDoorServerReceive>, part: BasePart, originalDoorCFrame: CFrame, shouldOpen: boolean, duration: number): ()
    local door = request.Door

    local pivotAttachment = part:FindFirstChild("DoorPivot")
    assert(pivotAttachment and pivotAttachment:IsA("Attachment"), "Hinge doors must have a DoorPivot Attachment")

    local hingePosition = CFrame.new(pivotAttachment.Position)

    local targetAngle: number
    if request.Kind == "ClientReceive" then
        assert(request.Receive.Kind == "HingeDoorClientReceive")
        targetAngle = request.Receive.TargetAngle
    else
        targetAngle = if shouldOpen then math.rad(90) else 0
    end

    local direction: Direction
    if request.Kind ~= "ClientReceive" then
        if shouldOpen then
            if door:GetAttribute("HingeRestrictDirection") then
                direction = "CounterClockwise"
            elseif door:GetAttribute("HingeRestrictDirectionClockwise") then
                direction = "Clockwise"
            else
                if request.Kind == "ClientInteraction" then
                    local referenceCFrame = door:GetAttribute("ReferenceCFrame")
                    if typeof(referenceCFrame) ~= "CFrame" then
                        referenceCFrame = part.CFrame
                        door:SetAttribute("ReferenceCFrame", part.CFrame)
                    end

                    assert(typeof(referenceCFrame) == "CFrame", "ReferenceCFrame must be a CFrame")
                    direction = if referenceCFrame:ToWorldSpace(pivotAttachment.CFrame).LookVector:Dot(workspace.CurrentCamera.CFrame.LookVector) < 0 then "Clockwise" else "CounterClockwise"
                else
                    assert(request.Receive.Kind == "HingeDoorServerReceive")
                    direction = request.Receive.Direction
                end
            end
        end

        if direction == "Clockwise" then
            local angle = door:GetAttribute("HingeOpenAngleCW")
            if typeof(angle) == "number" then
                targetAngle = math.rad(angle)
            end
        elseif direction == "CounterClockwise" then
            local angle = door:GetAttribute("HingeOpenAngleCCW")
            if typeof(angle) == "number" then
                targetAngle = math.rad(angle)
            else
                targetAngle = -targetAngle
            end
        end

        targetAngle *= -1
    end

    if request.Kind == "ServerReceive" or request.Kind == "ServerRun" then
        local rotation = CFrame.fromAxisAngle(pivotAttachment.SecondaryAxis, targetAngle)
        local targetCFrame = originalDoorCFrame:ToWorldSpace(hingePosition * rotation * hingePosition:Inverse())

        local clientReceive: ClientReceive<HingeDoorClientReceive> = {
            Kind = "ClientReceive" :: "ClientReceive",
            Door = door,
            OriginalCFrame = part.CFrame,
            Receive = {
                Kind = "HingeDoorClientReceive" :: "HingeDoorClientReceive",
                TargetAngle = targetAngle,
            },
        }

        part.CFrame = targetCFrame

        sendToClients(request :: any, clientReceive)

        return
    end

    do
        local finalRotation = CFrame.fromAxisAngle(pivotAttachment.SecondaryAxis, targetAngle)
        door:SetAttribute("ReferenceCFrame", originalDoorCFrame:ToWorldSpace(hingePosition) * finalRotation * hingePosition:Inverse())
    end

    local angle = findOrCreateAngleValue(part)

    if request.Kind == "ClientInteraction" then
        remotes.ClientServer.OpenDoor:FireServer(door, direction)
    else
        part.CFrame = request.OriginalCFrame
    end

    local tween = TweenService:Create(angle, getTweenInfo(door, duration), {Value = targetAngle})
    tween:Play()

    local con: RBXScriptConnection
    con = RunService.PreRender:Connect(function()
        local rotation = CFrame.fromAxisAngle(pivotAttachment.SecondaryAxis, angle.Value)
        part.CFrame = originalDoorCFrame:ToWorldSpace(hingePosition * rotation * hingePosition:Inverse())

        if tween.PlaybackState == Enum.PlaybackState.Completed then
            con:Disconnect()
        end
    end)
end

local function slideDoor(request: DoorRequest<SlideDoorClientReceive | SlideDoorServerReceive>, part: BasePart, originalDoorCFrame: CFrame, shouldOpen: boolean, duration: number): ()
    local door = request.Door

    door:SetAttribute("NoInteract", true)

    local axis = door:GetAttribute("SlideAxis")
    if typeof(axis) ~= "Vector3" then
        axis = Vector3.zAxis
    end
    assert(typeof(axis) == "Vector3")

    local targetCFrame = if shouldOpen then originalDoorCFrame:ToWorldSpace(CFrame.new(axis * part.Size * 0.9)) else originalDoorCFrame

    if request.Kind == "ServerReceive" or request.Kind == "ServerRun" then
        local clientReceive: ClientReceive<SlideDoorClientReceive> = {
            Kind = "ClientReceive" :: "ClientReceive",
            Door = door,
            OriginalCFrame = part.CFrame,
            Receive = {
                Kind = "SlideDoorClientReceive" :: "SlideDoorClientReceive",
                Open = shouldOpen,
            },
        }

        local id = door:GetAttribute("Id")
        task.delay(duration, function()
            if id ~= door:GetAttribute("Id") then
                return
            end
            door:SetAttribute("NoInteract", false)
        end)

        part.CFrame = targetCFrame

        return sendToClients(request :: any, clientReceive)
    end

    if request.Kind == "ClientInteraction" then
        remotes.ClientServer.OpenDoor:FireServer(door, if shouldOpen then "Clockwise" else "CounterClockwise")
    else
        part.CFrame = request.OriginalCFrame
    end

    local tween = TweenService:Create(part, getTweenInfo(door, duration), {CFrame = targetCFrame})
    tween:Play()

    local id = door:GetAttribute("Id")
    tween.Completed:Once(function(status)
        if status == Enum.PlaybackState.Completed and id == door:GetAttribute("Id") then
            door:SetAttribute("NoInteract", false)
        end
    end)
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

    if door:GetAttribute("NoInteract") then
        if request.Kind ~= "ClientReceive" and (request.Kind ~= "ServerRun" or not request.Force) then
            return
        end
    end

    if request.Kind == "ServerReceive" then
        if request.Receive.Kind == "HingeDoorServerReceive" then
            if request.Receive.Direction == nil and not door:GetAttribute("Open") then
                return
            elseif request.Receive.Direction ~= nil and door:GetAttribute("Open") then
                return
            end
        elseif request.Receive.Kind == "SlideDoorServerReceive" then
            if request.Receive.Open == door:GetAttribute("Open") then
                return
            elseif not request.Receive.Open and door:GetAttribute("Open") == nil then
                return
            end
        end
    end

    if door:GetAttribute("Locked") then
        if request.Kind ~= "ClientReceive" and (request.Kind ~= "ServerRun" or not request.Force) then
            if IS_SERVER then
                return
            end

            if os.clock() - (door:GetAttribute("LastPlayedLockedSound") :: number? or 0) < 1 then
                return
            end
            PlaySound(134969396, nil, door)
            door:SetAttribute("LastPlayedLockedSound", os.clock())
            return
        end
    end

    local shouldOpen: boolean
    if request.Kind == "ClientInteraction" then
        shouldOpen = not door:GetAttribute("Open")
    elseif request.Receive.Kind == "SlideDoorServerReceive" or request.Receive.Kind == "SlideDoorClientReceive" then
        shouldOpen = request.Receive.Open
    elseif request.Receive.Kind == "HingeDoorClientReceive" then
        shouldOpen = request.Receive.TargetAngle ~= 0
    else
        shouldOpen = request.Receive.Direction ~= nil
    end

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
            local id = if shouldOpen then if door:GetAttribute("DoorKind") == "Slide" then DEFAULT_SLIDE_OPEN_SOUND else DEFAULT_HINGE_OPEN_SOUND else if door:GetAttribute("DoorKind") == "Slide" then DEFAULT_SLIDE_CLOSE_SOUND else DEFAULT_HINGE_CLOSE_SOUND
            sounds = {PlaySound.MakeSound(id, {
                RollOffMinDistance = 6,
                RollOffMaxDistance = 18,
            })}
        end
        PlaySound(sounds, nil, GetPrimaryPart(door))
    end

    local duration = 0.75

    local durationAttribute = door:GetAttribute("Duration")
    if typeof(durationAttribute) == "number" then
        duration = durationAttribute
    end

    if shouldOpen then
        local configOpenDuration = door:GetAttribute("OpeningDuration")
        if typeof(configOpenDuration) == "number" then
            duration = configOpenDuration
        end
    else
        local configCloseDuration = door:GetAttribute("ClosingDuration")
        if typeof(configCloseDuration) == "number" then
            duration = configCloseDuration
        end
    end

    if IS_SERVER then
        local id = tostring(newproxy())
        door:SetAttribute("Id", id)

        if shouldOpen then
            local autoCloseAfter = door:GetAttribute("AutoCloseAfter")
            if typeof(autoCloseAfter) == "number" then
                task.delay(autoCloseAfter + duration, function()
                    if id ~= door:GetAttribute("Id") then
                        return
                    end

                    assert(request.Kind == "ServerReceive" or request.Kind == "ServerRun")

                    local closeRequest: ServerRun = {
                        Kind = "ServerRun" :: "ServerRun",
                        Door = door,
                        Receive = if request.Receive.Kind == "SlideDoorServerReceive" then {
                            Kind = "SlideDoorServerReceive" :: "SlideDoorServerReceive",
                            Open = false,
                        } elseif request.Receive.Kind == "HingeDoorServerReceive" then {
                            Kind = "HingeDoorServerReceive" :: "HingeDoorServerReceive",
                            Direction = nil,
                        } else error("Invalid request"),
                    }
                    StandardDoor(closeRequest)
                end)
            end
        end
    end

    if door:GetAttribute("DoorKind") == "Slide" then
        slideDoor(request :: DoorRequest<SlideDoorClientReceive | SlideDoorServerReceive>, part, originalDoorCFrame, shouldOpen, duration)
    else
        hingeDoor(request :: DoorRequest<HingeDoorClientReceive | HingeDoorServerReceive>, part, originalDoorCFrame, shouldOpen, duration)
    end
end

if IS_SERVER then
    remotes.ClientServer.OpenDoor.OnServerEvent:Connect(function(plr: Player, door: unknown, direction: unknown): ()
        if typeof(door) ~= "Instance" or (not door:IsA("BasePart") and not door:IsA("Model")) then
            return
        end
        local MapObject = door :: Types.MapObject

        if typeof(direction) ~= "nil" and direction ~= "Clockwise" and direction ~= "CounterClockwise" then
            return
        end

        if not door:HasTag("Door") then
            return
        end

        local doorPart: BasePart
        local success = pcall(function() -- TODO: REMOVE THIS LOGGING
            doorPart = GetPrimaryPart(MapObject)
        end)

        if not success then
            error("No primary part found for door: " .. door:GetFullName())
        end

        local distance = plr:DistanceFromCharacter(doorPart.Position)
        if distance == 0 or distance > 15 then
            return
        end

        local receive: HingeDoorServerReceive | SlideDoorServerReceive
        if door:GetAttribute("DoorKind") == "Slide" then
            receive = {
                Kind = "SlideDoorServerReceive" :: "SlideDoorServerReceive",
                Open = direction == "Clockwise",
            }
        else
            receive = {
                Kind = "HingeDoorServerReceive" :: "HingeDoorServerReceive",
                Direction = direction,
            }
        end

        local request: ServerReceive = {
            Kind = "ServerReceive" :: "ServerReceive",
            Player = plr,
            Door = MapObject,
            Receive = receive,
        }
        StandardDoor(request)
    end)
end

if not IS_SERVER then
    remotes.ClientServer.OpenDoor.OnClientEvent:Connect(StandardDoor)
end

return StandardDoor