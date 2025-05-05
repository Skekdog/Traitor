local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NewtonLauncher = require(script.Parent.NewtonLauncher)
local Types = require(ReplicatedStorage.RoundRule.Types)

local module = {}

local MAX_DISTANCE = 7
local PUSH_FORCE = 65

local function raycast(head: BasePart, direction: Vector3): RaycastResult?
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {head.Parent :: Model}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.CollisionGroup = "WeaponHitTargets"

	return workspace:Raycast(head.Position, direction * MAX_DISTANCE, params)
end

local item: Types.MeleeWeaponDefinition = {
    Kind = "Melee" :: "Melee",
    Name = "Crowbar",
    
    Slot = 1,
    CanDrop = false,

    DamageKind = "Bludgeon" :: "Bludgeon",

    Model = ReplicatedStorage.WeaponModels.Crowbar,
    HoldAnimation = "rbxassetid://10247423634",
    AttackAnimation = "rbxassetid://13269497293",

    MaxDistance = 7,
    Damage = 20,
    AttackInterval = 0.3,
    AttackSound = ReplicatedStorage.WeaponSounds.Fired.Crowbar.SoundId,

    AlternateFireServer = function(item: Types.MeleeWeapon, _, origin: Vector3, direction: Vector3, attacker: Types.Participant): ()
        local char = attacker:GetCharacter()
        if not char then
            return
        end

        local head = char:FindFirstChild("Head")
        if not head or not head:IsA("BasePart") then
            return
        end

        local raycastResult = raycast(head, direction)
		if not raycastResult then
			return
		end

		local hitPart = raycastResult.Instance :: BasePart
		local model = hitPart:FindFirstAncestorOfClass("Model")

		if not model then
			return
		end

		local hitParticipant = attacker.Round:GetParticipant(model.Name)
		if not hitParticipant then
			return
		end

		hitParticipant:TryTakeDamage({
			Attacker = attacker,
			Amount = 0,
			Source = "Fall",
		})

		NewtonLauncher.Fling(hitPart, direction * PUSH_FORCE * hitPart.AssemblyMass)
    end,

    AlternateToggled = true,
}

module.Item = item

return module