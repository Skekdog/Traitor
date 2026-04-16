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
				function() return true
			end,

		PrimaryFireServer =
			if RunService:IsServer() then
				require(ReplicatedStorage.API.Item.Behaviour.Server).PrimaryFire
			else
				function() return nil
			end,

		AlternateToggled = true,
		AlternateFireClient =
			if RunService:IsClient() then
				require(ReplicatedStorage.API.Item.Behaviour.Client).Aim
			else
				function() return true
			end,

		OnHitRejectServer =
			if RunService:IsServer() then
				require(ReplicatedStorage.API.Item.Behaviour.Server).ProcessReject
			else
				nil
			,
	}

	for i, v in components do
		base[i] = v
	end

	return base
end

return Gun