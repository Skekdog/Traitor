local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Items = require(ReplicatedStorage.API.Items)

local Knife = {}

local Item = Items.CopyModify(Items.GetItem("Knife"), "Knife", {
	CreditCost = 3,
})

Knife.Item = Item

return Knife