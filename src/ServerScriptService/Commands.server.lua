local Cmdr = require(script.Parent.Cmdr)
Cmdr:RegisterCommandsIn(script.Parent.CommandsFolder)
Cmdr:RegisterHook("BeforeRun", function(context): string?
    if context.Group == "Admin" and context.Executor.UserId ~= game.CreatorId then
        return "You don't have permission to run this command."
    end
    return
end)
