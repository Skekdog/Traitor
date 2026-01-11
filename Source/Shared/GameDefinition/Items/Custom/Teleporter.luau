local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Custom = require(ReplicatedStorage.API.ItemPresets.Custom)
local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local ShowAlert = require(ReplicatedStorage.Shared.Interface.Util.ShowAlert)

local MAX_USES = 6

local FX_DURATION = 1
local FX_HEIGHT = 2

local GROUNDED_RAY_DISTANCE = 4

local teleportFX = Instance.new("Part")
teleportFX.Anchored = true
teleportFX.Size = Vector3.new(2, 0.1, 2)
teleportFX.CastShadow = false
teleportFX.CanTouch = false
teleportFX.CanCollide = false
teleportFX.CanQuery = false
teleportFX.Color = Color3.new(0.52549, 0.858824, 0.372549)
teleportFX.Transparency = 0.5
teleportFX.Material = Enum.Material.Neon

local remote: RemoteEvent
if RunService:IsServer() then
	remote = Instance.new("RemoteEvent")
	remote.Name = "TeleporterFX"
	remote.Parent = script
else
	local found = script:WaitForChild("TeleporterFX")
	assert(found:IsA("RemoteEvent"), "TeleporterFX must be a RemoteEvent")
	remote = found
end

type Teleporter = Types.Item & {
	Extras: {
		TimesUsed: number?,
		Target: Vector3?,
		InUse: boolean?,
		[any]: never,
	}
}

local function makeFXServer(player: Player, destination: Vector3): ()
	remote:FireAllClients(player, destination)
end

if RunService:IsClient() then
	local function makeFX(at: Vector3, mode: "MoveUp" | "MoveDown"): ()
		local moveVector = Vector3.new(0, if mode == "MoveUp" then -FX_HEIGHT else FX_HEIGHT, 0)

		local fx = teleportFX:Clone()
		fx.Position = at - moveVector / 2
		fx.Parent = workspace.Projectiles

		local tween = TweenService:Create(fx, TweenInfo.new(FX_DURATION, Enum.EasingStyle.Linear), {
			Position = at + moveVector,
		})

		tween.Completed:Once(function()
			fx:Destroy()
		end)

		PlaySound(5518430240, at, nil, {
			SoundGroup = SoundService.AllSounds :: SoundGroup,
			RollOffMinDistance = 5,
			RollOffMaxDistance = 12,
		})

		tween:Play()
	end

	remote.OnClientEvent:Connect(function(player: Player?, destination: Vector3)
		if not player then
			return
		end

		local char = player.Character
		if not char then
			return
		end

		makeFX(char:GetPivot().Position, "MoveUp")
		makeFX(destination, "MoveDown")
	end)
end

local function isGrounded(participant: Types.Participant): boolean
	local char = participant:GetCharacter()
	if not char then
		return false
	end

	local origin = char:GetPivot().Position
	local map = participant.Round:GetMap()

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {workspace.Characters, workspace.Projectiles, map.Structure.PlayerSpawns}
	params.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(origin, Vector3.new(0, -GROUNDED_RAY_DISTANCE, 0), params)
	return not not result
end

local function PrimaryFireServer(item: Types.Item | Teleporter, participant: Types.Participant): ()
	local teleporter = item :: Teleporter

	if teleporter.Extras.InUse or not teleporter.Extras.Target then
		return
	end

	if (teleporter.Extras.TimesUsed or 0) >= MAX_USES then
		return ShowAlert("This teleporter is out of charge!", participant.Player)
	end

	local char = participant:GetCharacter()
	if not char then
		return
	end

	if not isGrounded(participant) then
		return ShowAlert("Can't teleport right now!", participant.Player)
	end

	local root = char.PrimaryPart
	if not root then
		return
	end

	root.Anchored = true
	teleporter.Extras.InUse = true
	teleporter.Extras.TimesUsed = (teleporter.Extras.TimesUsed or 0) + 1

	makeFXServer(participant.Player, teleporter.Extras.Target)

	ShowAlert(`Teleporting! {100 - math.round((teleporter.Extras.TimesUsed / MAX_USES) * 100)}% remaining.`, participant.Player)

	task.wait(FX_DURATION)

	char:PivotTo(CFrame.new(teleporter.Extras.Target) * char:GetPivot().Rotation)
	root.Anchored = false
	teleporter.Extras.InUse = false
end

local function AlternateFireServer(item: Types.Item | Teleporter, participant: Types.Participant, origin: Vector3): ()
	local teleporter = item :: Teleporter

	if (teleporter.Extras.TimesUsed or 0) >= MAX_USES then
		return ShowAlert("This teleporter is out of charge!", participant.Player)
	end

	if not isGrounded(participant) then
		return ShowAlert("Failed to mark location.", participant.Player)
	end

	ShowAlert("Location marked!", participant.Player)

	teleporter.Extras.Target = origin
end

local function OnEquipServer(teleporter: Types.Item | Teleporter, participant: Types.Participant): ()
	ShowAlert(`{100 - math.round(((teleporter.Extras.TimesUsed or 0) / MAX_USES) * 100)}% remaining.`, participant.Player)
end

local item = Custom({
	Name = "Teleporter",
	Description = "Can be used to teleport a limited number of times, after marking a target location.",
	IconContent = Content.fromAssetId(8415311131),

	ItemGroup = ItemGroups.RoleUtility,

	Model = ReplicatedStorage.Assets.ItemModels.Teleporter,
	HoldAnimation = Content.fromAssetId(106602520385915),

	Cost = 1,
	MaxStock = 1,

	PrimaryToggled = true,
	PrimaryHint = "Deploy Teleporter",
	PrimaryFireServer = PrimaryFireServer,

	AlternateToggled = true,
	AlternateHint = "Mark Location",
	AlternateFireServer = AlternateFireServer,

	OnEquipServer = OnEquipServer,
})

return item