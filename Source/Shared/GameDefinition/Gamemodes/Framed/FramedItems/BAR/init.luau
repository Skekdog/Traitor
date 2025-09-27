local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Items = require(ReplicatedStorage.API.StandardGame)

local BAR = {}

local Item = Items.CopyModify(Items.GetItem("BAR"), "BAR", {
	CreditCost = 2,
})

BAR.Item = Item

return BAR