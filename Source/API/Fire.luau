local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local Types = require(script.Parent.Types)

local Fire = {}

Fire.Attackers = {} :: {[Types.MapObject]: Types.Participant}

function Fire.MakeVisuals(object: Types.MapObject): ()
	local visuals = ReplicatedStorage.Assets.FireParticles:Clone()
	visuals.Parent = GetPrimaryPart(object) :: any
end

function Fire.Ignite(object: Types.MapObject, attacker: Types.Participant?): ()
	if Fire.IsBurning(object) then
		return
	end

	Fire.MakeVisuals(object)
	object:AddTag("Burning")

	if attacker then
		Fire.Attackers[object] = attacker
	end
end

function Fire.Extinguish(object: Types.MapObject): ()
	local primaryPart = if object:IsDescendantOf(game) then GetPrimaryPart(object) else nil
	if primaryPart then
		local visuals = primaryPart:FindFirstChild("FireParticles")
		if visuals then
			visuals:Destroy()
		end
	end

	Fire.Attackers[object] = nil
	object:RemoveTag("Burning")
end

function Fire.IsBurning(object: Types.MapObject): boolean
	return object:HasTag("Burning")
end

return Fire