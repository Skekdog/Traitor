local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DamageSourceRemap = require(ReplicatedStorage.Compat.DamageSourceRemap)
local NewtonLauncher = require(ReplicatedStorage.Shared.GameDefinition.Items.NewtonLauncher)
local ExplosionParams = require(ReplicatedStorage.Shared.RoundRule.ExplosionParams)
local Combat = require(ServerScriptService.Combat.Combat)
local RoundHandler = require(ServerScriptService.RoundHandler)

local module = {}

function module.Damage(self, player: Player?, attacker: Player?, damage: number, origin: Vector3?, hitPosition: Vector3?, directionalForce: Vector3?, _: boolean, _: boolean, source: string, itemName: string?): ()
	if not player then
		return
	end

	local round = RoundHandler.GetRound()
	local participant = round:GetParticipant(player.Name)

	if not participant then
		return
	end

	local attackerParticipant = if attacker then round:GetParticipant(attacker.Name) else nil

	participant:TryTakeDamage({
		Amount = damage,
		Attacker = attackerParticipant,
		Source = DamageSourceRemap(source),

		Origin = origin,
		HitPosition = hitPosition,
	})
end

--todo: i'm not certain about these parameters, obviously the missing ones, but also the ones starting with underscore
function module.DamageWithinRadius(self, _, attacker: Player?, _damage: number, _: boolean, position: Vector3, _falloffBegin: number, _falloffEnd: number, _: boolean, _: boolean, source: string): ()
	local round = RoundHandler.GetRound()
	local params = ExplosionParams.new({
		Damage = _damage,
		FalloffBegin = _falloffBegin,
		FalloffEnd = _falloffEnd,
		Pressure = 0,
		VisualRadius = 0,
	}, position)
	Combat.CreateExplosion(round, params, nil, Instance.new("Sound"))
end

function module.Explosion(self, position: Vector3, soundId: number?): ()
	local round = RoundHandler.GetRound()
	local params = ExplosionParams.new({
		Damage = 0,
		FalloffBegin = 5,
		FalloffEnd = 20,
		Pressure = 10000,
		VisualRadius = 20,
	}, position)

	local sound = Instance.new("Sound")
	if soundId then
		sound.SoundId = "rbxassetid://" .. soundId
	end

	Combat.CreateExplosion(round, params, nil, soundId and sound)
end

function module.Impulse(self, target: Model | BasePart, attacker: Player?, origin: Vector3, directionalForce: Vector3, _: boolean, _: boolean, itemName: string): ()
	local part = if target:IsA("Model") then target.PrimaryPart else target
	if not part then
		return
	end
	NewtonLauncher.Fling(part, directionalForce)
end

function module.Impact(self, player: Player?, hit: {Position: Vector3}, target: BasePart, material: Enum.Material): ()
	return
end

function module.ValidateRay(self, range: number, origin: Vector3, hit: {Position: Vector3}, target: BasePart): boolean
	return true -- most usages of this function will need to be manually rewritten anyway, so this is fine
end

function module.SpawnFire(): ()

end

return module