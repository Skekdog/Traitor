local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CalculateFallDamage = require(ReplicatedStorage.Shared.Character.CalculateFallDamage)
local IsBadNumber = require(ReplicatedStorage.Shared.Util.IsBadNumber)
local RoundHandler = require(ServerScriptService.RoundHandler)

ReplicatedStorage.Remotes.ClientServer.Fell.OnServerEvent:Connect(function(player: Player, velocity: unknown): ()
    if typeof(velocity) ~= "number" or IsBadNumber(velocity) then
        return
    end

    local participant = RoundHandler.Round():GetParticipant(player.Name)
    if not participant then
        return
    end

    local damage = CalculateFallDamage(velocity)
    if damage == 0 then
        return
    end

    participant:TryTakeDamage({
        Amount = damage,
        Source = "Fall",
    })
end)

return nil