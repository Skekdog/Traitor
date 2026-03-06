local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GetParticipant = require(ReplicatedStorage.API.GetParticipant)
local CalculateFallDamage = require(ReplicatedStorage.Shared.Character.CalculateFallDamage)
local IsBadNumber = require(ReplicatedStorage.Shared.Util.IsBadNumber)
local RoundHandler = require(ServerScriptService.RoundHandler)

local function checkForPlayers(plr: Player, root: BasePart): {Player}
    local params = OverlapParams.new()
    params.FilterDescendantsInstances = {workspace.Characters}
    params.FilterType = Enum.RaycastFilterType.Include
    params.RespectCanCollide = false

    local parts = workspace:GetPartBoundsInBox(CFrame.lookAlong(root.Position, -Vector3.zAxis), Vector3.new(3, 40, 3))

    local players: {Player} = {}
    for _, part in parts do
        local char = part.Parent
        if char and char:IsA("Model") then
            local player = Players:GetPlayerFromCharacter(char)
            if player ~= plr and player and not table.find(players, player) then
                table.insert(players, player)
            end
        end
    end

    return players
end

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

    local char = participant:GetCharacter()
    if not char then
        return
    end

    local root = char.PrimaryPart
    if not root then
        return
    end

    local players = checkForPlayers(player, root)
    if #players > 0 then
        for _, player in players do
            local aParticipant = GetParticipant(player)
            if aParticipant then
                aParticipant:TryTakeDamage({
                    Amount = damage / #players,
                    Source = "Stomp",
                    Attacker = participant,
                })
            end
        end

        return
    end

    participant:TryTakeDamage({
        Amount = damage,
        Source = "Fall",
    })
end)

return nil