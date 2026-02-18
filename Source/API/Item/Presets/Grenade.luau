local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Types = require(ReplicatedStorage.API.Types)

local function Grenade(components: Types.ItemComponents): Types.ItemComponents
	local base: Types.ItemComponents = {
		Name = "",
		Description = "",
		IconContent = Content.none,

		IsProjectileSimulated = true,
		PregameDisable = true,
		IsSingleUse = true,

		UseAttack = true,

		DamageKind = "Explode",

		ExplosionInfo = {
			Damage = 0,
			FalloffStart = 0,
			FalloffEnd = 1,
			Pressure = 1,
			VisualRadius = 10,
		},

		PrimaryFireClient =
			if RunService:IsClient() then
				require(ReplicatedStorage.API.Item.Behaviour.Client).PrimaryFire
			else
				function() return true
			end,

		PrimaryFireServer =
			if RunService:IsServer() then
				require(ReplicatedStorage.API.Item.Behaviour.Server).PrimaryFire
			else
				function() return nil
			end,

		ProjectileSpeed = 35,
	}

	for i, v in components do
		base[i] = v
	end

	return base
end

return Grenade