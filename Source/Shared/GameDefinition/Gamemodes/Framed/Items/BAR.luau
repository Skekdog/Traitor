local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modify = require(ReplicatedStorage.API.Modify)
local Items = require(ReplicatedStorage.API.StandardGame)

local BAR = {}

local Item = Modify(Items.GetItem("BAR"), "BAR", {
	Cost = 2,
})

BAR.Item = Item

return table.freeze(BAR)