local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)

local participant = LocalParticipantInfo.GetParticipant()

local function highlightProp(prop: Instance): ()
	assert(prop:IsA("BasePart") or prop:IsA("Model"))

	local id = prop:GetAttribute("PossessedBy")
	local player: Player?
	if typeof(id) == "number" then
		player = Players:GetPlayerByUserId(id)
	end

	if not player or player == Players.LocalPlayer then
		return
	end

	local highlight = prop:FindFirstChild("PossessedPropHighlight")
	if not highlight then
		local newHighlight = Instance.new("Highlight")
		newHighlight.FillColor = Color3.fromRGB(246, 174, 18)
		newHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		newHighlight.Name = "PossessedPropHighlight"
		newHighlight.Parent = prop
		highlight = newHighlight
	end

	assert(highlight and highlight:IsA("Highlight"))
	highlight.Enabled = true

	local namePlate = prop:FindFirstChild("PossessedPropNameplate")
	if not namePlate then
		local newBillboard = Instance.new("BillboardGui")
		newBillboard.Size = UDim2.fromScale(2, 1)
		newBillboard.Name = "PossessedPropNameplate"
		newBillboard.AlwaysOnTop = true

		local size = if prop:IsA("BasePart") then prop.Size else prop:GetExtentsSize()

		newBillboard.StudsOffset = Vector3.new(0, size.Y + 0.1, 0)
		newBillboard.Adornee = GetPrimaryPart(prop)

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Font = Enum.Font.BuilderSansBold
		label.TextStrokeTransparency = 0
		label.TextStrokeColor3 = Color3.new(0, 0, 0)
		label.TextScaled = true
		label.Text = player.Name
		label.Parent = newBillboard

		newBillboard.Parent = prop
		namePlate = newBillboard
	end

	assert(namePlate and namePlate:IsA("BillboardGui"))
	namePlate.Enabled = true
end

local function unhighlightProp(prop: Instance): ()
	local highlight = prop:FindFirstChild("PossessedPropHighlight")
	if highlight and highlight:IsA("Highlight") then
		highlight.Enabled = false
	end

	local namePlate = prop:FindFirstChild("PossessedPropNameplate")
	if namePlate and namePlate:IsA("BillboardGui") then
		namePlate.Enabled = false
	end
end

local function highlightProps(): ()
	for _, prop in CollectionService:GetTagged("Possessed") do
		highlightProp(prop)
	end
end

local function unhighlightProps(): ()
	for _, prop in CollectionService:GetTagged("Possessed") do
		unhighlightProp(prop)
	end
end

participant.Status:Connect(function(status)
	if status == "Alive" then
		unhighlightProps()
		return
	end

	highlightProps()
end, true)

CollectionService:GetInstanceAddedSignal("Possessed"):Connect(function(prop)
	if participant.Status() ~= "Alive" then
		highlightProp(prop)
	end
end)

CollectionService:GetInstanceRemovedSignal("Possessed"):Connect(function(prop)
	if participant.Status() ~= "Alive" then
		unhighlightProp(prop)
	end
end)

return nil