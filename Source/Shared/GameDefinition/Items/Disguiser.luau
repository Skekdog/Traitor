local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local ShowAlert = require(ReplicatedStorage.Shared.Interface.Util.ShowAlert)
local Participant = require(ReplicatedStorage.Shared.RoundRule.Participant)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local module = {}

local DISGUISED_SKIN_TONE = Color3.new(1, 1, 1)
local DISGUISED_SHIRT = 855773572
local DISGUISED_PANTS = 867838635

local DISGUISED_DESCRIPTION = Instance.new("HumanoidDescription")

DISGUISED_DESCRIPTION.HeadColor = DISGUISED_SKIN_TONE
DISGUISED_DESCRIPTION.LeftArmColor = DISGUISED_SKIN_TONE
DISGUISED_DESCRIPTION.RightArmColor = DISGUISED_SKIN_TONE
DISGUISED_DESCRIPTION.LeftLegColor = DISGUISED_SKIN_TONE
DISGUISED_DESCRIPTION.RightLegColor = DISGUISED_SKIN_TONE
DISGUISED_DESCRIPTION.TorsoColor = DISGUISED_SKIN_TONE

DISGUISED_DESCRIPTION.Shirt = DISGUISED_SHIRT
DISGUISED_DESCRIPTION.Pants = DISGUISED_PANTS

type ParticipantData = {
	Participant: Types.Participant,
	HumanoidDescription: HumanoidDescription?,
}

local serverParticipantTable: {[Player]: ParticipantData?} = {}

local remote: RemoteEvent
if RunService:IsServer() then
	remote = Instance.new("RemoteEvent")
	remote.Name = "Disguise"
	remote.Parent = script
else
	local found = script:WaitForChild("Disguise")
	assert(found:IsA("RemoteEvent"), "Disguise must be a RemoteEvent")
	remote = found
end

local clientDisguiseActive = false

function module.DisguiseServer(participantData: ParticipantData, enable: boolean?, char: Model?, hum: Humanoid?, applyReset: boolean?): ()
	local participant = participantData.Participant

	-- this is to prevent an error in studio when stopping the game.
	if not participant.Player.Parent then
		return
	end

	enable = if enable == nil then not participant.Player:GetAttribute("IsDisguised") else enable
	if participant.Player:GetAttribute("IsDisguised") == enable then
		return
	end
	participant.Player:SetAttribute("IsDisguised", enable)

	hum = hum or participant:GetHumanoid()
	if not hum then
		return
	end

	char = char or participant:GetCharacter()
	if not char then
		return
	end

	hum.ApplyDescriptionFinished:Once(function()
		local item = char:FindFirstChild("Item")
		if item then
			local motor = item:FindFirstChildOfClass("Motor6D")
			if motor then
				local hand = char:FindFirstChild("RightHand")
				if hand and hand:IsA("BasePart") then
					motor.Part0 = hand
				end
			end
		end

		for _, v in char:GetDescendants() do
			Participant.OnCharacterPartAdded(v)
		end
	end)

	if enable then
		if not participantData.HumanoidDescription then
			-- We only set it once. This is because if a player spams the disguiser, they will end up with the description just being the disguise description. Bad!
			participantData.HumanoidDescription = hum:GetAppliedDescription()
		end
		if applyReset then
			hum:ApplyDescriptionReset(DISGUISED_DESCRIPTION, Enum.AssetTypeVerification.Always)
		else
			hum:ApplyDescription(DISGUISED_DESCRIPTION, Enum.AssetTypeVerification.Always)
		end
	elseif participantData.HumanoidDescription then
		if applyReset then
			hum:ApplyDescriptionReset(participantData.HumanoidDescription, Enum.AssetTypeVerification.Always)
		else
			hum:ApplyDescription(participantData.HumanoidDescription, Enum.AssetTypeVerification.Always)
		end
	end
end

if RunService:IsServer() then
	remote.OnServerEvent:Connect(function(player, enable: unknown)
		if typeof(enable) ~= "boolean" then
			return
		end

		local participantData = serverParticipantTable[player]
		if not participantData then
			return
		end

		local participant = participantData.Participant

		local found = false
		for _, v in participant:GetItems() do
			assert(v)
			if v.Definition.Name == "Disguiser" then
				found = true
				break
			end
		end

		if not found then
			return
		end

		module.DisguiseServer(participantData, enable)
	end)
end

local function OnEquipClient(item: Types.AnyItem): ()
	ControlManager.Register("Disguise", function(_, state)
		clientDisguiseActive = not clientDisguiseActive
		ShowAlert("Disguise: " .. if clientDisguiseActive then "ON" else "OFF")
		remote:FireServer(clientDisguiseActive)

		return Enum.ContextActionResult.Sink
	end, nil, {
		Toggled = true,
		Keybind = {
			ConsoleKeybind = Enum.KeyCode.ButtonR1,
			KBMKeybind = Enum.KeyCode.Semicolon,
		},
		TouchButton = {
			Position = UDim2.fromOffset(50, 250),
			Scale = 1,
		}
	})
end

local function OnEquipServer(item: Types.AnyItem, participant: Types.Participant): ()
	serverParticipantTable[participant.Player] = {
		Participant = participant,
	}
end

local function OnUnequipClient(item: Types.AnyItem): ()
	clientDisguiseActive = false
	ControlManager.Unregister("Disguise")
end

local function OnUnequipServer(item: Types.AnyItem, participant: Types.Participant): ()
	local data = serverParticipantTable[participant.Player]
	if not data then
		return
	end
	module.DisguiseServer(data, false)
	serverParticipantTable[participant.Player] = nil
end

local item: Types.ItemDefinition = {
	Kind = "Item" :: "Item",

	Name = "Disguiser",
	Description = "Conceals your identity from others. Use semicolon to activate.",
	Icon = "rbxassetid://107291373883291",

	CreditCost = 1,
	MaxStock = 1,

	OnEquipClient = OnEquipClient,
	OnEquipServer = OnEquipServer,

	OnUnequipClient = OnUnequipClient,
	OnUnequipServer = OnUnequipServer,
}

module.Item = item

return module