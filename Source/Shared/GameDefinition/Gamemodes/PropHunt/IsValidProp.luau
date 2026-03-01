local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)

local MIN_SIZE = 1

local function IsValidProp(prop: Types.MapObject): boolean
	if prop:HasTag("Ammo") or prop:HasTag("Item") or prop:HasTag("Interactable") then
		return false
	end

	local part = GetPrimaryPart(prop)
	if part.Anchored then
		return false
	end

	local size = if prop:IsA("Model") then prop:GetExtentsSize() else prop.ExtentsSize
	return size.X >= MIN_SIZE and size.Y >= MIN_SIZE and size.Z >= MIN_SIZE
end

return IsValidProp