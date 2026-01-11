local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)

local function Gun(components: Types.ItemComponents): Types.ItemComponents
	local base: Types.ItemComponents = {
		Name = "",
		Description = "",
		IconContent = Content.none,

		HasMuzzleFlash = true,
		CanHeadshot = true,

		DamageKind = "Shot",

		Projectile = ReplicatedStorage.Assets.Projectiles.Bullet,
	}

	for i, v in components do
		base[i] = v
	end

	return base
end

return Gun