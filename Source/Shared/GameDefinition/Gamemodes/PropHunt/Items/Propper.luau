local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local Modify = require(ReplicatedStorage.API.Modify)
local StandardGame = require(ReplicatedStorage.API.StandardGame)
local Types = require(ReplicatedStorage.API.Types)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local IsValidProp = require(ReplicatedStorage.Shared.GameDefinition.Gamemodes.PropHunt.IsValidProp)
local ForEachPart = require(ReplicatedStorage.Shared.RoundRule.Common.ForEachPart)

local Propper = {}

local DEFAULT_HEALTH = 50

local remote = GetRemote("ThirdPerson", script)

local COLLISION_GROUP = "PropHuntPropCollisions"

if RunService:IsServer() then
	PhysicsService:RegisterCollisionGroup(COLLISION_GROUP)
	PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUP, "Default", false)
	PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUP, "PlayerCharacterParts", true)
end

local function beforeHitProp(item: Types.Item, params: Types.DamageParams, prop: Types.Prop, ...): boolean
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

	if character:GetAttribute("PropName") == prop.Model.Name then
		return false
	end

	local morph = Instance.new("Model")
	morph:SetAttribute("IsDisguised", true)

	local oldHumanoid = participant:GetHumanoid()

	local model = prop.Model:Clone()
	model:RemoveTag("Prop")

	local root = Instance.new("Part")
	root.Transparency = 1
	root.Name = "HumanoidRootPart"

	local humanoid = Instance.new("Humanoid")
	humanoid.RequiresNeck = false
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.Parent = morph

	Instance.new("Animator", humanoid) -- this doesn't get used, but it creates a warning from a roblox script if missing

	local head = GetPrimaryPart(model)
	head.Name = "Head"

	local propCFrame = if model:IsA("Model") then model:GetBoundingBox() else model.CFrame
	root.CFrame = propCFrame

	local weld = Instance.new("Weld")
	weld.Part0 = head
	weld.Part1 = root

	weld.C0 = head.PivotOffset.Rotation
	weld.Parent = head

	for _, part in model:GetChildren() do
		part.Parent = morph
	end
	head.Parent = morph -- This doesn't always get set, if the PrimaryPart IS the prop model

	morph:SetAttribute("PropName", model.Name)
	morph.PrimaryPart = root

	local charHead = character:FindFirstChild("Head")
	if not charHead or not charHead:IsA("BasePart") then
		return false
	end

	local propSize = if prop.Model:IsA("Model") then prop.Model:GetExtentsSize() else prop.Model.Size
	morph:PivotTo(charHead:GetPivot() * CFrame.new(Vector3.new(0, propSize.Y, 0)))

	local rootSize = propSize * 0.5
	root.Size = rootSize

	humanoid.HipHeight = rootSize.Y / 2
	root.Parent = morph

	root:GetPropertyChangedSignal("Parent"):Once(function()
		humanoid.Health = 0
	end)

	participant.CharacterCollisionGroup = COLLISION_GROUP
	participant:SpawnCharacter(morph, true)

	local health = prop:GetHealth() or DEFAULT_HEALTH

	if oldHumanoid then
		local percent = oldHumanoid.Health / oldHumanoid.MaxHealth
		humanoid.Health = health * percent
	else
		humanoid.Health = math.min(health, participant:GetHealth())
	end

	humanoid.CameraOffset = Vector3.new(0, -propSize.Y / 2, 0)
	humanoid.MaxHealth = health

	morph.Parent = workspace.Characters
	root:SetNetworkOwner(participant.Player)

	task.spawn(ForEachPart, morph, function(part: BasePart)
		part.CollisionGroup = if part == root then "Default" else COLLISION_GROUP
	end)

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