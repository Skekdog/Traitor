local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetTaggedDescendants = require(ReplicatedStorage.Shared.RoundRule.Common.GetTaggedDescendants)
local GetInteractableDefinition = require(script.Parent.GetInteractableDefinition)
local Map = require(ReplicatedStorage.Shared.RoundRule.Map)
local Prop = require(ReplicatedStorage.Shared.RoundRule.Prop)
local Types = require(ReplicatedStorage.API.Types)
local DynamicValue = require(ReplicatedStorage.Shared.Util.DynamicValue)
local InstanceSignal = require(ReplicatedStorage.Shared.Util.InstanceSignal)
local module = {}

local replicatedData = ReplicatedStorage.Shared.RoundRule.ReplicatedData
local remotes = ReplicatedStorage.Shared.RoundRule.Remotes

type Event = {
    Timestamp: number,
    Description: string,
    WasFreeKill: boolean?,
    WasSelfDefense: boolean?,
    WasCorrectKill: boolean?,
}

module.Map = DynamicValue.new(nil :: Types.Map?)

module.Gamemode = DynamicValue.new(nil :: Types.GamemodeDefinition?)
InstanceSignal.ListenAttribute<<string?>>(replicatedData, "Gamemode"):Connect(function(name)
    if not name then
        module.Gamemode:SetValue()
        return
    end

    local isSucky = false

    local object = ReplicatedStorage.Shared.GameDefinition.Gamemodes:FindFirstChild(name)
    if not object then
        local map = module.Map()
        if map and map.Structure:FindFirstChild("Bosses") then
            object = (map.Structure.Bosses :: Instance):FindFirstChild(name)
            isSucky = true
        end
    end

    if object then
        local ret = (require)(object)
        if isSucky then
            module.Gamemode:SetValue(ret.Gamemode)
        else
            module.Gamemode:SetValue(ret)
        end
    else
        module.Gamemode:SetValue()
    end
end, true)

module.Credits = DynamicValue.new(0)
remotes.UpdateCredits.OnClientEvent:Connect(function(value: number?)
    module.Credits:SetValue(value or 0)
end)

module.FreeKill = DynamicValue.new(nil :: string?)
remotes.FreeKill.OnClientEvent:Connect(function(reason: string?)
    module.FreeKill:SetValue(reason)
end)

function module.GetHighlights(): {Types.Highlight}
    local highlights: {Types.Highlight} = {}
    for _, v in replicatedData.Highlights:GetChildren() do
        if v:IsA("StringValue") then
            table.insert(highlights, {
                Title = v.Name,
                Description = v.Value,
                Priority = v:GetAttribute("Priority") :: number,
                Group = v:GetAttribute("Group") :: string,
            })
        end
    end

    return highlights
end

function module.GetOrderedRoundEvents(): {Event}
    local events: {Event} = {}
    for _, v in replicatedData.Events:GetChildren() do
        if v:IsA("StringValue") then
            table.insert(events, {
                Timestamp = tonumber(v.Name) or error("Invalid timestamp"),
                Description = v.Value,
                WasFreeKill = v:GetAttribute("WasFreeKill") :: boolean?,
                WasSelfDefense = v:GetAttribute("WasSelfDefense") :: boolean?,
                WasCorrectKill = v:GetAttribute("WasCorrectKill") :: boolean?,
            })
        end
    end

    table.sort(events, function(a, b)
        return a.Timestamp < b.Timestamp
    end)

    return events
end

module.Phase = DynamicValue.new("Waiting" :: Types.Phase)
InstanceSignal.ListenAttribute<<Types.Phase?>>(replicatedData, "Phase"):Connect(function(phase)
	module.Phase:SetValue(phase or "Waiting")
end, true)

module.AdvanceTime = DynamicValue.new(nil :: number?)
InstanceSignal.ListenAttribute<<number?>>(replicatedData, "AdvanceTime"):Connect(function(advanceTime)
	module.AdvanceTime:SetValue(advanceTime)
end, true)

