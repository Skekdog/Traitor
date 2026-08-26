local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Audio = require(ReplicatedStorage.API.Audio)
local GetMapObject = require(ReplicatedStorage.API.GetMapObject)
local Impulse = require(ReplicatedStorage.API.Impulse)
local BehaviourTypes = require(script.Parent.BehaviourTypes)
local Checks = require(script.Parent.Checks)
local ProcessHit = require(script.Parent.ProcessHit)
local Types = require(ReplicatedStorage.API.Types)
local BulletTracer = require(ReplicatedStorage.Shared.Combat.BulletTracer)
local ForEachPart = require(ReplicatedStorage.Shared.RoundRule.Common.ForEachPart)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local ExplosionParams = require(ReplicatedStorage.Shared.RoundRule.ExplosionParams)

local SELF_SHOT_GRACE = 0.5
local BOUNCE_DEBOUNCE = 0.25

local Server = {}

local NEAR_MISS_RADIUS = 0.25 -- note this is a RADIUS, so it gets doubled when used
local NEAR_MISS_SD_DURATION = 5

local nearMissSound = Instance.new("Sound")
nearMissSound.SoundId = "rbxassetid://98905989782853"
nearMissSound.Parent = ReplicatedStorage.Assets

function Server.CreateExplosion(round: Types.Round, params: Types.ExplosionParams): ()
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

	Audio.PlayAt(info.Sound or ServerStorage.Assets.Explosion, params.Position)

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

    explosion.Parent = folder
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

	if not Checks.RaycastStatic(participant.Round:GetMap(), origin, hitscan.Position, hitscan.Hit and hitscan.Hit.Part) then
		return "StaticObscured"
	end

	if not item.IsSilent then
		Server.ApplyNearMissSelfDefense(origin, hitscan.Position, participant)
	end

	if hitscan.Hit then
		ProcessHit.Part(item, participant, hitscan.Hit.Part, hitscan.Position, hitscan.Hit.Normal, origin, hitscan.Hit.RelativeCFrame, item.Projectile, os.clock())
	end

	return nil
end

local function explode(item: Types.Item, participant: Types.Participant, projectile: Types.MapObject): ()
	if not item.ExplosionInfo then
		return
	end

	local params = ExplosionParams.new(item.ExplosionInfo, GetPrimaryPart(projectile).Position, participant, item)

	Server.CreateExplosion(participant.Round, params)

	if item.OnExplode then
		item.OnExplode(params)
	end

	if item.OnProjectileDespawn then
		item.OnProjectileDespawn(item, projectile, participant)
	end
	projectile:Destroy()
end

function Server.SimulateProjectile(item: Types.Item, participant: Types.Participant, origin: Vector3, direction: Vector3, cookedTime: number?): ()
	assert(item.Projectile, "Simulated items must define a projectile")

	local projectile = item.Projectile:Clone()
	ForEachPart(projectile, function(part)
		part.Anchored = false
		part.CollisionGroup = "WeaponHitTargets"
	end)

	;(projectile :: Instance).Parent = workspace.Projectiles

	local primaryPart = GetPrimaryPart(projectile)

	primaryPart:SetNetworkOwner(nil)

	local char = participant:GetCharacter()
	primaryPart.AssemblyLinearVelocity = if char and char.PrimaryPart then char.PrimaryPart.AssemblyLinearVelocity else Vector3.zero

	participant:TryThrowAssembly(projectile, item.ProjectileSpeed or 35, nil, origin, direction, nil, true)

	if item.OnProjectileSpawn then
		item.OnProjectileSpawn(item, projectile, participant)
	end

	if item.FuseTime and item.ExplosionInfo then
		task.wait(item.FuseTime - (cookedTime or 0))
		explode(item, participant, projectile)
	else
		local maxBounces = item.MaxBounces or 1
		local bounces = 0

		local startTime = os.clock()

		local lastBounce = 0
		ForEachPart(projectile, function(part)
			part.Touched:Connect(function(otherPart)
				if (os.clock() - lastBounce < BOUNCE_DEBOUNCE) or (os.clock() - startTime < SELF_SHOT_GRACE and char and otherPart:IsDescendantOf(char)) or not PhysicsService:CollisionGroupsAreCollidable(part.CollisionGroup, otherPart.CollisionGroup) then
					return
				end

				lastBounce = os.clock()
				bounces += 1

				local projPosition = primaryPart.Position

				local surfacePosition = otherPart:GetClosestPointOnSurface(projPosition)
				local normal = projPosition - surfacePosition

				local result = ProcessHit.Part(item, participant, otherPart, surfacePosition, normal, origin, nil, projectile, startTime)

				local shouldPlayersStopBounces = if item.ShouldPlayersStopBounces ~= nil then item.ShouldPlayersStopBounces else true
				if bounces >= maxBounces or result == "Participant" and shouldPlayersStopBounces then
					if item.ExplosionInfo then
						explode(item, participant, projectile)
					else
						if item.OnProjectileDespawn then
							item.OnProjectileDespawn(item, projectile, participant)
						end
						projectile:Destroy()
					end
				end
			end)
		end)
	end
end

local nearMissOverlapParams = OverlapParams.new()
nearMissOverlapParams.IncludeInstances = {workspace.Characters}

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

		Audio.PlayIn(nearMissSound, part, nil, nil, target.Player)
	end
end

function Server.DeductAmmo(item: Types.Item): ()
	if item.Ammo then
		item.Ammo -= 1
	end
end

function Server.PrimaryFire(item: Types.Item, origin: Vector3, direction: Vector3, participant: Types.Participant, data: unknown): {string} | string?
	if not BehaviourTypes.IsRequest(data) then
		return "InvalidRequest"
	end

	local request = data :: BehaviourTypes.Request

	if not Checks.Ammo(item) then
		return "NoAmmo"
	end

	if not Checks.Alive(item, participant:GetHealth()) then
		return "NotAlive"
	end

	if not Checks.GamePhase(item, participant.Round:GetPhase()) then
		return "PhaseInactive"
	end

	if not Checks.ActionEnabled(item, "Primary") then
		return "PrimaryDisabled"
	end

	local char = participant:GetCharacter()
	if not char or not Checks.OriginDistance(item, origin, char) then
		return "OriginTooFar"
	end

	Server.DeductAmmo(item)

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

function Server.ProcessReject(item: Types.Item): ()
	-- Well actually this will also run if the hit is rejected because NoAmmo but lol!
	Server.DeductAmmo(item)
end

return table.freeze(Server)