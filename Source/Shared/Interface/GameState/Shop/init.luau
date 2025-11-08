local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScreenMessage = require(ReplicatedStorage.API.ScreenMessage)
local Plural = require(ReplicatedStorage.Shared.Grammar.Plural)
local EquipmentMenu = require(ReplicatedStorage.Shared.Interface.EquipmentMenu)
local ClientInventory = require(ReplicatedStorage.Shared.LocalState.ClientInventory)
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local GetDisplayName = require(ReplicatedStorage.Shared.RoundRule.Common.GetDisplayName)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local COLOUR_GOOD = Color3.fromRGB(75, 255, 62)
local COLOUR_BAD = Color3.fromRGB(167, 0, 0)

local selectedItem: Types.AnyItemDefinition?

local purchases: {[Types.AnyItemDefinition]: number?} = {}

local shopPage = script.Shop

local function updateName(): ()
	shopPage.ItemName.Text = if selectedItem then GetDisplayName(selectedItem) else "Item Name"
end

local function updateDescription(): ()
	shopPage.Description.Text = if selectedItem then selectedItem.Description or "" else "Click on an item to view more information."
end

local function updateStock(): boolean
	if selectedItem and selectedItem.MaxStock then
		local purchasedAmount = purchases[selectedItem] or 0

		local inStock = purchasedAmount < selectedItem.MaxStock
		shopPage.Data.InStock.Text = if inStock then "This is in stock." else "This is out of stock."
		shopPage.Data.InStock.TextColor3 = if inStock then COLOUR_GOOD else COLOUR_BAD

		return inStock
	else
		shopPage.Data.InStock.Text = ""
		return true
	end
end

local function updateCredits(): boolean
	local credits = LocalRoundInfo.Credits()

	shopPage.Data.CurrentCredits.Text = "You have " .. credits .. Plural(credits, " credit", " credits") .. "."
	shopPage.Data.CurrentCredits.TextColor3 = COLOUR_GOOD

	if selectedItem and selectedItem.CreditCost then
		local canAfford = selectedItem.CreditCost <= credits

		shopPage.Data.CreditCost.Text = "This costs " .. selectedItem.CreditCost .. " credits."
		shopPage.Data.CreditCost.TextColor3 = if canAfford then COLOUR_GOOD else COLOUR_BAD

		shopPage.Data.CurrentCredits.TextColor3 = if canAfford then COLOUR_GOOD else COLOUR_BAD

		return canAfford
	else
		shopPage.Data.CreditCost.Text = ""
		return true
	end
end

local function updateSlot(): boolean
	local gamemode = LocalRoundInfo.Gamemode() or error("Gamemode is not loaded")
	if gamemode.IsSlotless or not selectedItem or not selectedItem.ItemGroup or not selectedItem.ItemGroup.PreferredSlot then
		shopPage.Data.SlotOccupied.Text = ""
		return true
	end

	local isOccupied = ClientInventory.Inventory.Slots()[selectedItem.ItemGroup.PreferredSlot] ~= nil

	shopPage.Data.SlotOccupied.Text = if isOccupied then "This slot is occupied." else "This slot is available."
	shopPage.Data.SlotOccupied.TextColor3 = if isOccupied then COLOUR_BAD else COLOUR_GOOD

	return not isOccupied
end

local function purchaseAllowed(): boolean
	local inStock = updateStock()
	local canAfford = updateCredits()
	local slotAvailable = updateSlot()

	local allowed = if selectedItem and inStock and canAfford and slotAvailable then true else false
	shopPage.Purchase.TextColor3 = if allowed then COLOUR_GOOD else COLOUR_BAD

	return allowed
end

local function selectItem(item: Types.AnyItemDefinition?): ()
	selectedItem = item

	updateName()
	updateDescription()

	purchaseAllowed()
end

local function populateShop(role: Types.Role): ()
	local list = shopPage.ScrollHolder.ScrollingFrame

	for _, child in list:GetChildren() do
		if child:IsA("GuiButton") then
			child:Destroy()
		end
	end

	selectItem()

	if role.Definition.EquipmentShop then
		local gamemode = LocalRoundInfo.Gamemode() or error("Gamemode is not loaded")
		for _, definition in role.Definition.EquipmentShop do
			assert(definition.CreditCost, "missing credit cost for " .. definition.Name)
			assert(definition.Description, "missing description for " .. definition.Name)
			assert(definition.Icon, "missing icon for " .. definition.Name)

			local button = shopPage.EquipmentEntry:Clone()
			button.Name = "Equipment_" .. definition.Name
			button.Image = definition.Icon

			button.ResampleMode = if definition.IsPixelIcon then Enum.ResamplerMode.Pixelated else Enum.ResamplerMode.Default

			button.TextLabel.Text = if not gamemode.IsSlotless and definition.ItemGroup and definition.ItemGroup.PreferredSlot then `[{definition.ItemGroup.PreferredSlot}]` else ""
			button.TextLabel.Visible = true

			button.Visible = true
			button.Parent = list :: any

			button.Activated:Connect(function()
				selectItem(definition)
			end)
		end
	end
end

local lastRole: Types.Role? = nil
LocalParticipantInfo.GetParticipant().Role:Connect(function(role)
	if role ~= lastRole or role == nil then
		lastRole = role
		purchases = {}
		populateShop(role)
	end
end, true)

LocalRoundInfo.Credits:Connect(purchaseAllowed)

ClientInventory.Inventory.Slots:Connect(purchaseAllowed)

local function errorMessage(message: string): ()
    ScreenMessage(message, "Error")
end

shopPage.Purchase.Activated:Connect(function()
	local item = selectedItem
	if not item or not purchaseAllowed() then
		return
	end

	local response: Types.ItemPurchaseResult = ReplicatedStorage.Shared.RoundRule.Remotes.PurchaseItem:InvokeServer(item.Name)
    if response == "NotEnoughCredits" then
        errorMessage("You don't have enough credits to buy this.")
    elseif response == "NotInStock" then
        errorMessage("This item is out of stock.")
    elseif response == "SlotOccupied" then
        errorMessage(`You already have an item of this type.`)
    elseif response == "NotInRound" then
        errorMessage("You are dead.")
    elseif response ~= "Success" then
        errorMessage("An unknown error occurred.")
	end

	if response == "Success" then
		purchases[item] = (purchases[item] or 0) + 1
	end
end)

EquipmentMenu.AddPage(shopPage)

return nil