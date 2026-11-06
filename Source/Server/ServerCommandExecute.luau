local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Exec = require(ReplicatedStorage.Shared.DevTools.Console.Exec)
local RoundHandler = require(script.Parent.RoundHandler)

ReplicatedStorage.Remotes.ClientServer.Exec.OnServerInvoke = function(plr, command: unknown): {string}
    if typeof(command) ~= "string" then
        return {"Invalid Command"}
    end

    return Exec.ServerExecute(plr, RoundHandler.Round(), command)
end

return nil