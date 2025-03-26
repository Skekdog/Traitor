local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalRoundInfo = require(ReplicatedStorage.LocalRoundInfo)
local GetDisplayName = require(ReplicatedStorage.RoundRule.Common.GetDisplayName)
local Types = require(ReplicatedStorage.RoundRule.Types)
local ScreenMessage = require(ReplicatedStorage.ScreenMessage)
local UIManager = require(ReplicatedStorage.UIManager)

local goodColour = Color3.new(0.294118, 1, 0.243137)
local badColour = Color3.fromRGB(167, 0, 0)

local selectedItem: Types.AnyItemDefinition?

local isPurchaseConnected: boolean = false

local function updateCredits(ui: ShopUI?, requiredCredits: number?): ()
    ui = ui or UIManager.TryGetUI("Equipment Shop") :: ShopUI?
    if ui then
        local credits = LocalRoundInfo.GetCredits()
        ui.Object.CurrentCredits.Text = `You have {credits} {if credits == 1 then "credit" else "credits"}.`
        ui.Object.CurrentCredits.TextColor3 = if credits >= (requiredCredits or 0) then goodColour else badColour
        ui.Object.Purchase.TextColor3 = if requiredCredits and credits >= requiredCredits then goodColour else badColour
        ui.Object.CreditCost.TextColor3 = if LocalRoundInfo.GetCredits() >= (requiredCredits or 0) then goodColour else badColour
    end
end

type ShopUI = UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs["Equipment Shop"])}
local function selectItem(ui: ShopUI, item: Types.AnyItemDefinition?): ()
    selectedItem = item
    if not item then
        ui.Object.Description.Text = "Click on an item to view more information."
        ui.Object.ItemName.Text = "Item Name"

        ui.Object.CreditCost.Visible = false
        return
    end
    ui.Object.Description.Text = item.Description or ""
    ui.Object.ItemName.Text = GetDisplayName(item)

    ui.Object.CreditCost.Visible = true
    ui.Object.CreditCost.Text = `This costs {item.CreditCost} {if item.CreditCost == 1 then "credit" else "credits"}.`

    selectedItem = item

    updateCredits(ui, item.CreditCost)
end

local function errorMessage(message: string): ()
    ScreenMessage("Error", message)
end

local function notEnoughCredits(): ()
    errorMessage("You don't have enough credits to buy this.")
end

local function tryPurchase(): ()
    if not selectedItem then
        return
    end

    if LocalRoundInfo.GetCredits() < (selectedItem.CreditCost or 0) then
        return notEnoughCredits()
    end

    local response: Types.ItemPurchaseResult = ReplicatedStorage.RoundRule.Remotes.PurchaseItem:InvokeServer(selectedItem.Name)
    if response == "NotEnoughCredits" then
        notEnoughCredits()
    elseif response == "NotInStock" then
        errorMessage("This item is out of stock.")
    elseif response == "SlotOccupied" then
        errorMessage(`You already have an item in slot {selectedItem.Slot}.`)
    elseif response == "NotInRound" then
        errorMessage("You are dead.")
    elseif response ~= "Success" then
        errorMessage("An unknown error occurred.")
    end

    local ui = UIManager.TryGetUI("Equipment Shop") :: ShopUI?
    if ui then
        selectItem(ui, selectedItem)
    end
end

local function tryPopulateEquipment(role: Types.Role?): ()
    local ui = (UIManager.TryGetUI("Equipment Shop") or UIManager.RegisterUI(UIManager.UnregisteredUIs["Equipment Shop"])) :: ShopUI
    if not isPurchaseConnected then
        isPurchaseConnected = true
        ui.Object.Purchase.Activated:Connect(tryPurchase)
    end

    selectItem(ui, nil)

    if not role or not role.Definition.EquipmentShop then
        if ui then
            ui:Unregister()
        end
        return
    end

    updateCredits(ui)

    local list = ui.Object.ScrollingFrame

    for _, v in list:GetChildren() do
        if v:IsA("GuiButton") then
            v:Destroy()
        end
    end

    for _, v in role.Definition.EquipmentShop do
        assert(v.CreditCost and v.Icon and v.Description, `Equipment {v.Name} is missing an icon, cost or description.`)

        local button = ui.Object.EquipmentEntry:Clone()
        button.Name = v.Name
        button.Image = v.Icon or ""

        button.TextLabel.Text = if v.Slot then `[{v.Slot}]` else ""
        button.TextLabel.Visible = not not v.Slot

        button.Visible = true
        button.Parent = list :: any

        button.Activated:Connect(function()
            selectItem(ui, v)
        end)
    end
end

local lastRole: Types.Role?
LocalRoundInfo.Listen("PlayerRole", function()
    local role = LocalRoundInfo.GetPlayerRole(Players.LocalPlayer.Name)
    if lastRole ~= role then
        lastRole = role
        tryPopulateEquipment(role)
    end
end)

LocalRoundInfo.Listen("Credits", updateCredits)
