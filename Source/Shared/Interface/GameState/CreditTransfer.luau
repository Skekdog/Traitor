local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScreenMessage = require(ReplicatedStorage.API.ScreenMessage)
local Plural = require(ReplicatedStorage.Shared.Grammar.Plural)
local EquipmentMenu = require(ReplicatedStorage.Shared.Interface.EquipmentMenu)
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local IsBadNumber = require(ReplicatedStorage.Shared.Util.IsBadNumber)

local page = ReplicatedStorage.Assets.EquipmentPages.CreditTransfer

EquipmentMenu.AddPage(page)

local amountBox = page.Amount.TextBox

local ownParticipant = LocalParticipantInfo.GetParticipant()

amountBox.FocusLost:Connect(function()
	local amount = tonumber(amountBox.Text)
	if not amount then
		amount = 0
	end
	assert(amount)

	if amount < 0 or IsBadNumber(amount) then
		amount = 0
	end

	amount = math.floor(amount)

	amountBox.Text = tostring(amount)
end)

local buttons: {[LocalParticipantInfo.LocalParticipant]: TextButton?} = {}
local function tryAddPlayerButton(participant: LocalParticipantInfo.LocalParticipant): ()
	if buttons[participant] then
		return
	end

	page.NoAllies.Visible = false

	local button = page.Players.PlayerButton:Clone()

	button.Name = participant.Name
	button.Text = participant.Name
	button.Visible = true
	button.Parent = page.Players

	button.Activated:Connect(function()
		local amount = tonumber(amountBox.Text)
		if not amount then
			return
		end

		if amount > LocalRoundInfo.Credits() then
			return ScreenMessage("You don't have enough credits.", "Error")
		end

		if ownParticipant.Status() ~= "Alive" then
			return ScreenMessage("You are dead.", "Error")
		end

		ReplicatedStorage.Remotes.ClientServer.TransferCredits:FireServer(participant.Name, amount)
	end)

	buttons[participant] = button
end

local function tryRemovePlayerButton(participant: LocalParticipantInfo.LocalParticipant): ()
	local button = buttons[participant]
	if button then
		button:Destroy()
		buttons[participant] = nil

		local count = 0
		for _ in buttons do
			count += 1
		end

		page.NoAllies.Visible = count == 0
	end
end

local function updateButton(participant: LocalParticipantInfo.LocalParticipant): ()
	local role = participant.Role()
	local isAlive = participant.Status() == "Alive"
	if isAlive and role:IsAlliedWith(ownParticipant.Role()) then
		tryAddPlayerButton(participant)
	else
		tryRemovePlayerButton(participant)
	end
end

LocalParticipantInfo.Participants:Connect(function(participants: {[string]: LocalParticipantInfo.LocalParticipant})
	local foundParticipants: {LocalParticipantInfo.LocalParticipant} = {}
	for _, participant in participants do
		if participant == ownParticipant then
			continue
		end

		participant.Role:Connect(function()
			updateButton(participant)
		end, true)

		participant.Status:Connect(function()
			updateButton(participant)
		end, true)
	end

	for participant in buttons do
		if not table.find(foundParticipants, participant) then
			tryRemovePlayerButton(participant)
		end
	end
end, true)

LocalRoundInfo.Credits:Connect(function(credits)
	page.CreditsLabel.Text = "You have " .. credits .. Plural(credits, " credit.", " credits.")
end, true)

return nil