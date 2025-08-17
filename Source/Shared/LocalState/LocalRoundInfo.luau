local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Interactable = require(ReplicatedStorage.Shared.RoundRule.Interactable)
local Map = require(ReplicatedStorage.Shared.RoundRule.Map)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
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

module.Gamemode = DynamicValue.new(nil :: Types.GamemodeDefinition?)
InstanceSignal.ListenAttribute(replicatedData, "Gamemode", "" :: string?):Connect(function(name: string?)
    if not name then
        module.Gamemode:SetValue()
        return
    end

    local object = ReplicatedStorage.Shared.GameDefinition.Gamemodes:FindFirstChild(name)
    if object then
        module.Gamemode:SetValue((require)(object))
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
InstanceSignal.ListenAttribute(replicatedData, "Phase", "Waiting" :: Types.Phase):Connect(function(phase: string?)
	module.Phase:SetValue(phase or "Waiting")
end, true)

module.AdvanceTime = DynamicValue.new(nil :: number?)
InstanceSignal.ListenAttribute(replicatedData, "AdvanceTime", 0 :: number?):Connect(function(advanceTime)
	module.AdvanceTime:SetValue(advanceTime)
end, true)

module.Winner = DynamicValue.new(nil :: string?)
InstanceSignal.ListenAttribute(replicatedData, "Winner", nil :: string?):Connect(function(winner)
	module.Winner:SetValue(winner)
end, true)

module.WinnerKind = DynamicValue.new(nil :: "Role" | "Participant"?)
InstanceSignal.ListenAttribute(replicatedData, "WinnerKind", nil :: "Role" | "Participant"?):Connect(function(winnerKind)
	module.WinnerKind:SetValue(winnerKind)
end, true)

module.Paused = DynamicValue.new(false)
InstanceSignal.ListenAttribute(replicatedData, "Paused", false):Connect(function(paused)
	module.Paused:SetValue(paused)
end, true)

module.StartTime = DynamicValue.new(nil :: number?)
InstanceSignal.ListenAttribute(replicatedData, "StartTime", nil :: number?):Connect(function(startTime)
	module.StartTime:SetValue(startTime)
end, true)

function module.GetPlayerScores(): {[string]: Types.ScoreTable}
    local playerScores: {[string]: Types.ScoreTable} = {}
    for _, v in replicatedData.Scores:GetChildren() do
        if v:IsA("StringValue") then
            local name = v.Name
            playerScores[name] = {}
            for reason, value in v:GetAttributes() do
                playerScores[name][reason] = value :: number
            end
        end
    end

    return playerScores
end

do
    local map: Types.Map?
    local mapScript = workspace:FindFirstChild("Map")
    if mapScript then
        if mapScript:IsA("ModuleScript") then
            map = Map.fromModuleScript(mapScript)
        end
    end

    module.Map = DynamicValue.new(map)
end

module.Interactables = DynamicValue.new({} :: {[Instance]: Types.Interactable?})

local function loadInteractable(instance: Instance): ()
    if not instance:IsDescendantOf(workspace) then
        return
    end

    while not module.Gamemode() or not module.Map() do
        task.wait()
    end

    local GetInteractableDefinition = (require)(script.Parent.GetInteractableDefinition)
    local definition: Types.InteractableDefinition = GetInteractableDefinition(instance.Name)
    if not definition then
        return
    end

    local interactable = Interactable.new(definition, instance :: BasePart)
    module.Interactables()[instance] = interactable

    if definition.OnLoadClient then
        definition.OnLoadClient(interactable)
    end
end

CollectionService:GetInstanceAddedSignal("InteractableLoaded"):Connect(loadInteractable)
for _, v in CollectionService:GetTagged("InteractableLoaded") do
    loadInteractable(v)
end

module.OnReset = DynamicValue.new(nil)

remotes.Reset.OnClientEvent:Connect(function()
	module.Credits:SetValue(0)
    module.Interactables:SetValue({})
    module.FreeKill:SetValue()

    module.OnReset:Invoke()
end)

remotes.MapLoaded.OnClientEvent:Connect(function()
    local child = workspace:FindFirstChild("Map")
    if not child or not child:IsA("ModuleScript") then
        return
    end

    if #child:GetChildren() < 1 then
        child.ChildAdded:Wait()
    end

    local newMap = Map.fromModuleScript(child)
    module.Map:SetValue(newMap)

    child.Destroying:Once(function()
        if module.Map() == newMap then
            module.Map:SetValue()
        end
    end)
end)

return module