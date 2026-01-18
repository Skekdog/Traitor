local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
	}

	for i, v in components do
		base[i] = v
	end

	return base
end

return Melee