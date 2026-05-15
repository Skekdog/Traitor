local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Audio = require(ReplicatedStorage.API.Audio)
local DNATraces = require(ReplicatedStorage.API.DNATraces)
local GetMapObject = require(ReplicatedStorage.API.GetMapObject)
local Server = require(ReplicatedStorage.API.Item.Behaviour.Server)
local Types = require(ReplicatedStorage.API.Types)
local ForEachPart = require(ReplicatedStorage.Shared.RoundRule.Common.ForEachPart)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local ExplosionParams = require(ReplicatedStorage.Shared.RoundRule.ExplosionParams)

local IDLE_JUMP_INTERVAL = 1.75
local IDLE_JUMP_INTERVAL_OFFSET = 0.25
local IDLE_JUMP_POWER = 10

local ATTACK_RADIUS = 16
local ATTACK_INTERVAL = 1.25
local ATTACK_INTERVAL_OFFSET = 0.1
local ATTACK_POWER = 15

local attackSound = Audio.MakeSound({
	Content = Content.fromAssetId(123427781961789),
	RolloffStart = 10,
	RolloffEnd = 25,
})

local idleSound = Audio.MakeSound({
	Content = Content.fromAssetId(120444494019329),
	RolloffStart = 10,
	RolloffEnd = 20,
})

type TurtleServer = Types.Prop & {
	Interactable: Types.InteractableDefinition,
	Extras: {
		Participant: Types.Participant?,
		LastAction: number?,
	}
}

local function getInterval(base: number, offset: number): number
	return base + (math.random(-offset * 1000, offset * 1000) / 1000)
end

local function tickTurtle(turtle: TurtleServer): boolean
	local owner: Types.Participant? = turtle.Extras.Participant
	if not turtle.Model:IsDescendantOf(workspace) or not turtle.Round or not owner then
		return false
	end

	local lastAction = turtle.Extras.LastAction :: number? or os.clock()
	turtle.Extras.LastAction = lastAction

	if os.clock() - lastAction < getInterval(ATTACK_INTERVAL, ATTACK_INTERVAL_OFFSET) then
		return true
	end

	local part = GetPrimaryPart(turtle.Model)
	local turtlePosition = part.Position

	local closestDistance, closestRoot: BasePart? = ATTACK_RADIUS, nil
	for _, participant in turtle.Round:GetParticipants() do
		if participant == turtle.Extras.Participant or participant:IsAlliedWithParticipant(turtle.Extras.Participant) then
			continue
		end

		local char = participant:GetCharacter()
		local root = if char then char.PrimaryPart else nil

		if not root then
			continue
		end

		local distance = (root.Position - turtlePosition).Magnitude
		if distance >= closestDistance then
			continue
		end

		closestDistance, closestRoot = distance, root
	end

	if not closestRoot then
		if os.clock() - lastAction < getInterval(IDLE_JUMP_INTERVAL, IDLE_JUMP_INTERVAL_OFFSET) then
			return true
		end

		local direction = Vector3.new(math.random(-1000, 1000), math.random(-1000, 1000), math.random(-1000, 1000)).Unit
		part:ApplyImpulse((direction + Vector3.yAxis) * part.AssemblyMass * IDLE_JUMP_POWER)

		turtle.Extras.LastAction = os.clock()

		Audio.PlayIn(idleSound, part)

		return true
	end

	local direction = (closestRoot.Position - part.Position).Unit
	part:ApplyImpulse((direction + Vector3.yAxis) * part.AssemblyMass * ATTACK_POWER)

	turtle.Extras.LastAction = os.clock()

	Audio.PlayIn(attackSound, part)

	return true
end

local activeTurtles: {TurtleServer} = {}
RunService.Heartbeat:Connect(function(dt)
	local removeTurtles: {TurtleServer} = {}

	for _, turtle in activeTurtles do
		if not tickTurtle(turtle) then
			table.insert(removeTurtles, turtle)
		end
	end

	for _, turtle in removeTurtles do
		table.remove(activeTurtles, assert(table.find(activeTurtles, turtle)))
	end
end)

local function OnLoadServer(interactable: Types.Prop): ()
	local turtle = interactable :: TurtleServer

	local participant: Types.Participant? = turtle.Extras.Participant
	if participant then
		DNATraces.Add(interactable, participant, nil, Content.fromAssetId(93284379186217), interactable.Model)
	end

	task.delay(1, function()
		table.insert(activeTurtles, turtle)

		ForEachPart(turtle.Model, function(part)
			part.Touched:Connect(function(otherPart)
				if not participant then
					return
				end

				if not otherPart:IsDescendantOf(workspace) then
					return
				end

				local char = GetMapObject(otherPart, "Character")
				if not char then
					return
				end

				local targetParticipant = participant.Round:GetParticipant(char.Name)
				if not targetParticipant or targetParticipant == participant or targetParticipant:IsAlliedWithParticipant(participant) then
					return
				end

				targetParticipant:TryTakeDamage({
					Amount = 100,
					Source = "Poison",
					Attacker = participant,
				})
			end)
		end)
	end)
end

local function OnBreakServer(prop: Types.Prop, params: Types.DamageParams): ()
	Server.CreateExplosion(prop.Round or error("Missing round"), ExplosionParams.new({
		Damage = 50,
		FalloffStart = 10,
		FalloffEnd = 15,
		Pressure = 10000,
		VisualRadius = 15,
	}, GetPrimaryPart(prop.Model).Position, params.Attacker))
end

local model = ReplicatedStorage.Assets.ItemModels.Turtles

local interactable: Types.InteractableDefinition = {
	Name = "Turtles",
	DisplayName = "Turtle",

	Model = model,

	InteractionRange = 7.5,
	IsContinuousInteraction = false,

	OnLoadServer = OnLoadServer,

	OnBreakServer = OnBreakServer,
}

return table.freeze(interactable)