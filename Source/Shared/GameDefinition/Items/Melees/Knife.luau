local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DNATraces = require(ReplicatedStorage.API.DNATraces)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local ItemKillHighlights = require(ReplicatedStorage.API.Item.Behaviour.KillHighlights)
local Melee = require(ReplicatedStorage.API.Item.Presets.Melee)
local Types = require(ReplicatedStorage.API.Types)

local THROW_FORCE = 80
local DAMAGE = 100

local function throw(item: Types.Item, origin: Vector3, direction: Vector3, attacker: Types.Participant): ()
	assert(item.Model)
	local model = item.Model:Clone()

	assert(model:IsA("BasePart"))
	model.CollisionGroup = "PlayerCharacterParts" -- to prevent collision with head

	model:RemoveTag("Interactable")
	model:RemoveTag("Item")
	model:RemoveTag("Prop")

	local didThrow = attacker:TryThrowAssembly(model, THROW_FORCE, attacker.Round:GetMap().Structure.Dynamic, origin, direction, true, true)
	if not didThrow then
		return
	end

	local con
	con = model.Touched:Connect(function(otherPart)
		if model.AssemblyLinearVelocity.Magnitude < 0.5 then
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

	attacker:RemoveItem(item)

	task.wait(1) -- wait, otherwise the attacker immediately picks up the knife

	if not model.Parent then
		return
	end

	model:AddTag("Item")
	local newItem = attacker.Round:LoadProp(model)

	DNATraces.Add(newItem, attacker, nil, Content.fromAssetId(14930962070), model)
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

	attacker:RemoveItem(item, true)

	return true
end

local Knife = Melee({
	Name = "Knife",
	Description = "A sharp knife, capable of one-hit kills when stabbing or when thrown.",
	IconContent = Content.fromAssetId(14930962070),

	ItemGroup = ItemGroups.RoleWeapon,
	IsSuspicious = true,

	IsSilent = true,

	Cost = 1,
	MaxStock = 2,

	ImpulseForce = 1,

	DamageKind = "Stab" :: "Stab",
	Damage = DAMAGE,

	MaxDistance = 7,
	PrimaryInterval = 1.1,
	PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired.Crowbar,

	Model = ReplicatedStorage.Assets.ItemModels.Knife,
	HoldAnimation = Content.fromAssetId(96501965592565),
    PrimaryAnimation = Content.fromAssetId(122463302312412),

	AlternateFireServer = throw,
	AlternateToggled = true,

	BeforeHitParticipant = BeforeHitParticipant,
})

return table.freeze(Knife)