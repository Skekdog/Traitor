local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Grenade = require(ReplicatedStorage.API.Item.Presets.Grenade)
local PlaySound = require(ReplicatedStorage.API.PlaySound)

local flashbangEqualiser = Instance.new("EqualizerSoundEffect")
flashbangEqualiser.Name = "FlashbangEffect"
flashbangEqualiser.HighGain = -8
flashbangEqualiser.LowGain = 10
flashbangEqualiser.MidGain = -20
flashbangEqualiser.Enabled = true

local flashbangTweenStart = TweenInfo.new(0.15)
local flashbangTweenFinish = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 4)

local Flashbang = Grenade({
	Name = "Flashbang",
    Description = "Explodes in a good radius after 3 seconds, blinding and deafening anyone in range.",
    IconContent = Content.fromAssetId(10753198321),

    MaxStock = 2,

    ItemGroup = ItemGroups.RoleUtility,
    Cost = 1,

    Projectile = ReplicatedStorage.Assets.Projectiles.Flashbang,
    Model = ReplicatedStorage.Assets.ItemModels.Flashbang,
    HoldAnimation = Content.fromAssetId(12498620263),

    ExplosionInfo = {
        Damage = 0,
        FalloffStart = 0,
        FalloffEnd = 15,
        Pressure = 10000,
        VisualRadius = 15,
    },

    OnHitClient = function()
        local correction = Instance.new("ColorCorrectionEffect")
        local blur = Instance.new("BlurEffect")

        correction.Name = "FlashbangCorrection"
        blur.Name = "FlashbangBlur"

        correction:SetAttribute("IgnoreLighting", true)
        blur:SetAttribute("IgnoreLighting", true)

        blur.Parent = Lighting
        correction.Parent = Lighting

        local equaliser = Instance.fromExisting(flashbangEqualiser)
        equaliser.Parent = SoundService:FindFirstChild("AllSounds")

        local tween = TweenService:Create(correction, flashbangTweenStart, {Brightness = 0.8})
        tween.Completed:Once(function()
            local endTween = TweenService:Create(correction, flashbangTweenFinish, {Brightness = 0})
            endTween.Completed:Once(function()
                blur:Destroy()
                correction:Destroy()
                equaliser:Destroy()
            end)
            endTween:Play()
            TweenService:Create(blur, flashbangTweenFinish, {Size = 0}):Play()
        end)
        tween:Play()
        TweenService:Create(blur, flashbangTweenStart, {Size = 48}):Play()

        PlaySound("rbxassetid://223471024", nil, nil)
    end,

    FuseTime = 3,

    PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired.Grenade,
})

return table.freeze(Flashbang)