local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local Modify = require(ReplicatedStorage.API.Modify)
local StandardGame = require(ReplicatedStorage.API.StandardGame)
local Types = require(ReplicatedStorage.API.Types)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local CreateEmptyPart = require(ReplicatedStorage.Shared.RoundRule.Common.CreateEmptyPart)
local IsValidProp = require(ReplicatedStorage.Shared.GameDefinition.Gamemodes.PropHunt.IsValidProp)

local Propper = {}

local DEFAULT_HEALTH = 50

local remote = GetRemote("ThirdPerson", script)

local function beforeHitProp(item: Types.Item, params: Types.DamageParams, prop: Types.Prop): boolean
	if prop.Interactable then
		return false
	end

	if not IsValidProp(prop.Model) then
		return false
	end

	local participant = params.Attacker
	assert(participant)

	local character = participant:GetCharacter()
	assert(character)

	local charRoot = character.PrimaryPart
	if not charRoot then
		return false
	end

	if charRoot:GetAttribute("PropName") == prop.Model.Name then
		return false
	end

	local morph = Instance.new("Model")
	morph:SetAttribute("IsDisguised", true)

	local oldHumanoid = participant:GetHumanoid()

	local humanoid = Instance.new("Humanoid")
	humanoid.RequiresNeck = false
	humanoid.RigType = Enum.HumanoidRigType.R6
	humanoid.Parent = morph

	local model = prop.Model:Clone()
	model:RemoveTag("Prop")
	local root = GetPrimaryPart(model)

	for _, part in model:GetChildren() do
		part.Parent = morph
	end

	local head = CreateEmptyPart(root.CFrame)
	head.Anchored = false
	head.Name = "Head"

	local weld = Instance.new("Weld")
	weld.Part0 = root
	weld.Part1 = head
	weld.Parent = head

	head.Parent = morph

	root:SetAttribute("PropName", model.Name)
	root.Name = "HumanoidRootPart"
	morph.PrimaryPart = root

	local charHead = character:FindFirstChild("Head")
	if not charHead or not charHead:IsA("BasePart") then
		return false
	end

	local propSize = if prop.Model:IsA("Model") then prop.Model:GetExtentsSize() else prop.Model.Size
	morph:PivotTo(charHead:GetPivot() * CFrame.new(Vector3.new(0, propSize.Y, 0)))

	root.Parent = morph -- ?? flipping silly nonsense, apparently the parent doesn't get set by the for loop above ?????? what the flip???
	participant:SpawnCharacter(morph, true)

	local health = prop:GetHealth() or DEFAULT_HEALTH

	if oldHumanoid then
		local percent = oldHumanoid.Health / oldHumanoid.MaxHealth
		humanoid.Health = health * percent
	else
		humanoid.Health = math.min(health, participant:GetHealth())
	end

	humanoid.CameraOffset = Vector3.new(0, -1.5, 0)
	humanoid.MaxHealth = health

	morph.Parent = workspace.Characters
	root:SetNetworkOwner(participant.Player)

	if not participant.Extras.PropperCharacterChangedSignal then
		participant.Extras.PropperCharacterChangedSignal = participant.Player:GetPropertyChangedSignal("Character"):Once(function()
			remote:FireClient(participant.Player, false)
			participant.Extras.PropperCharacterChangedSignal = nil
		end)
	end

	remote:FireClient(participant.Player, true)

	return false
end

if RunService:IsClient() then
	local Camera = require(ReplicatedStorage.API.Camera)
	local Crouch = require(ReplicatedStorage.Shared.Actions.Crouch)

	remote.OnClientEvent:Connect(function(doThirdPerson: boolean): ()
		Crouch.SetCrouchDisabled("PropMorph", doThirdPerson)
		if doThirdPerson then
			Camera.EnterThirdPerson(10)
		end
	end)
end

local Item = Modify(StandardGame.GetItem("Crowbar"), "Propper", {
	Description = "Become a prop",
	BeforeHitProp = beforeHitProp,

	AlternateFireClient = {__nil = true},
	AlternateFireServer = {__nil = true},
})

Propper.Item = Item

return table.freeze(Propper)