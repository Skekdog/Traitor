local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local Types = require(script.Parent.Types)

local Fire = {}

function Fire.MakeVisuals(object: Types.MapObject): ()
	local visuals = ReplicatedStorage.Assets.FireParticles:Clone()
	visuals.Parent = GetPrimaryPart(object) :: any
end

function Fire.Ignite(object: Types.MapObject): ()
	Fire.MakeVisuals(object)
	object:AddTag("Burning")
end

function Fire.Extinguish(object: Types.MapObject): ()
	local visuals = object:FindFirstChild("FireParticles")
	if visuals then
		visuals:Destroy()
	end

	object:RemoveTag("Burning")
end

function Fire.IsBurning(object: Types.MapObject): boolean
	return object:HasTag("Burning")
end

return Fire