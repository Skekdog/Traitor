local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Types = require(ReplicatedStorage.API.Types)

local function Gun(components: Types.ItemComponents): Types.ItemComponents
	local base: Types.ItemComponents = {
		Name = "",
		Description = "",
		IconContent = Content.none,

		HasMuzzleFlash = true,
		CanHeadshot = true,
		IsAimable = true,

		DamageKind = "Shot",

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

return Gun