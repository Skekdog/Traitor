local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(script.Parent.Types)
local GetMapObjectWithTag = require(ReplicatedStorage.Shared.RoundRule.Common.GetMapObjectWithTag)

local function GetMapObject(descendant: Instance, tag: string | {string}): Types.MapObject?
	return GetMapObjectWithTag(descendant, tag)
end

return GetMapObject