module.Winner = DynamicValue.new(nil :: string?)
InstanceSignal.ListenAttribute<<string?>>(replicatedData, "Winner"):Connect(function(winner)
	module.Winner:SetValue(winner)
end, true)

module.WinnerKind = DynamicValue.new(nil :: "Role" | "Participant"?)
InstanceSignal.ListenAttribute<<"Role" | "Participant"?>>(replicatedData, "WinnerKind"):Connect(function(winnerKind)
	module.WinnerKind:SetValue(winnerKind)
end, true)

module.Paused = DynamicValue.new(false)
InstanceSignal.ListenAttribute<<boolean>>(replicatedData, "Paused"):Connect(function(paused)
	module.Paused:SetValue(paused)
end, true)

module.StartTime = DynamicValue.new(nil :: number?)
InstanceSignal.ListenAttribute<<number?>>(replicatedData, "StartTime"):Connect(function(startTime)
	module.StartTime:SetValue(startTime)
end, true)

function module.GetPlayerScores(): {[string]: Types.ScoreTable}
    local playerScores: {[string]: Types.ScoreTable} = {}
    for _, v in replicatedData.Scores:GetChildren() do
        if v:IsA("StringValue") then
            local name = v.Name
            playerScores[name] = {}
            for _, scoreValue in v:GetChildren() do
                assert(scoreValue:IsA("IntValue"))
                playerScores[name][scoreValue.Name] = scoreValue.Value
            end
        end
    end

    return playerScores
end

task.defer(function()
    local mapScript = workspace:FindFirstChild("Map")
    if mapScript then
        module.Map:SetValue(Map.new(Map.ValidateStructure(mapScript)))
    end
end)

module.Interactables = DynamicValue.new({} :: {[Instance]: Types.Prop?})

local function loadInteractable(instance: Instance): ()
    assert(instance:IsA("BasePart") or instance:IsA("Model"), "Interactable must be a BasePart or Model")
    if not instance:IsDescendantOf(workspace) then
        return
    end

    if module.Interactables()[instance] then
        return
    end

    local gamemode, map = module.Gamemode(), module.Map()
    while not gamemode or not map do
        task.wait()
        gamemode, map = module.Gamemode(), module.Map()
    end
    assert(gamemode and map)

    local name = instance.Name
    if instance:HasTag("Door") then
        name = "Door"
    elseif instance:HasTag("Ladder") then
        name = "Ladder"
    elseif instance:HasTag("Item") then
        name = "Item"
    end

    local definition = GetInteractableDefinition(name, gamemode, map)
    if not definition then
        return
    end

    local interactable = Prop.new(instance, nil, definition)
    module.Interactables()[instance] = interactable

    if definition.OnLoadClient then
        definition.OnLoadClient(interactable)
    end
end

module.Map:Connect(function(map)
    if not map then
        return
    end

    map.Structure.Dynamic.DescendantAdded:Connect(function(descendant: Instance)
        if descendant:HasTag("Interactable") then
            loadInteractable(descendant)
        end
    end)
    for _, v in GetTaggedDescendants(map.Structure.Dynamic, "Interactable") do
        loadInteractable(v)
    end
end, true)

CollectionService:GetInstanceAddedSignal("Interactable"):Connect(loadInteractable)

module.OnReset = DynamicValue.new(nil)

remotes.Reset.OnClientEvent:Connect(function()
	module.Credits:SetValue(0)
    module.Interactables:SetValue({})
    module.FreeKill:SetValue()

    module.OnReset:Invoke()
end)

remotes.MapLoaded.OnClientEvent:Connect(function()
    local child = workspace:FindFirstChild("Map")
    if not child then
        return
    end

    if #child:GetChildren() < 1 then
        child.ChildAdded:Wait()
    end

    local newMap = Map.new(Map.ValidateStructure(child))
    module.Map:SetValue(newMap)

    child.Destroying:Once(function()
        if module.Map() == newMap :: Types.Map? then
            module.Map:SetValue()
        end
    end)
end)

return table.freeze(module)