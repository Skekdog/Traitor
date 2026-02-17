local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local GetMapObject = require(ReplicatedStorage.API.GetMapObject)
local Impulse = require(ReplicatedStorage.API.Impulse)
local PlaySound = require(ReplicatedStorage.API.PlaySound)
local BehaviourTypes = require(script.Parent.BehaviourTypes)
local Checks = require(script.Parent.Checks)
local ProcessHit = require(script.Parent.ProcessHit)
local Types = require(ReplicatedStorage.API.Types)
local BulletTracer = require(ReplicatedStorage.Shared.Combat.BulletTracer)
local ForEachPart = require(ReplicatedStorage.Shared.RoundRule.Common.ForEachPart)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local ExplosionParams = require(ReplicatedStorage.Shared.RoundRule.ExplosionParams)

local Server = {}

local NEAR_MISS_RADIUS = 0.25 -- note this is a RADIUS, so it gets doubled when used
local NEAR_MISS_SD_DURATION = 5

local nearMissSound = Instance.new("Sound")
nearMissSound.SoundId = "rbxassetid://98905989782853"
nearMissSound.Parent = ReplicatedStorage.Assets

function Server.CreateExplosion(round: Types.Round, params: Types.ExplosionParams, sound: Sound?): ()
    local explosion = Instance.new("Explosion")

    local info = params.Definition

    explosion.Position = params.Position
    explosion.BlastRadius = info.VisualRadius
    explosion.BlastPressure = info.Pressure

    explosion.DestroyJointRadiusPercent = 0
    explosion.ExplosionType = Enum.ExplosionType.NoCraters

    local folder = workspace:FindFirstChild("Explosions") or Instance.new("Folder")
    assert(folder:IsA("Folder"), "Explosions is not a folder")
    folder.Name = "Explosions"
    folder.Parent = workspace

	PlaySound(sound or ServerStorage.Assets.Explosion, params.Position)

    explosion.Parent = folder

	local hits: {Types.Participant | Types.Prop} = {}
    for _, v in workspace:GetPartBoundsInRadius(params.Position, info.FalloffEnd) do
		if not v:IsDescendantOf(workspace) then
			continue -- stupid bullshit
		end
		local propObject = GetMapObject(v, "Prop")
		if propObject then
			local prop = round:GetProp(propObject)
			if prop then
				if table.find(hits, prop) then
					continue
				end
				table.insert(hits, prop)
				ProcessHit.Prop(params, params.Attacker, prop, v, v.Position, params.Position)
				continue
			end
		end

		local char = GetMapObject(v, "Character")
		local participant = if char and char:IsA("Model") then round:GetParticipant(char) else nil

		local impulse = (v.Position - params.Position).Unit * info.Pressure / 1000

		if participant then
			if table.find(hits, participant) then
				continue
			end

			if info.FilterImpulse and info.FilterImpulse(info, participant) == false then
				impulse = Vector3.zero
			end

			table.insert(hits, participant)
			ProcessHit.Participant(params, params.Attacker, participant, v, v.Position, params.Position, impulse)
		end

		Impulse.ApplyImpulse(v, impulse, true, nil, params.Attacker)
    end
end

function Server.ProcessHitscan(item: Types.Item, origin: Vector3, participant: Types.Participant, i: number, hitscan: BehaviourTypes.HitscanResult): string?
	if i > (item.ProjectileCount or 1) then
		return "TooManyShots"
	end

	if item.Projectile then
		BulletTracer(item.Projectile, item.ProjectileSpeed or 100, origin, hitscan.Position, participant.Player)
	end

	if not Checks.TargetDistance(item, origin, hitscan.Position) then
		return "TargetTooFar"
	end

	if not Checks.RaycastStatic(item, participant, origin, hitscan.Position, hitscan.Hit and hitscan.Hit.Part) then
		return "StaticObscured"
	end

	if not item.IsSilent then
		Server.ApplyNearMissSelfDefense(origin, hitscan.Position, participant)
	end

	if hitscan.Hit then
		ProcessHit.Part(item, participant, hitscan.Hit.Part, hitscan.Position, hitscan.Hit.Normal, origin, hitscan.Hit.RelativeCFrame)
	end

	return nil
end

