local Types = require(script.Parent.Parent.RoundRule.Types)
local module: {[string]: Types.AmmoDefinition} = {}

local NO_PART = Instance.new("Part")

module.HUGE = {
    Kind = "Ammo",
    Name = "HUGE",
    Capacity = 250,
    ReserveCapacity = 0,
    Model = NO_PART,
}

module.AWP = {
    Kind = "Ammo",
    Name = "AWP",
    Capacity = 4,
    ReserveCapacity = 0,
    Model = NO_PART,
}

module.Flare = {
    Kind = "Ammo",
    Name = "Flare",
    Capacity = 6,
    ReserveCapacity = 0,
    Model = NO_PART,
}

module["Golden Bullet"] = {
    Kind = "Ammo",
    Name = "Golden Bullet",
    Capacity = 1,
    ReserveCapacity = 0,
    Model = NO_PART,
}

module["9mm"] = {
    Kind = "Ammo",
    Name = "9mm",
    Capacity = 20,
    ReserveCapacity = 60,
    Model = NO_PART,
}

module.Shotgun = {
    Kind = "Ammo",
    Name = "Shotgun",
    Capacity = 8,
    ReserveCapacity = 16,
    Model = NO_PART,
}

module.Deagle = {
    Kind = "Ammo",
    Name = "Deagle",
    Capacity = 8,
    ReserveCapacity = 32,
    Model = NO_PART,
}

module.SMG1 = {
    Kind = "Ammo",
    Name = "SMG1",
    Capacity = 30,
    ReserveCapacity = 60,
    Model = NO_PART,
}

module.Rifle = {
    Kind = "Ammo",
    Name = "Rifle",
    Capacity = 5,
    ReserveCapacity = 10,
    Model = NO_PART,
}

return module