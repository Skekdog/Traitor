local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Audio = require(ReplicatedStorage.API.Audio)
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local Message = require(ReplicatedStorage.API.Interface.Message)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Custom = require(ReplicatedStorage.API.Item.Presets.Custom)
local Types = require(ReplicatedStorage.API.Types)

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

local TELEPORT_SOUND = Audio.MakeSound({
	Content = Content.fromAssetId(5518430240),
	RolloffStart = 15,
	RolloffEnd = 25,
})

local remote = GetRemote("TeleporterFX", script)

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

		Audio.PlayAt(TELEPORT_SOUND, at)

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
	params.ExcludeInstances = {workspace.Characters, workspace.Projectiles, map.Structure.PlayerSpawns}

	local result = workspace:Raycast(origin, Vector3.new(0, -GROUNDED_RAY_DISTANCE, 0), params)
	return not not result
end

local function PrimaryFireServer(item: Types.Item | Teleporter, _, _, participant: Types.Participant): ()
	local teleporter = item :: Teleporter

	if teleporter.Extras.InUse or not teleporter.Extras.Target then
		return
	end

	if (teleporter.Extras.TimesUsed or 0) >= MAX_USES then
		return Message.Popup("This teleporter is out of charge!", participant.Player)
	end

	local char = participant:GetCharacter()
	if not char then
		return
	end

	if not isGrounded(participant) then
		return Message.Popup("Can't teleport right now!", participant.Player)
	end

	local root = char.PrimaryPart
	if not root then
		return
	end

	root.Anchored = true
	teleporter.Extras.InUse = true
	teleporter.Extras.TimesUsed = (teleporter.Extras.TimesUsed or 0) + 1

	makeFXServer(participant.Player, teleporter.Extras.Target)

	Message.Popup(`Teleporting! {100 - math.round((teleporter.Extras.TimesUsed / MAX_USES) * 100)}% remaining.`, participant.Player)

	task.wait(FX_DURATION)

	char:PivotTo(CFrame.new(teleporter.Extras.Target) * char:GetPivot().Rotation)
	root.Anchored = false
	teleporter.Extras.InUse = false
end

local function AlternateFireServer(item: Types.Item | Teleporter, origin: Vector3, _, participant: Types.Participant): ()
	local teleporter = item :: Teleporter

	if (teleporter.Extras.TimesUsed or 0) >= MAX_USES then
		return Message.Popup("This teleporter is out of charge!", participant.Player)
	end

	if not isGrounded(participant) then
		return Message.Popup("Failed to mark location.", participant.Player)
	end

	Message.Popup("Location marked!", participant.Player)

	teleporter.Extras.Target = origin
end

local function OnEquipServer(teleporter: Types.Item | Teleporter, participant: Types.Participant): ()
	Message.Popup(`{100 - math.round(((teleporter.Extras.TimesUsed or 0) / MAX_USES) * 100)}% remaining.`, participant.Player)
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

return table.freeze(item)