local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Grenade = require(ReplicatedStorage.API.Item.Presets.Grenade)
local PlaySound = require(ReplicatedStorage.API.PlaySound)
local CreateEmptyPart = require(ReplicatedStorage.Shared.RoundRule.Common.CreateEmptyPart)

local SmokeGrenade = Grenade({
	Name = "Smoke Grenade",
	Description = "oh no I can't see",
	IconContent = Content.none,

    ItemGroup = ItemGroups.Grenade,

    HoldAnimation = Content.fromAssetId(12498620263),
    Model = ReplicatedStorage.Assets.ItemModels["Smoke Grenade"],

    ExplosionInfo = {
        Damage = 0,
        FalloffStart = 0,
        FalloffEnd = 15,
        Pressure = 10000,
        VisualRadius = 15,

        Sound = PlaySound.MakeSound(104605904869658, {
            Volume = 0.75,
            RollOffMinDistance = 40,
            RollOffMaxDistance = 60,
        })
    },

    OnExplode = function(params)
        local smoke = Instance.new("Smoke")
        smoke.Size = 7.5
        smoke.Opacity = 0.75
        smoke.RiseVelocity = 2
        smoke.Color = Color3.fromRGB(127, 127, 127)

        local smokePart = CreateEmptyPart(CFrame.new(params.Position))
        smoke.Parent = smokePart
        smokePart.Parent = workspace.Projectiles

        task.delay(30, smokePart.Destroy, smokePart)
    end,

    FuseTime = 3,

    Projectile = ReplicatedStorage.Assets.Projectiles["Smoke Grenade"],

    PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired.Grenade,
})

return table.freeze(SmokeGrenade)