function Server.SimulateProjectile(item: Types.Item, participant: Types.Participant, origin: Vector3, direction: Vector3): ()
	assert(item.Projectile, "Simulated items must define a projectile")

	local projectile = item.Projectile:Clone()
	ForEachPart(projectile, function(part)
		part.Anchored = false
		part.CollisionGroup = "WeaponHitTargets"
	end)

	;(projectile :: Instance).Parent = workspace.Projectiles

	local primaryPart = GetPrimaryPart(projectile)

	primaryPart:SetNetworkOwner(nil)
	participant:TryThrowAssembly(projectile, item.ProjectileSpeed or 35, nil, origin, direction)

	if item.FuseTime and item.ExplosionInfo then
		task.wait(item.FuseTime)

		local params = ExplosionParams.new(item.ExplosionInfo, primaryPart.Position, participant, item)

		Server.CreateExplosion(participant.Round, params)

		if item.OnExplode then
			item.OnExplode(params)
		end

		projectile:Destroy()
	else
		local maxBounces = item.MaxBounces or 1
		local bounces = 0

		local startTime = os.clock()

		local char = participant:GetCharacter()

		ForEachPart(projectile, function(part)
			part.Touched:Connect(function(otherPart)
				if (os.clock() - startTime < 0.5 and char and otherPart:IsDescendantOf(char)) or not PhysicsService:CollisionGroupsAreCollidable(part.CollisionGroup, otherPart.CollisionGroup) then
					return
				end

				bounces += 1

				local projPosition = primaryPart.Position

				local surfacePosition = otherPart:GetClosestPointOnSurface(projPosition)
				local normal = projPosition - surfacePosition

				local result = ProcessHit.Part(item, participant, otherPart, surfacePosition, normal, origin)

				local shouldPlayersStopBounces = if item.ShouldPlayersStopBounces ~= nil then item.ShouldPlayersStopBounces else true
				if bounces >= maxBounces or result == "Participant" and shouldPlayersStopBounces then
					projectile:Destroy()
				end
			end)
		end)
	end
end

local nearMissOverlapParams = OverlapParams.new()
nearMissOverlapParams.FilterDescendantsInstances = {workspace.Characters}
nearMissOverlapParams.FilterType = Enum.RaycastFilterType.Include

-- I think it makes more sense to do this on the server than on the client?
-- I'm not honestly sure though
function Server.ApplyNearMissSelfDefense(origin: Vector3, destination: Vector3, attacker: Types.Participant): ()
	local round = attacker.Round

	local processed: {[Model]: true?} = {}

	local length = (destination - origin).Magnitude
	local cframe = CFrame.new(origin, destination) * CFrame.new(0, 0, -length / 2)

	local size = Vector3.one * NEAR_MISS_RADIUS * 2 * Vector3.new(1, 1, length)

	for _, part in workspace:GetPartBoundsInBox(cframe, size, nearMissOverlapParams) do
		local model = part:FindFirstAncestorOfClass("Model")
		if not model or processed[model] then
			continue
		end

		processed[model] = true

		local target = round:GetParticipant(model)
		if not target or target == attacker then
			continue
		end

		target:AddSelfDefenseEntry({
			Against = attacker,
			Duration = NEAR_MISS_SD_DURATION,
		})

		PlaySound(nearMissSound, nil, part, nil, target.Player)
	end
end

function Server.PrimaryFire(item: Types.Item, origin: Vector3, direction: Vector3, participant: Types.Participant, data: unknown): {string} | string?
	if not BehaviourTypes.IsRequest(data) then
		return "InvalidRequest"
	end

	local request = data :: BehaviourTypes.Request

	if item.Ammo then
		if item.Ammo <= 0 then
			return "NoAmmo"
		end
		item.Ammo -= 1
	end

	if not request and not item.IsProjectileSimulated then
		return "InvalidHitscanRequest"
	elseif request and item.IsProjectileSimulated then
		return "InvalidSimulationRequest"
	end

	local rejects: {string} = {}
	if request then
		for i, hitscan in ipairs(request) do
			local reject = Server.ProcessHitscan(item, origin, participant, i, hitscan)
			if reject then
				table.insert(rejects, reject)
			end
		end
	else
		Server.SimulateProjectile(item, participant, origin, direction)
	end

	return rejects
end

return Server