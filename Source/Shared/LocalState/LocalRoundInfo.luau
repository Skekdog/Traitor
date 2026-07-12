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

module.Map = DynamicValue.new(nil :: Types.Map?)

module.RoundFinishData = DynamicValue.new<<Types.ClientRoundFinishData?>>()

remotes.RoundFinishData.OnClientEvent:Connect(function(data)
    module.RoundFinishData:SetValue(data)
end)

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

module.Phase = DynamicValue.new("Waiting" :: Types.Phase)
InstanceSignal.ListenAttribute<<Types.Phase?>>(replicatedData, "Phase"):Connect(function(phase)
	module.Phase:SetValue(phase or "Waiting")
end, true)

module.AdvanceTime = DynamicValue.new(nil :: number?)
InstanceSignal.ListenAttribute<<number?>>(replicatedData, "AdvanceTime"):Connect(function(advanceTime)
	module.AdvanceTime:SetValue(advanceTime)
end, true)

module.Paused = DynamicValue.new(false)
InstanceSignal.ListenAttribute<<boolean>>(replicatedData, "Paused"):Connect(function(paused)
	module.Paused:SetValue(paused)
end, true)

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