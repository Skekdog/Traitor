local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modify = require(ReplicatedStorage.API.Modify)
local Items = require(ReplicatedStorage.API.StandardGame)

local Knife = {}

local Item = Modify(Items.GetItem("Knife"), "Knife", {
	Cost = 3,
})

Knife.Item = Item

return Knife