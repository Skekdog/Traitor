local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShatterGlass = require(ReplicatedStorage.Shared.Combat.ShatterGlass)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local function Window(prop: Types.Prop, params: Types.DamageParams?): ()
	ShatterGlass(GetPrimaryPart(prop.Model), if params and params.Origin then params.Origin - (params.HitPosition or GetPrimaryPart(prop.Model).Position) else nil)
end

return Window