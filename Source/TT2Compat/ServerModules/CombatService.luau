local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local NewtonLauncher = require(ReplicatedStorage.Shared.GameDefinition.Items.NewtonLauncher)
local ExplosionParams = require(ReplicatedStorage.Shared.RoundRule.ExplosionParams)
local Combat = require(ServerScriptService.Combat.Combat)
local RoundHandler = require(ServerScriptService.RoundHandler)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local module = {}

function module.Damage(self, player: Player, attacker: Player?, damage: number, _, _, _, _, _, source: Types.DamageSource): ()
	local round = RoundHandler.GetRound()
	local participant = round:GetParticipant(player.Name)

	if not participant then
		return
	end

	local attackerParticipant = if attacker then round:GetParticipant(attacker.Name) else nil

	participant:TryTakeDamage({
		Amount = damage,
		Attacker = attackerParticipant,
		Source = source,
	})
end

function module.DamageWithinRadius(self, _, attacker: Player?, _: number, _: boolean, position: Vector3, _: number, _: number, _: boolean, _: boolean, source: Types.DamageSource): ()
	local round = RoundHandler.GetRound()
	local params = ExplosionParams.new({
		Damage = 0,
		FalloffBegin = 5,
		FalloffEnd = 20,
		Pressure = 0,
		VisualRadius = 0,
	}, position)
	Combat.CreateExplosion(round, params, nil, Instance.new("Sound"))
end

function module.Explosion(self, position: Vector3): ()
	local round = RoundHandler.GetRound()
	local params = ExplosionParams.new({
		Damage = 0,
		FalloffBegin = 5,
		FalloffEnd = 20,
		Pressure = 10000,
		VisualRadius = 20,
	}, position)
	Combat.CreateExplosion(round, params)
end

function module.Impulse(self, target: Model | BasePart, attacker: Player?, origin: Vector3, directionalForce: Vector3, _: boolean, _: boolean, itemName: string): ()
	local part = if target:IsA("Model") then target.PrimaryPart else target
	if not part then
		return
	end
	NewtonLauncher.Fling(part, directionalForce)
end

return module