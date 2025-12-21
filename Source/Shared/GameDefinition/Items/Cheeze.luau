local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)
local ItemGroups = require(ReplicatedStorage.Shared.GameDefinition.Items.Common.ItemGroups)
local PlaySound = require(ReplicatedStorage.API.PlaySound)

local Cheeze = {}

local EAT_DURATION = 1
local HEAL_AMOUNT = 90

local ALIGN_RESPONSIVENESS = 5
local ALIGN_MAX_VELOCITY = 10

local ROTATE_VELOCITY = 2

local function playEatSound(participant: Types.Participant): ()
	local char = participant:GetCharacter()
	local root = if char then char.PrimaryPart else nil

	PlaySound(3043029786, nil, root, {
		RollOffMaxDistance = 20,
		RollOffMinDistance = 5,
	})
end

local function PrimaryFireServer(item: Types.Item, _, _, _, participant: Types.Participant): ()
	if item.Extras.IsEating or item.Extras.IsThrowing then
		return
	end

	item.PreventUnequip = true
	item.Extras.IsEating = true

	participant:TryPlayAnimation(82123370330518, "EatCheeze")

	playEatSound(participant)

	task.delay(EAT_DURATION, function()
		if not participant:IsAlive() then
			return
		end

		participant:SetHealth(participant:GetHealth() + HEAL_AMOUNT)

		participant:RemoveItem(item)
	end)
end

local function PrimaryFireClient(item: Types.Item): ()
	local ViewmodelModule = require(ReplicatedStorage.Shared.Combat.ViewmodelModule)

	if item.Extras.IsEating or item.Extras.IsThrowing then
		return
	end

	item.PreventUnequip = true
	item.Extras.IsEating = true

	ViewmodelModule.PlayAnimation("rbxassetid://82123370330518")
end

local function AlternateFireClient(item: Types.Item): ()
	local ViewmodelModule = require(ReplicatedStorage.Shared.Combat.ViewmodelModule)
	local ClientInventory = require(ReplicatedStorage.Shared.LocalState.ClientInventory)

	if item.Extras.IsEating or item.Extras.IsThrowing then
		return
	end

	item.PreventUnequip = true
	item.Extras.IsThrowing = true

	local track = ViewmodelModule.PlayAnimation("rbxassetid://115786020255555")

	local function onFinish(): ()
		ClientInventory.RemoveItem(item)
	end

	if track then
		track:GetMarkerReachedSignal("RemoveCheeze"):Once(onFinish)
	else
		onFinish()
	end
end

local function hover(cheeze: BasePart, part: BasePart): ()
	local alignPosition = Instance.new("AlignPosition")

	alignPosition.Mode = Enum.PositionAlignmentMode.TwoAttachment

	local a0 = Instance.new("Attachment")
	a0.Name = "CheezeAttachment"
	a0.Parent = cheeze

	local a1 = Instance.new("Attachment")
	a1.Name = "CheezeAttachment"

	a1.CFrame = part.CFrame:ToObjectSpace(cheeze.CFrame)

	a1.Parent = part

	alignPosition.Attachment0 = a0
	alignPosition.Attachment1 = a1

	alignPosition.MaxVelocity = ALIGN_MAX_VELOCITY
	alignPosition.Responsiveness = ALIGN_RESPONSIVENESS

	alignPosition.Name = "CheezePosition"
	alignPosition.Parent = cheeze

	local angularVelocity = Instance.new("AngularVelocity")
	angularVelocity.AngularVelocity = Vector3.new(0, ROTATE_VELOCITY, 0)
	angularVelocity.MaxTorque = 100000

	angularVelocity.Attachment0 = a0
	angularVelocity.Attachment1 = a1

	angularVelocity.RelativeTo = Enum.ActuatorRelativeTo.Attachment1

	angularVelocity.Name = "CheezeAngularVelocity"
	angularVelocity.Parent = cheeze

	Instance.new("Sparkles", cheeze).TimeScale = 0.5
end

local function AlternateFireServer(item: Types.Item, _, _, _, participant: Types.Participant): ()
	local GetParticipant = require(ReplicatedStorage.API.GetParticipant)

	if item.Extras.IsEating or item.Extras.IsThrowing then
		return
	end

	item.PreventUnequip = true
	item.Extras.IsThrowing = true

	local track = participant:TryPlayAnimation(115786020255555, "ThrowCheeze")

	local function onFinish(): ()
		assert(item.Model and item.Model:IsA("BasePart"))

		local model = item.Model:Clone()
		participant:TryThrowAssembly(model, 10, participant.Round:GetMap().Structure.Dynamic)

		participant:RemoveItem(item)

		local con
		con = model.Touched:Connect(function(part)
			if not part:IsDescendantOf(participant.Round:GetMap().Structure.Static) then
				return
			end

			con:Disconnect()
			hover(model, part)

			model.Touched:Connect(function(playerPart)
				local otherParticipant: Types.Participant? = GetParticipant(playerPart) -- type annotation needed here because otherwise "Code is too complex" type error
				if false and otherParticipant == participant then
					if participant:GetItemOccupyingGroup(ItemGroups.RoleUtility) then
						return
					end

					model:Destroy()
					participant:GiveItemFromItemDefinition(item.Definition)

					return
				end

				if otherParticipant then
					local hum = otherParticipant:GetHumanoid()
					if hum and hum.Health < hum.MaxHealth then
						model:Destroy()
						otherParticipant:SetHealth(otherParticipant:GetHealth() + HEAL_AMOUNT)

						playEatSound(otherParticipant)
					end
				end
			end)
		end)
	end

	if track then
		track:GetMarkerReachedSignal("RemoveCheeze"):Once(onFinish)
	else
		onFinish()
	end
end

local definition: Types.ItemDefinition = {
	Kind = "Item" :: "Item",

	Name = "Cheeze",
	Description = "Can be consumed to instantly heal, or thrown on the ground to allow others to heal.",
	Icon = "rbxassetid://9506964263",

	Model = ReplicatedStorage.Assets.WeaponModels.Cheeze,
	HoldAnimation = "rbxassetid://85447019535859",

	CreditCost = 1,
	MaxStock = 2,

	ItemGroup = ItemGroups.RoleUtility,

	PrimaryFireServer = PrimaryFireServer,
	PrimaryFireClient = PrimaryFireClient,
	AlternateFireServer = AlternateFireServer,
	AlternateFireClient = AlternateFireClient,
}

Cheeze.Item = definition

return Cheeze