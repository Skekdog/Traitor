local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local IsNaN = require(ReplicatedStorage.Shared.Util.IsNaN)
local RoundHandler = require(ServerScriptService.RoundHandler)

ReplicatedStorage.Remotes.ClientServer.Fell.OnServerEvent:Connect(function(player: Player, velocity: unknown): ()
    if typeof(velocity) ~= "number" or IsNaN(velocity) then
        return
    end

    local participant = RoundHandler.Round():GetParticipant(player.Name)
    if not participant then
        return
    end

    if velocity <= 45 then
        return
    end

    local damage = (0.00591 * (velocity ^ 2)) + (0.62055 * velocity) - 40

    participant:TryTakeDamage({
        Amount = damage,
        Source = "Fall",
    })
end)

return nil