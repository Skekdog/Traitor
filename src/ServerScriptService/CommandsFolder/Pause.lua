local CmdrTypes = require(game:GetService("ReplicatedFirst").CmdrTypes)
local definition: CmdrTypes.CommandDefinition = {
    Name = "pause",
    Aliases = {},
    Description = "Pauses the current round timer, if possible.",
    Group = "Admin",
    Args = {},
}
return definition