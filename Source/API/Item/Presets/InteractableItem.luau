local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Audio = require(ReplicatedStorage.API.Audio)
local Types = require(ReplicatedStorage.API.Types)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)

local function createInteractableForItem(item: Types.Item, round: Types.Round, participant: Types.Participant): Types.Prop
    local interactableDefinition = round:GetInteractableDefinition(item.Name)
    assert(interactableDefinition, "Could not find interactable definition for " .. item.Name)
    assert(interactableDefinition.Model, "Interactable must have a model")
    local model = interactableDefinition.Model:Clone()
    model:AddTag("Interactable")
    model:RemoveTag("Item")

    local prop = round:LoadProp(model)
    prop.Extras.Participant = participant
    prop.Extras.Player = participant.Player

    return prop
end

local throwSound = Audio.MakeSound({
    Content = Content.fromAssetId(137090564514029),

    Volume = 1,

    RolloffStart = 10,
    RolloffEnd = 15,
})

local plantSound = Audio.MakeSound({
    Content = Content.fromAssetId(95346310800820),

    Volume = 1,

    RolloffStart = 10,
    RolloffEnd = 15,
})

local function throwInteractable(item: Types.Item, participant: Types.Participant, origin: Vector3, direction: Vector3, deferParent: boolean?): Types.Prop?
    local round = participant.Round

    local interactable = createInteractableForItem(item, round, participant)
    local success = participant:TryThrowAssembly(interactable.Model, 10, if deferParent then nil else round:GetMap().Structure.Dynamic, nil, direction)

    if not success then
        round._props[interactable.Model] = nil
        interactable.Model:Destroy()
        return nil
    end

    participant:RemoveItem(item, true)

    Audio.PlayIn(throwSound, GetPrimaryPart(interactable.Model), nil, true)

    if deferParent then
        task.defer(function()
            (interactable.Model :: Instance).Parent = round:GetMap().Structure.Dynamic
        end)
    end

    return interactable
end

local function plantInteractable(item: Types.Item, participant: Types.Participant, origin: Vector3, direction: Vector3): (Types.Prop?, RaycastResult?, WeldConstraint?)
    local params = RaycastParams.new()
    params.CollisionGroup = "WeaponHitTargets"
    params.ExcludeInstances = {workspace.Characters, workspace.Projectiles}

    local result = workspace:Raycast(origin, direction * 10, params)
    if not result or not result.Instance:IsDescendantOf(participant.Round:GetMap().Structure.Static) then
        return nil
    end

    local interactable = createInteractableForItem(item, participant.Round, participant)
    local object = interactable.Model
    object:RemoveTag("Item");
    (object :: Instance).Parent = participant.Round:GetMap().Structure.Dynamic

    GetPrimaryPart(object).CFrame = CFrame.lookAt(result.Position, result.Position + result.Normal)

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = result.Instance :: BasePart
    weld.Part1 = GetPrimaryPart(object)
    weld.Parent = object

    participant:RemoveItem(item, true)

    Audio.PlayIn(plantSound, GetPrimaryPart(object), nil, true)

    return interactable, result, weld
end

local function Custom(components: Types.ItemComponents, allowThrow: boolean, allowPlant: boolean, onThrow: (interactable: Types.Prop, participant: Types.Participant) -> ()?, onPlant: (interactable: Types.Prop, raycastResult: RaycastResult, weldConstraint: WeldConstraint, participant: Types.Participant) -> ()?, throwCount: number?): Types.ItemComponents
	local base: Types.ItemComponents = {
		Name = "",
		Description = "",
		IconContent = Content.none,

		PrimaryFireServer = if allowThrow then function(item, origin, direction, participant)
            for i = 1, throwCount or 1 do
                local interactable = throwInteractable(item, participant, origin, direction, throwCount ~= nil)
                if interactable and onThrow then
                    onThrow(interactable, participant)
                end
            end
            return nil
		end else nil,

		AlternateFireServer = if allowPlant then function(item, origin, direction, participant)
			local interactable, raycastResult, weldConstraint = plantInteractable(item, participant, origin, direction)
			if interactable and raycastResult and weldConstraint and onPlant then
				onPlant(interactable, raycastResult, weldConstraint, participant)
			end
            return nil
		end else nil,
	}

	for i, v in components do
		base[i] = v
	end

	return base
end

return Custom