local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GetMapObject = require(ReplicatedStorage.API.GetMapObject)
local Types = require(ReplicatedStorage.API.Types)
local CalculateFallDamage = require(ReplicatedStorage.Shared.Character.CalculateFallDamage)
local IsBadNumber = require(ReplicatedStorage.Shared.Util.IsBadNumber)
local RoundHandler = require(ServerScriptService.RoundHandler)

local params = RaycastParams.new()
params.RespectCanCollide = false

local MAX_ABSORBER_DISTANCE = 10

local function checkForAbsorber(plr: Player, position: Vector3, round: Types.Round): {
    Absorber: Types.Participant | Types.Prop,
    Part: BasePart,
}?

    local include = {workspace.Characters, round:GetMap().Structure.Dynamic} :: {Instance}
    params.IncludeInstances = include
    params.ExcludeInstances = {plr.Character :: Model}

    local result = workspace:Raycast(position, -Vector3.yAxis * MAX_ABSORBER_DISTANCE, params)
    if not result then
        return nil
    end

    local mapObject = GetMapObject(result.Instance, {"Prop", "Character"})
    if not mapObject then
        return nil
    end

    local prop = round:GetProp(mapObject)
    if prop then
        return {
            Absorber = prop,
            Part = result.Instance,
        }
    end

    local participant = round:GetParticipant(mapObject.Name)
    if participant then
        return {
            Absorber = participant,
            Part = result.Instance,
        }
    end

    return nil
end

ReplicatedStorage.Remotes.ClientServer.Fell.OnServerEvent:Connect(function(player: Player, velocity: unknown, position: unknown): ()
    if typeof(velocity) ~= "number" or IsBadNumber(velocity) then
        return
    end

    if typeof(position) ~= "Vector3" then
        return
    end

    local participant = RoundHandler.Round():GetParticipant(player.Name)
    if not participant then
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

    local damage = CalculateFallDamage(velocity)
    if damage == 0 then
        return
    end

    local absorber = checkForAbsorber(player, position, participant.Round)
    if absorber then
        local currentHealth = (absorber.Absorber :: Types.Prop):GetHealth()

        local didDamage = (absorber.Absorber :: Types.Prop):TryTakeDamage({
            Amount = damage,
            Source = "Stomp",
            Attacker = participant,
        })

        if didDamage then
            damage -= currentHealth or 0
        end
    end

    if damage > 0 then
        participant:TryTakeDamage({
            Amount = damage,
            Source = "Fall",
        })
    end
end)

return nil