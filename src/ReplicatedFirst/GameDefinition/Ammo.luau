local Types = require(script.Parent.Parent.RoundRule.Types)
local module: {[string]: Types.AmmoDefinition} = {}

local NO_PART = Instance.new("Part")

module.HUGE = {
    Name = "HUGE",
    Kind = "AmmoBox",
    Capacity = 250,
    ReserveCapacity = 0,
    Model = NO_PART,
}

return module