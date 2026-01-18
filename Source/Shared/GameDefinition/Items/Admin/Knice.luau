local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local ItemKillHighlights = require(ReplicatedStorage.API.Item.Behaviour.KillHighlights)
local Melee = require(ReplicatedStorage.API.Item.Presets.Melee)
local DNAScanner = require(ReplicatedStorage.Shared.GameDefinition.Items.Custom.DNAScanner)
local ForEachPart = require(ReplicatedStorage.Shared.RoundRule.Common.ForEachPart)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local THROW_FORCE = 80
local DAMAGE = 100

local function throw(item: Types.Item, attacker: Types.Participant, origin: Vector3, direction: Vector3): ()
	assert(item.Model)
	local model = item.Model:Clone()

	ForEachPart(model, function(part)
		part.CollisionGroup = "PlayerCharacterParts" -- to prevent collision with head
	end)

	model:RemoveTag("Interactable")
	model:RemoveTag("Item")
	model:RemoveTag("Prop")

	local didThrow = attacker:TryThrowAssembly(model, THROW_FORCE, attacker.Round:GetMap().Structure.Dynamic, origin, direction, true)
	if not didThrow then
		return
	end

	ForEachPart(model, function(part)
		local con
		con = part.Touched:Connect(function(otherPart)
			if part.AssemblyLinearVelocity.Magnitude < 0.5 then
				return con:Disconnect()
			end

			local otherModel = otherPart:FindFirstAncestorOfClass("Model")
			if not otherModel then
				return
			end

			local otherParticipant = attacker.Round:GetParticipant(otherModel.Name)
			if not otherParticipant then
				return
			end

			if otherParticipant == attacker then
				return
			end

			model:Destroy()

			local params = {
				Amount = DAMAGE,
				Attacker = attacker,
				Source = item,
			}

			ItemKillHighlights(
				{
					Title = "Knife Knowing You",
					Description = "%s stabbed someone in the face over the internet.",
					Priority = 2,
					Threshold = 1,
				},
				{
					Title = "Such A Knife Man",
					Description = "%s found %d knives lying around, and made use of them.",
					Priority = 4,
					Threshold = 2,
				},
				{
					Title = "World's Knifest Man",
					Description = "%s killed %d people with a knife. Don't ask me how.",
					Priority = 6,
					Threshold = 4,
				}
			)(item, params, otherParticipant)
			otherParticipant:TryTakeDamage(params)
		end)
	end)

	task.wait(1) -- wait, otherwise the attacker immediately picks up the knife

	if not model.Parent then
		return
	end

	model:AddTag("Item")
	local newItem = attacker.Round:LoadProp(model)

	DNAScanner.AddDNATrace(newItem, attacker, nil, Content.fromAssetId(14930962070), model)
end

local function BeforeHitParticipant(item: Types.Item, params: Types.DamageParams, hitParticipant: Types.Participant): boolean
	ItemKillHighlights(
		{
			Title = "Knife Knowing You",
			Description = "%s stabbed someone in the face over the internet.",
			Priority = 2,
			Threshold = 1,
		},
		{
			Title = "Such A Knife Man",
			Description = "%s found %d knives lying around, and made use of them.",
			Priority = 4,
			Threshold = 2,
		},
		{
			Title = "World's Knifest Man",
			Description = "%s killed %d people with a knife. Don't ask me how.",
			Priority = 6,
			Threshold = 4,
		}
	)(item, params, hitParticipant)
	local attacker = params.Attacker
	assert(attacker)

	local shop = attacker:GetRole().Definition.EquipmentShop
	local foundKnife = false
	if shop then
		for _, v in shop do
			if v.Name == "Knife" then
				foundKnife = true
				break
			end
		end
	end

	if not foundKnife then
		hitParticipant.Round:AddHighlight({
			Title = "Where Did You Get That From?",
			Description = `{attacker:GetFormattedName()} did not have connections, but still killed someone with a knife.`,
			Priority = 5,
			Group = ItemKillHighlights.GetIdentifier("Knife")
		})
	end

	return true
end

local model = ReplicatedStorage.Assets.ItemModels.Knife:Clone()
model.Name = "Knice"
model.Parent = ReplicatedStorage.Assets.ItemModels

local item = Melee({
	Name = "Knice",
	Description = "A sharp knife, capable of one-hit kills when stabbing or when thrown.",
	IconContent = Content.fromAssetId(14930962070),

	ItemGroup = ItemGroups.RoleWeapon,
	IsEvilItem = true,

	Cost = 1,
	MaxStock = 2,

	ImpulseForce = 1,

	DamageKind = "Stab" :: "Stab",
	Damage = DAMAGE,

	MaxDistance = 7,
	PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired.Crowbar,

	Model = model,
	HoldAnimation = Content.fromAssetId(96501965592565),
    PrimaryAnimation = Content.fromAssetId(122463302312412),

	AlternateFireServer = throw,
	BeforeHitParticipant = BeforeHitParticipant,
})

return item