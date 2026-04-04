local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fire = require(ReplicatedStorage.API.Fire)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Grenade = require(ReplicatedStorage.API.Item.Presets.Grenade)
local PlaySound = require(ReplicatedStorage.API.PlaySound)
local CreateEmptyPart = require(ReplicatedStorage.Shared.RoundRule.Common.CreateEmptyPart)

local IncendiaryGrenade = {}

local RAY_OFFSET = Vector3.new(0, 8, 0)
local RAY_SPREAD = math.rad(45)

local random = Random.new()

local item = Grenade({
    Name = "Incendiary Grenade",
	Description = "The fire and the flame",
	IconContent = Content.none,

    ItemGroup = ItemGroups.Grenade,

    Projectile = ReplicatedStorage.Assets.Projectiles["Incendiary Grenade"],
    HoldAnimation = Content.fromAssetId(12498620263),
    Model = ReplicatedStorage.Assets.ItemModels["Incendiary Grenade"],

    ExplosionInfo = {
        Damage = 10,
        FalloffStart = 0,
        FalloffEnd = 15,
        Pressure = 10000,
        VisualRadius = 15,

		Sound = PlaySound.MakeSound(114507723450506, {
			Volume = 0.75,
			RollOffMinDistance = 40,
			RollOffMaxDistance = 60,
		})
    },

    OnExplode = function(params)
		local raycastResult = workspace:Raycast(params.Position, RAY_OFFSET)
		local startPos = if raycastResult then raycastResult.Position else params.Position + RAY_OFFSET

		for _ = 1, 20 do
			local x = random:NextNumber(-RAY_SPREAD, RAY_SPREAD)
			local y = random:NextNumber(-RAY_SPREAD, RAY_SPREAD)
			local vec = CFrame.Angles(math.rad(-90) + x, y, 0).LookVector * 2048
			local raycastResult2 = workspace:Raycast(startPos, vec)

			if raycastResult2 and raycastResult2.Material ~= Enum.Material.Water then
				task.delay(random:NextNumber(0, 1), function(): ()
					local part = CreateEmptyPart(CFrame.new(raycastResult2.Position))
					part.Size = Vector3.new(3, 3, 3) * random:NextNumber(0.75, 1.5)
					part.Parent = workspace.Projectiles
					Fire.Ignite(part)
					task.wait(random:NextNumber(17.5, 21.5))
					part:Destroy()
				end)
			end
		end
    end,

    FuseTime = 3,

    ProjectileSpeed = 60,

	PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired.Grenade,
})

IncendiaryGrenade.Item = item

return table.freeze(IncendiaryGrenade)