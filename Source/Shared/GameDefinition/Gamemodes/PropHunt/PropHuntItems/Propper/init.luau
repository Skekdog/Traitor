local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local Modify = require(ReplicatedStorage.API.Modify)
local StandardGame = require(ReplicatedStorage.API.StandardGame)
local Types = require(ReplicatedStorage.API.Types)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local CreateEmptyPart = require(ReplicatedStorage.Shared.RoundRule.Common.CreateEmptyPart)

local Propper = {}

local remote = GetRemote("ThirdPerson", script)

local function beforeHitProp(item: Types.Item, params: Types.DamageParams, prop: Types.Prop): boolean
	if prop.Interactable then
		return false
	end

	if GetPrimaryPart(prop.Model):IsGrounded() then
		return false
	end

	local participant = params.Attacker
	assert(participant)

	local morph = Instance.new("Model")

	local humanoid = Instance.new("Humanoid")
	humanoid.RequiresNeck = false
	humanoid.RigType = Enum.HumanoidRigType.R6
	humanoid.Parent = morph

	local model = prop.Model:Clone()
	local root = GetPrimaryPart(model)

	for _, part in model:GetChildren() do
		part.Parent = morph
	end

	local head = CreateEmptyPart(root.CFrame)
	head.Anchored = false
	head.Name = "Head"

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = head
	weld.Parent = head

	head.Parent = morph

	root.Name = "HumanoidRootPart"
	morph.PrimaryPart = root

	local character = participant:GetCharacter()
	assert(character)

	local charHead = character:FindFirstChild("Head")
	if not charHead or not charHead:IsA("BasePart") then
		return false
	end

	morph:PivotTo(charHead:GetPivot())

	participant:SpawnCharacter(morph, true)

	root:SetNetworkOwner(participant.Player)

	remote:FireClient(participant.Player, true)

	return false
end

if RunService:IsClient() then
	local Camera = require(ReplicatedStorage.API.Camera)
	remote.OnClientEvent:Connect(function(doThirdPerson: boolean): ()
		Camera.EnterAnimationView()
	end)
end

local Item = Modify(StandardGame.GetItem("Crowbar"), "Propper", {
	Description = "Become a prop",
	BeforeHitProp = beforeHitProp,

	AlternateFireClient = {__nil = true},
	AlternateFireServer = {__nil = true},
})

Propper.Item = Item

return Propper