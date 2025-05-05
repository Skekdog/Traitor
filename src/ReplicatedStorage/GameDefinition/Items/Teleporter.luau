local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local PlaySound = require(ReplicatedStorage.RoundRule.Common.PlaySound)
local Types = require(ReplicatedStorage.RoundRule.Types)
local ShowAlert = require(ReplicatedStorage.ShowAlert)

local MAX_USES = 6
local FX_DURATION = 1
local FX_HEIGHT = 2

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

local function PrimaryFireServer(item: Types.Item | Teleporter, _, _, _, participant: Types.Participant): ()
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

	local hum = participant:GetHumanoid()
	if not hum or not hum.FloorMaterial or hum.FloorMaterial == Enum.Material.Air then
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

	task.wait(FX_DURATION)

	char:PivotTo(CFrame.new(teleporter.Extras.Target) * char:GetPivot().Rotation)
	root.Anchored = false
	teleporter.Extras.InUse = false
end

local function AlternateFireServer(item: Types.Item | Teleporter, _, origin: Vector3, _, participant: Types.Participant): ()
	local teleporter = item :: Teleporter

	if (teleporter.Extras.TimesUsed or 0) >= MAX_USES then
		return ShowAlert("This teleporter is out of charge!", participant.Player)
	end

	local char = participant:GetCharacter()
	if not char then
		return
	end

	local map = participant.Round:GetMap()

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {workspace.Characters, workspace.Projectiles, map.DynamicMap, map.ItemSpawns, map.AmmoSpawns, map.Windows, map.PlayerSpawns, map.Bounds, map.Props}
	params.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(origin, Vector3.new(0, -6, 0), params)
	if not result then
		return ShowAlert("Failed to mark location.", participant.Player)
	end

	teleporter.Extras.Target = origin
end

local item: Types.ItemDefinition = {
	Kind = "Item" :: "Item",

	Name = "Teleporter",
	Description = "Can be used to teleport a limited number of times, after marking a target location.",
	Icon = "rbxassetid://8415311131",

	Slot = 8,
	CanDrop = true,

	Model = ReplicatedStorage.WeaponModels.Teleporter,
	HoldAnimation = "rbxassetid://106602520385915",

	CreditCost = 1,
	MaxStock = 1,

	PrimaryToggled = true,
	PrimaryHint = "Deploy Teleporter",
	PrimaryFireServer = PrimaryFireServer,

	AlternateToggled = true,
	AlternateHint = "Mark Location",
	AlternateFireServer = AlternateFireServer,
}

return item