local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local UIManager = require(ReplicatedFirst.UIManager)

local getOwnInfo = ReplicatedStorage.RoundHandler.GetOwnInfo
local API = require(ReplicatedFirst.API)
local RoundHandlerTypes = require(ReplicatedFirst.RoundHandlerTypes)

local UI = UIManager.WaitForUI("Equipment Shop", true).UI
local purchaseButton = UI.Purchase

local radarCooldown = 5

local function update(item, credits)
	UI.CurrentCredits.Text = "You have "..tostring(credits).." credit(s)."
	if credits >= UI.ScrollingUI:FindFirstChild(item):GetAttribute("CreditCost") then
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

local clientStorage = game:WaitForChild("ClientStorage")
local scriptCons = clientStorage:WaitForChild("ScriptConnections")
local function radar()
	local stop = false
	clientStorage:GetAttributeChangedSignal("IsSpectating"):Once(function()
		stop = true
	end)
	while not stop do
		scriptCons.PingRadarEvent:Fire()
		task.wait(radarCooldown)
	end
end

UI.ScrollingFrame.ChildAdded:Connect(function(v)
	if v:IsA("ImageButton") then
		v.MouseButton1Click:Connect(function()
			purchaseButton:SetAttribute("Item", v.Name)
			UI.CreditCost.Text = "This costs "..tostring(v:GetAttribute("CreditCost")).." credit(s)."
			UI.Description.Text = v:GetAttribute("Description")
			UI:FindFirstChild("Name").Text = v.Name
		end)
	end
end)

local purchaseCon
purchaseButton:GetAttributeChangedSignal("Item"):Connect(function()
	local item = purchaseButton:GetAttribute("Item")
	
	if item == "" then
		return
	end
	
	local creditCost = UI.ScrollingUI:FindFirstChild(item):GetAttribute("CreditCost")

	local participant: RoundHandlerTypes.Participant? = getOwnInfo:InvokeServer()

	if not participant then return end

	local credits = participant.Credits
	
	update(item, credits)
	
	if purchaseCon then purchaseCon:Disconnect() end
	purchaseCon = purchaseButton.MouseButton1Click:Connect(function()
		if credits >= creditCost then
			local response = ReplicatedStorage.ClientServer.PurchaseEquipment:InvokeServer(item)
			if response == "ItemError" then
				API.ScreenMessage("Error", "Equipment not found on server")
			elseif response == "CreditError" then
				API.ScreenMessage("Error", "You don't have enough credits for this")
			elseif response == "MaxOwnedError" then
				API.ScreenMessage("Error", "You already have the maximum amount of this")
			elseif response == "SlotError" then
				API.ScreenMessage("Error", "Required slot is in use")
			elseif response == "Success" then
				if item == "Radar" then
					radar()
				end
			end
		end
		update(item, participant.Credits)
	end)
end)

ReplicatedStorage:WaitForChild("ServerClient").InformClientSideEquipment.OnClientEvent:Connect(function(item)
	if item == "Radar" then
		radar()
	end
end)
