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

		FuseTime = 3,
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
				function() return nil
			end,

		PrimaryFireServer =
			if RunService:IsServer() then
				require(ReplicatedStorage.API.Item.Behaviour.Server).PrimaryFire
			else
				function() return nil
			end,
	}

	for i, v in components do
		base[i] = v
	end

	return base
end

return Grenade