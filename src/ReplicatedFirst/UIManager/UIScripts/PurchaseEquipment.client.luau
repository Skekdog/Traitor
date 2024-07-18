local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local LocalRoundInfo = require(ReplicatedFirst.LocalRoundInfo)
local PingRadar = require(ReplicatedFirst.PingRadar)
local Types = require(ReplicatedFirst.RoundHandler.Types)
local UIManager = require(ReplicatedFirst.UIManager)

local API = require(ReplicatedFirst.API)

local UI = UIManager.WaitForUI("Equipment Shop", true).Object :: typeof(UIManager.UnregisteredUIs["Equipment Shop"])
local purchaseButton = UI.Purchase

local radarCooldown = 5

local function update(item: string, credits: number)
	UI.CurrentCredits.Text = `You have {credits} {if credits == 1 then "credit" else "credits"}.`
	if credits >= UI.ScrollingFrame:FindFirstChild(item):GetAttribute("CreditCost") then
		UI.CreditCost.TextColor3 = Color3.new(0.294118, 1, 0.243137)
		UI.CurrentCredits.TextColor3 = Color3.new(0.294118, 1, 0.243137)
		purchaseButton.TextColor3 = Color3.fromRGB(56, 167, 31)
		purchaseButton.BackgroundColor3 = Color3.new(1, 1, 1)
	else
		UI.CreditCost.TextColor3 = Color3.fromRGB(167, 0, 0)
		UI.CurrentCredits.TextColor3 = Color3.fromRGB(167, 0, 0)
		purchaseButton.TextColor3 = Color3.fromRGB(167, 0, 0)
		purchaseButton.BackgroundColor3 = Color3.fromRGB(185, 185, 185)
	end
end

UI.Reset.Event:Connect(function()
	purchaseButton:SetAttribute("Item", "")
	UI.CreditCost.Text = ""
	UI.CurrentCredits.Text = ""
	UI.Description.Text = "Click on an item to view more information."
	UI:FindFirstChild("Name").Text = "Item"
	purchaseButton.TextColor3 = Color3.fromRGB(167, 0, 0)
end)

local function radar()
	local stop = false
	local con
	con = LocalRoundInfo.Listen("IsSpectating", function()
		stop = true
		con()
	end)
	while not stop do
		PingRadar()
		task.wait(radarCooldown)
	end
end

local function childAdded(v: Instance)
	if not v:IsA("ImageButton") then
		return
	end

	v.MouseButton1Click:Connect(function()
		purchaseButton:SetAttribute("Item", v.Name)
		local cost = v:GetAttribute("CreditCost")
		UI.CreditCost.Text = `This costs {cost} {if cost == 1 then "credit" else "credits"}.`
		UI.Description.Text = v:GetAttribute("Description")
		UI:FindFirstChild("Name").Text = v.Name
	end)
end

UI.ScrollingFrame.ChildAdded:Connect(childAdded)
for _, v in UI.ScrollingFrame:GetChildren() do
	childAdded(v)
end

local purchaseCon
type PurchaseResponse = "NoRound" | "NotInRound" | "NotFound" | "NotEnoughCredits" | "NotInStock" | "Dead"?
purchaseButton:GetAttributeChangedSignal("Item"):Connect(function()
	local item = purchaseButton:GetAttribute("Item")
	
	if item == "" then
		return
	end
	
	local creditCost = UI.ScrollingFrame:FindFirstChild(item):GetAttribute("CreditCost")

	local participant = LocalRoundInfo.GetOwnParticipant()

	if not participant then
		return
	end

	local credits = participant.Credits
	
	update(item, credits)
	
	if purchaseCon then
		purchaseCon:Disconnect()
	end
	purchaseCon = purchaseButton.MouseButton1Click:Connect(function()
		participant = LocalRoundInfo.GetOwnParticipant()
		if not participant then
			return
		end
		credits = participant.Credits
		if credits >= creditCost then
			local response: PurchaseResponse = ReplicatedStorage:WaitForChild("RoundHandler").PurchaseEquipment:InvokeServer(item)
			if response == "NoRound" then
				API.ScreenMessage("Error", "Round is not loaded.")
			elseif response == "NotInRound" then
				API.ScreenMessage("Error", "Not in round.")
			elseif response == "NotFound" then
				API.ScreenMessage("Error", "Item not found.")
			elseif response == "NotEnoughCredits" then
				API.ScreenMessage("Error", "You do not have enough credits to purchase this.")
			elseif response == "NotInStock" then
				API.ScreenMessage("Error", "You have purchased the maximum amount of this item.")
			elseif response == "Dead" then
				API.ScreenMessage("Error", "You are dead.")
			elseif response == "SlotInUse" then
				API.ScreenMessage("Error", "This slot is already being used.")
			end
		end
	end)
end);

LocalRoundInfo.Listen("UpdateOwnParticipant", function(participant: Types.ClientOwnParticipant?)
	local item = purchaseButton:GetAttribute("Item")
	if item == "" then
		return
	end
	update(item, if participant then participant.Credits else 0)
end)

ReplicatedStorage:WaitForChild("RoundHandler").InformClientSideEquipment.OnClientEvent:Connect(function(item)
	if item == "Radar" then
		radar()
	end
end)
