local function createInteractableForItem(item: Types.Item, round: Types.Round): Types.Interactable
    local interactableDefinition = round:GetInteractableDefinition(item.Definition.Name)
    assert(interactableDefinition, "Could not find interactable definition for " .. item.Definition.Name)
    return round:AddInteractable(interactableDefinition, nil, true)
end

local function throwInteractable(item: Types.Item, mode: "Primary" | "Alternate", origin: Vector3, direction: Vector3, participant: Types.Participant): Types.Interactable?
    local round = participant.Round

    local interactable = createInteractableForItem(item, round)
    interactable.Model:RemoveTag("Item")
    interactable.Extras.PlantedBy = participant
    interactable.Extras.Player = participant.Player
    local success = participant:TryThrowAssembly(interactable.Model, 10, round:GetMap().Structure.Dynamic, nil, direction)

    if not success then
        round._interactables[interactable.Model] = nil
        interactable.Model:Destroy()
        return nil
    end

    participant:RemoveItem(item)

    return interactable
end

local function plantInteractable(item: Types.Item, origin: Vector3, direction: Vector3, participant: Types.Participant): (Types.Interactable?, RaycastResult?, WeldConstraint?)
    local params = RaycastParams.new()
    params.CollisionGroup = "WeaponHitTargets"
    params.FilterDescendantsInstances = {workspace.Characters, workspace.Projectiles}
    params.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(origin, direction * 10, params)
    if not result or not result.Instance:IsDescendantOf(participant.Round:GetMap().Structure.Static) then
        return nil
    end

    local interactable = createInteractableForItem(item, participant.Round)
    interactable.Extras.PlantedBy = participant
    local object = interactable.Model
    object:RemoveTag("Item");
    (object :: Instance).Parent = participant.Round:GetMap().Structure.Dynamic

    GetPrimaryPart(object).CFrame = CFrame.lookAt(result.Position, result.Position + result.Normal)

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = result.Instance :: BasePart
    weld.Part1 = GetPrimaryPart(object)
    weld.Parent = object

    participant:RemoveItem(item)

    return interactable, result, weld
end

items.C4 = {
    Kind = "Item" :: "Item",
    Name = "C4",
    ItemGroup = ItemGroups.RoleWeapon,
    CanDrop = true,

    IsEvilItem = true,

    Description = "Explodes in a massive radius after a set timer.",
    Icon = "rbxassetid://17229908151",

	Model = interactableModels("C4"),
    HoldAnimation = "rbxassetid://92236433436790",

    CreditCost = 1,
    MaxStock = 2,

    PrimaryHint = "Throw C4",
    AlternateHint = "Plant C4",

    PrimaryToggled = true,
    AlternateToggled = true,

    PrimaryFireServer = throwInteractable,
    AlternateFireServer = function(item: Types.Item, mode: "Primary" | "Alternate", origin: Vector3, direction: Vector3, participant: Types.Participant): ()
        local interactable, result, weld = plantInteractable(item, origin, direction, participant)
        if not interactable or not result or not weld then
            return
        end

        local object = interactable.Model
        assert(object:IsA("BasePart"))

        weld.Enabled = false
        object.CFrame *= CFrame.Angles(math.rad(-90), 0, 0)
		object.CFrame += result.Normal / 4
        weld.Enabled = true
    end
}

items.Visualiser = {
    Kind = "Item" :: "Item",
    Name = "Visualiser",
    ItemGroup = ItemGroups.RoleUtility,
    CanDrop = true,

    Description = "Recreates the scene of a player's murder, if they were killed by bullets.",
    Icon = "rbxassetid://11817043651",

    CreditCost = 1,
    MaxStock = 1,

    PrimaryToggled = true,
    PrimaryHint = "Deploy Visualiser",
    PrimaryFireServer = function(item: Types.Item, mode: "Primary" | "Alternate", origin: Vector3, direction: Vector3, participant: Types.Participant): ()
        local interactable = throwInteractable(item, mode, origin, direction, participant)
        if not interactable then
            return
        end

        interactable.Extras.Player = participant.Player
    end
}

items.Radio = {
    Kind = "Item" :: "Item",
    Name = "Radio",
    ItemGroup = ItemGroups.RoleUtility,
    CanDrop = false,

    Description = "Remotely plays a sound to confuse nearby spies.",
    Icon = "rbxassetid://128627317841330",

    CreditCost = 1,
    MaxStock = 1,

    PrimaryToggled = true,
    PrimaryHint = "Deploy Radio",
    PrimaryFireServer = function(item: Types.Item, mode: "Primary" | "Alternate", origin: Vector3, direction: Vector3, participant: Types.Participant): ()
        local interactable = throwInteractable(item, mode, origin, direction, participant)
        if not interactable then
            return
        end

        interactable.Extras.Player = participant.Player
        DNAScanner.AddDNATrace(interactable, participant, nil, "rbxassetid://128627317841330", interactable.Model)
    end,
}

items.HealthStation = {
    Kind = "Item" :: "Item",
    Name = "HealthStation",
    DisplayName = "Health Station",
    ItemGroup = ItemGroups.RoleUtility,
    CanDrop = true,

    Description = "Can be used by anyone to restore health, with a slow recharge.",
    Icon = "rbxassetid://93284379186217",
    IsPixelIcon = true,

    CreditCost = 1,
    MaxStock = 1,

    PrimaryToggled = true,
    PrimaryHint = "Deploy Health Station",
    PrimaryFireServer = throwInteractable,
}

items.DeathStation = {
    Kind = "Item" :: "Item",
    Name = "DeathStation",
    DisplayName = "Death Station",
    ItemGroup = ItemGroups.RoleUtility,
    CanDrop = true,

    Description = "Visually mimics a health station. Can be used by good guys to die.",
    Icon = "rbxassetid://109445031317494",
    IsPixelIcon = true,

    CreditCost = 1,
    MaxStock = 1,

    PrimaryToggled = true,
    PrimaryHint = "Deploy Death Station",
    PrimaryFireServer = function(item: Types.Item, mode: "Primary" | "Alternate", origin: Vector3, direction: Vector3, participant: Types.Participant): ()
        local interactable = throwInteractable(item, mode, origin, direction, participant)
        if not interactable then
            return
        end

        interactable.Extras.Owner = participant

        DNAScanner.AddDNATrace(interactable, participant, nil, "rbxassetid://93284379186217", interactable.Model)
    end,
}

items.Decoy = {
    Kind = "Item" :: "Item",
    Name = "Decoy",
    ItemGroup = ItemGroups.RoleUtility,
    CanDrop = false,

    CreditCost = 1,
    MaxStock = 1,

    Description = "When placed, overrides your shown position on radars. Can be destroyed.",
    Icon = "rbxassetid://96906503847712",

    AlternateToggled = true,
    AlternateHint = "Plant Decoy",

    AlternateFireServer = function(item: Types.Item, mode: "Primary" | "Alternate", origin: Vector3, direction: Vector3, participant: Types.Participant): ()
        local interactable, _, weld = plantInteractable(item, origin, direction, participant)
        if not interactable or not weld then
            return
        end

        local object = interactable.Model
        assert(object:IsA("BasePart"))

        weld.Enabled = false
        object.CFrame *= CFrame.new(0, 0, -object.Size.Z / 2)
        weld.Enabled = true

        interactable.Model:SetAttribute("Player", participant.Player.Name)
        DNAScanner.AddDNATrace(interactable, participant, nil, "rbxassetid://96906503847712", interactable.Model)
    end
}

return allItems