local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Interactable = require(ReplicatedStorage.RoundRule.Interactable)
local DynamicValue = require(script.Parent.DynamicValue)
local InstanceSignal = require(script.Parent.InstanceSignal)
local Map = require(script.Parent.RoundRule.Map)
local Role = require(script.Parent.RoundRule.Role)
local Types = require(script.Parent.RoundRule.Types)
local module = {}

local replicatedData = ReplicatedStorage.RoundRule.ReplicatedData
local remotes = ReplicatedStorage.RoundRule.Remotes

type CallbackName = "Map" | "Gamemode" | "Role" | "Paused" | "Phase" | "AdvanceTime" | "Credits" | "PlayerStatus" | "PlayerRole" | "Winner" | "WinnerKind" | "StartTime" | "Corpse"

type RoundHighlight = {
    Title: string,
    Description: string
}

type RoundEvent = {
    Timestamp: number,
    Description: string,
    WasFreeKill: boolean?,
    WasSelfDefense: boolean?,
    WasCorrectKill: boolean?,
}

module.Gamemode = DynamicValue.new(nil :: Types.Gamemode?)
InstanceSignal.ListenAttribute(replicatedData, "Gamemode", "" :: string?):Connect(function(name: string?)
    if not name then
        module.Gamemode:SetValue()
        return
    end

    local object = ReplicatedStorage.GameDefinition.Gamemodes:FindFirstChild(name)
    if object then
        module.Gamemode:SetValue((require)(object))
    else
        module.Gamemode:SetValue()
    end
end, true)

local function getRoleFromName(name: string?): Types.Role?
    if not name then
        return nil
    end
    
	local gamemode = module.Gamemode()
    assert(gamemode, "Gamemode is not loaded")
    return Role.fromDefinition(gamemode.Roles[name] or error("Role not found"))
end

module.Credits = DynamicValue.new(0)
remotes.UpdateCredits.OnClientEvent:Connect(function(value: number?)
    module.Credits:SetValue(value or 0)
end)

module.FreeKill = DynamicValue.new(nil :: string?)
remotes.FreeKill.OnClientEvent:Connect(function(reason: string?)
    module.FreeKill:SetValue(reason)
end)

function module.GetRoundHighlights(): {RoundHighlight}
    local highlights: {RoundHighlight} = {}
    for _, v in replicatedData.Highlights:GetChildren() do
        if v:IsA("StringValue") then
            table.insert(highlights, {
                Title = v.Name,
                Description = v.Value
            })
        end
    end

    return highlights
end

function module.GetOrderedRoundEvents(): {RoundEvent}
    local events: {RoundEvent} = {}
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

module.RoundPhase = DynamicValue.new("Waiting" :: Types.RoundPhase)
InstanceSignal.ListenAttribute(replicatedData, "Phase", "Waiting" :: Types.RoundPhase):Connect(function(phase: string?)
	module.RoundPhase:SetValue(phase or "Waiting")
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

local function createOrSetDynamicValue<T>(tbl: {[string]: DynamicValue.DynamicValue<T>?}, name: string, value: T): DynamicValue.DynamicValue<T>
	local dynamicValue = tbl[name]
	if not dynamicValue then
		dynamicValue = DynamicValue.new(value)
		tbl[name] = dynamicValue
		assert(dynamicValue)
		return dynamicValue
	else
		dynamicValue:SetValue(value)
		return dynamicValue
	end
end

module.PlayerStatuses = DynamicValue.new({} :: {[string]: DynamicValue.DynamicValue<Types.ParticipantStatus>?})
remotes.UpdatePlayerStatus.OnClientEvent:Connect(function(name: string, status: Types.ParticipantStatus?)
	createOrSetDynamicValue(module.PlayerStatuses() :: {[string]: DynamicValue.DynamicValue<Types.ParticipantStatus & any>?}, name, status or "Spectating")
	module.PlayerStatuses:Invoke()
end)

module.PlayerRoles = DynamicValue.new({} :: {[string]: DynamicValue.DynamicValue<Types.Role?>?})
remotes.UpdatePlayerRole.OnClientEvent:Connect(function(name: string, roleName: string?)
	createOrSetDynamicValue(module.PlayerRoles(), name, getRoleFromName(roleName))
	module.PlayerRoles:Invoke()
end)

module.PlayerCorpses = DynamicValue.new({} :: {[string]: DynamicValue.DynamicValue<Types.CorpseView>?})
remotes.UpdatePlayerCorpse.OnClientEvent:Connect(function(corpse: Types.CorpseView, covert: boolean)
    if covert then
        return
    end

	createOrSetDynamicValue(module.PlayerCorpses(), corpse.Name, corpse)
	module.PlayerCorpses:Invoke()
end)

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

module.Map:Connect(function(map)
    if not map then
        return
    end
    map.Interactables.ChildAdded:Connect(loadInteractable)

    for _, v in map.Interactables:GetChildren() do
        loadInteractable(v)
    end
end, true)

module.OnReset = DynamicValue.new(nil)

remotes.Reset.OnClientEvent:Connect(function()
	module.Credits:SetValue(0)
	module.PlayerStatuses:SetValue({})
	module.PlayerRoles:SetValue({})
    module.PlayerCorpses:SetValue({})
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