local RS = game:GetService("ReplicatedStorage")
local RF = game:GetService("ReplicatedFirst")

local UIManager = require(RF.UIManager)

local roundInfo = RS.ClientServer.GetRoundInfo
local API = require(RF.API)

local plr = game:GetService("Players").LocalPlayer

local frame = script.Parent
local purchaseButton = frame.Purchase

local UI = UIManager.GetUI("Equipment Shop").UI

local radarCooldown = 5

local function update(item,credits)
	frame.CurrentCredits.Text = "You have "..tostring(credits).." credit(s)."
	if credits >= frame.ScrollingFrame:FindFirstChild(item):GetAttribute("CreditCost") then
		frame.CreditCost.TextColor3 = Color3.new(0.294118,1,0.243137)
		frame.CurrentCredits.TextColor3 = Color3.new(0.294118,1,0.243137)
		purchaseButton.TextColor3 = Color3.fromRGB(56,167,31)
		purchaseButton.BackgroundColor3 = Color3.new(1,1,1)
	else
		frame.CreditCost.TextColor3 = Color3.fromRGB(167,0,0)
		frame.CurrentCredits.TextColor3 = Color3.fromRGB(167,0,0)
		purchaseButton.TextColor3 = Color3.fromRGB(167,0,0)
		purchaseButton.BackgroundColor3 = Color3.fromRGB(185,185,185)
	end
end

UI.Reset.Event:Connect(function()
	purchaseButton:SetAttribute("Item", "")
	frame.CreditCost.Text = ""
	frame.CurrentCredits.Text = ""
	frame.Description.Text = "Click on an item to view more information."
	frame:FindFirstChild("Name").Text = "Item"
	purchaseButton.TextColor3 = Color3.fromRGB(167, 0, 0)
end)

local scriptCons = game:WaitForChild("ClientStorage"):WaitForChild("ScriptConnections")
local function radar()
	local roundId = plr:GetAttribute("CurrentRoundID")
	while roundId == plr:GetAttribute("CurrentRoundID") do
		scriptCons.PingRadarEvent:Fire()
		task.wait(radarCooldown)
	end
end

UI.ScrollingFrame.ChildAdded:Connect(function(v)
	if v:IsA("ImageButton") then
		v.MouseButton1Click:Connect(function()
			purchaseButton:SetAttribute("Item",v.Name)
			frame.CreditCost.Text = "This costs "..tostring(v:GetAttribute("CreditCost")).." credit(s)."
			frame.Description.Text = v:GetAttribute("Description")
			frame:FindFirstChild("Name").Text = v.Name
		end)
	end
end)

local purchaseCon
purchaseButton:GetAttributeChangedSignal("Item"):Connect(function()
	local item = purchaseButton:GetAttribute("Item")
	
	if item == "" then
		return
	end
	
	local creditCost = frame.ScrollingFrame:FindFirstChild(item):GetAttribute("CreditCost")
	local credits = roundInfo:InvokeServer(plr:GetAttribute("CurrentRound"),"Self").PlayerInfo.Credits
	
	update(item,credits)
	
	if purchaseCon then purchaseCon:Disconnect() end
	purchaseCon = purchaseButton.MouseButton1Click:Connect(function()
		if credits >= creditCost then
			local response = RS.ClientServer.PurchaseEquipment:InvokeServer(item)
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
		update(item,roundInfo:InvokeServer(plr:GetAttribute("CurrentRound"),"Self").PlayerInfo.Credits)
	end)
end)

RS:WaitForChild("ServerClient").InformClientSideEquipment.OnClientEvent:Connect(function(item)
	if item == "Radar" then
		radar()
	end
end)
