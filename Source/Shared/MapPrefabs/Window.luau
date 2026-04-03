local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShatterGlass = require(ReplicatedStorage.Shared.Combat.ShatterGlass)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local Types = require(ReplicatedStorage.API.Types)

local function Window(prop: Types.Prop, params: Types.DamageParams): ()
	local force = 1
	do
		local source = params.Source
		if typeof(source) == "table" and source.ImpulseForce then
			force = source.ImpulseForce
		end
	end

	ShatterGlass(GetPrimaryPart(prop.Model), if params.Direction then params.Direction * force else nil)
end

return Window