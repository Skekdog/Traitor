
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalCharacter
local GetCentreRay
if RunService:IsClient() then
	LocalCharacter = require(ReplicatedStorage.LocalCharacter)
	GetCentreRay = require(ReplicatedStorage.GetCentreRay)
end

local Ammo = require(script.Parent.Ammo)
local Types = require(ReplicatedStorage.RoundRule.Types)

local MAX_RANGE = 10000

local function raycast(char: Model, range: number): RaycastResult?
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {char}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.CollisionGroup = "WeaponHitTargets"

	return workspace:Raycast(workspace.CurrentCamera.CFrame.Position, GetCentreRay().Direction.Unit * range, params)
end

local item: Types.GunWeaponDefinition = {
	Kind = "Gun" :: "Gun",
	Name = "Poltergeist",
	Description = "Attaches thrusters to props, blasting them towards others.",
	Icon = "rbxassetid://103677163409705",

	Model = ReplicatedStorage.WeaponModels.Poltergeist,

	LaserColor = Color3.new(),

	HoldAnimation = "rbxassetid://10247380824",

	Slot = 8,
	MaxStock = 2,
	CreditCost = 1,
	CanDrop = true,

	Damage = 0,

	Spread = 0,

	AttackInterval = 3,
	ReloadTime = 0,
	AmmoType = Ammo["Poltergeist"],

	AttackSound = "",
	ReloadSound = "",

	RecoilX = 0,
	RecoilY = 0,

	PreRenderClient = function(item: Types.AnyItem, dt: number): ()
		assert(item.Kind == "Gun")
		local map = workspace:FindFirstChild("Map")
		if not map then
			return
		end

		local props = map:FindFirstChild("Props")
		if not props then
			return
		end

		local result = raycast(assert(LocalCharacter.GetCharacter()), MAX_RANGE)
		if not result then
			return
		end

		if result.Instance:IsDescendantOf(props) then
			item.Definition.LaserColor = Color3.new(0, 1, 0)
		else
			item.Definition.LaserColor = Color3.new(1, 0, 0)
		end
	end
}

return item