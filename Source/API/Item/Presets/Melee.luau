local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Types = require(ReplicatedStorage.API.Types)

local function Melee(components: Types.ItemComponents): Types.ItemComponents
	local base: Types.ItemComponents = {
		Name = "",
		Description = "",
		IconContent = Content.none,

		MaxDistance = 7.5,
		CheckInitialIntersection = true,

		UseAttack = true,

		DamageKind = "Stab",

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

return Melee