local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShatterGlass = require(ReplicatedStorage.Shared.Combat.ShatterGlass)

local function Window(object: Model | BasePart, part: BasePart?, assailant: Player?, damage: number, hitPosition: Vector3?, impulse: Vector3?, damageSource: string?, itemName: string): ()
	if object:IsA("Model") then
		return
	end
	ShatterGlass(object, impulse)
end

return Window