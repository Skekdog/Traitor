local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local ItemKillHighlights = require(ReplicatedStorage.API.ItemPresets.ItemKillHighlights)
local FiveSeven = require(script.Parent.FiveSeven)
local Modify = require(ReplicatedStorage.API.ItemPresets.Modify)

local SilencedPistol = Modify(FiveSeven, "Silenced Pistol", {
	IsSilent = true,
	IsEvilItem = true,

	ItemGroup = ItemGroups.RoleWeapon,

	Model = ReplicatedStorage.Assets.ItemModels["Silenced Pistol"],
    HoldAnimation = Content.fromAssetId(9253211833),
    AimAnimation = Content.fromAssetId(18691552315),
    PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired["Silenced Pistol"],
    ReloadSound = ReplicatedStorage.Assets.ItemSounds.Reload["Silenced Pistol"],

    Projectile = ReplicatedStorage.Assets.Projectiles.SilencedBullet,

    BeforeHitParticipant = ItemKillHighlights(
        {
            Title = "Be Quiet",
            Description = "%s shut %d people up with the silenced pistol.",
            Priority = 2,
            Threshold = 2,
        },
        {
            Title = "Silenced Assassin",
            Description = "%s killed %d people who did not hear themselves die.",
            Priority = 4,
            Threshold = 4,
        }
    ),
})

return SilencedPistol