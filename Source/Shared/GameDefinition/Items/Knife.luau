local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemKillHighlights = require(ReplicatedStorage.Shared.GameDefinition.Items.Common.ItemKillHighlights)
local DNAScanner = require(script.Parent.DNAScanner)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local THROW_FORCE = 80
local DAMAGE = 100

local function throw(item: Types.MeleeWeapon, _, origin: Vector3, direction: Vector3, attacker: Types.Participant): ()
	local model = item.Model:Clone()

	model.CollisionGroup = "PlayerCharacterParts" -- to prevent collision with head
	assert(model:IsA("BasePart"))

	local didThrow = attacker:TryThrowAssembly(model, THROW_FORCE, nil, origin, direction, true)
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
		)(item, attacker.Round, otherParticipant, params)
		otherParticipant:TryTakeDamage(params)
	end)

	attacker:RemoveItem(item)

	task.wait(1) -- wait, otherwise the attacker immediately picks up the knife

	model.Parent = attacker.Round:GetMap().Dynamic
	local newItem = attacker.Round:LoadProp(model)

	DNAScanner.AddDNATrace(newItem, attacker, nil, "rbxassetid://14930962070", model)
end

local function BeforeHitParticipant(item: Types.ItemBeforeHit, round: Types.Round, hitParticipant: Types.Participant, params: Types.DamageParams): boolean
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
	)(item, round, hitParticipant, params)
	local attacker = params.Attacker
	assert(attacker and item.Kind == "Melee")

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
		round:AddHighlight({
			Title = "Where Did You Get That From?",
			Description = `{attacker:GetFormattedName()} did not have connections, but still killed someone with a knife.`,
			Priority = 5,
			Group = ItemKillHighlights.GetIdentifier("Knife")
		})
	end

	attacker:RemoveItem(item)

	return true
end

local item: Types.MeleeWeaponDefinition = {
	Kind = "Melee" :: "Melee",
	Name = "Knife",

	Description = "A sharp knife, capable of one-hit kills when stabbing or when thrown.",
	Icon = "rbxassetid://14930962070",

	Slot = 7,
	CanDrop = true,
	IsBadGuyItem = true,

	CreditCost = 1,
	MaxStock = 2,

	DamageKind = "Stab" :: "Stab",
	Damage = DAMAGE,

	MaxDistance = 7,
	AttackInterval = 0.75,
	AttackSound = ReplicatedStorage.Assets.WeaponSounds.Fired.Crowbar,

	Model = ReplicatedStorage.Assets.WeaponModels.Knife,
	HoldAnimation = "rbxassetid://96501965592565",
    AttackAnimation = "rbxassetid://122463302312412",

	AlternateFireServer = throw,
	AlternateToggled = true,

	BeforeHitParticipant = BeforeHitParticipant,
}

return item