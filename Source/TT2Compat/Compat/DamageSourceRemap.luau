local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)

local remap = {
	Melee = "Bludgeon",
	Bullet = "Shot",
	Headshot = "Shot",
	Blast = "Explode",
	Burn = "Burn",
	Drown = "Drown",
	Crush = "Crush",
	Fall = "Fall",
	Stomp = "Stomp",
}

local function DamageSourceRemap(source: string): Types.GeneralDamageSource
	return remap[source] or "Other"
end

return DamageSourceRemap