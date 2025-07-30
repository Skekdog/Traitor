local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShatterGlass = require(ReplicatedStorage.Shared.Combat.ShatterGlass)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local function Window(prop: Types.MapProp, params: Types.DamageParams?): ()
	ShatterGlass(prop.Model, if params and params.Origin then params.Origin - (params.HitPosition or prop.Model.Position) else nil)
end

return Window