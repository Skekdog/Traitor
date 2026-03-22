local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local module: {[string]: Types.AmmoDefinition} = {}

local boxModels = ReplicatedStorage.Assets.AmmoBoxModels

module["Super Gun"] = {
    Kind = "Ammo",
    Name = "Super Gun",
    Capacity = 10000,
    ReserveCapacity = 0,
    CanDrop = false,
}

module.HUGE = {
    Kind = "Ammo",
    Name = "HUGE",
    Capacity = 250,
    ReserveCapacity = 0,
    CanDrop = false,
}

module.AWP = {
    Kind = "Ammo",
    Name = "AWP",
    Capacity = 4,
    ReserveCapacity = 0,
    CanDrop = false,
}

module.MelonLauncher = {
    Kind = "Ammo",
    Name = "MelonLauncher",
    Capacity = 4,
    ReserveCapacity = 0,
    CanDrop = false,
}

module.Flare = {
    Kind = "Ammo",
    Name = "Flare",
    Capacity = 6,
    ReserveCapacity = 0,
    CanDrop = false,
}

module["Golden Bullet"] = {
    Kind = "Ammo",
    Name = "Golden Bullet",
    Capacity = 1,
    ReserveCapacity = 0,
    CanDrop = false,
}

module["Mil-Spec"] = {
    Kind = "Ammo",
    Name = "Mil-Spec",
    Capacity = 20,
    ReserveCapacity = 60,
    Model = boxModels["Mil-Spec"],
    CanDrop = true,
}

module.Shotgun = {
    Kind = "Ammo",
    Name = "Shotgun",
    Capacity = 8,
    ReserveCapacity = 16,
    Model = boxModels.Shotgun,
    CanDrop = true,
}

module["High-Cal"] = {
    Kind = "Ammo",
    Name = "High-Cal",
    Capacity = 8,
    ReserveCapacity = 32,
    Model = boxModels["High-Cal"],
    CanDrop = true,
}

module["Sub-Spec"] = {
    Kind = "Ammo",
    Name = "Sub-Spec",
    Capacity = 30,
    ReserveCapacity = 60,
    Model = boxModels["Sub-Spec"],
    CanDrop = true,
}

module.Rifle = {
    Kind = "Ammo",
    Name = "Rifle",
    Capacity = 5,
    ReserveCapacity = 10,
    Model = boxModels.Rifle,
    CanDrop = true,
}

module.Poltergeist = {
    Kind = "Ammo",
    Name = "Poltergeist",
    Capacity = 6,
    ReserveCapacity = 0,
    CanDrop = false,
}

module.Infinite = {
    Kind = "Ammo",
    Name = "Infinite",
    Capacity = math.huge,
    ReserveCapacity = 0,
    CanDrop = false,
}

return table.freeze(module)