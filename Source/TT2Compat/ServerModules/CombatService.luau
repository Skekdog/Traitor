local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Combat = require(ReplicatedStorage.API.Combat)
local GetParticipant = require(ReplicatedStorage.API.GetParticipant)
local Impulse = require(ReplicatedStorage.API.Impulse)
local Types = require(ReplicatedStorage.API.Types)
local DamageSourceRemap = require(ReplicatedStorage.Compat.DamageSourceRemap)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
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
function module.DamageWithinRadius(self,
	playerFilter: ((player: Player) -> boolean)?,
	assailant: Player?,
	damage: number,
	damageFalloff: boolean,
	position: Vector3,
	radius: number,
	impulseMagnitude: number?,
	impulseIgnoresMass: boolean?,
	impulseAffectsPlayers: boolean?,
	source: Types.GeneralDamageSource?,
	itemId: string?
): ()
	Combat.MakeExplosion({
		Damage = damage,
		FalloffStart = if damageFalloff then 0 else radius - 0.001,
		FalloffEnd = radius,
		Pressure = 0,
		VisualRadius = 0,
		Position = position,
		Attacker = assailant and GetParticipant(assailant)
	}, Instance.new("Sound"))
end

function module.Explosion(self, position: Vector3, soundId: number?, radius: number?, damage: number?): ()
	local params = {
		Damage = damage or 0,
		FalloffStart = 5,
		FalloffEnd = radius or 20,
		Pressure = 10000,
		VisualRadius = 20,
		Position = position,
	}

	local sound = Instance.new("Sound")
	if soundId then
		sound.SoundId = "rbxassetid://" .. soundId
	end

	Combat.MakeExplosion(params, soundId and sound)
end

function module.Impulse(self, target: Model | BasePart, attacker: Player?, origin: Vector3, directionalForce: Vector3, _: boolean, _: boolean, itemName: string): ()
	Impulse.ApplyImpulse(GetPrimaryPart(target), directionalForce, false, nil, attacker and GetParticipant(attacker))
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