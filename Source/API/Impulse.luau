local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local GetMapObject = require(script.Parent.GetMapObject)
local GetRemote = require(script.Parent.GetRemote)
local Types = require(script.Parent.Types)

local Impulse = {}

local remote = GetRemote("Impulse", ReplicatedStorage.Remotes.ServerClient)

function Impulse.CanImpulse(part: BasePart): boolean
	return not part:IsGrounded() and part:IsDescendantOf(workspace)
end

local function trySetHolder(part: BasePart, participant: Types.Participant?): ()
	if not participant then
		return
	end

	local mapObject = GetMapObject(part, "Prop")
	if not mapObject then
		return
	end

	local prop = participant.Round:GetProp(mapObject)
	if prop then
		local PropDamage = require(ServerScriptService.Combat.PropDamage)
		PropDamage.SetLastHolder(prop, participant)
	end
end

function Impulse.ApplyImpulse(part: BasePart, force: Vector3, adjustForMass: boolean, position: Vector3?, participant: Types.Participant?): ()
	if not Impulse.CanImpulse(part) then
		return
	end

	if RunService:IsServer() then
		trySetHolder(part, participant)
        local owner = part:GetNetworkOwner()
        if owner then
            return remote:FireClient(owner, part, force, adjustForMass, position)
        end
    end

	if adjustForMass then
		force *= part.AssemblyMass
	end

	if position then
		part:ApplyImpulseAtPosition(force, position)
	else
    	part:ApplyImpulse(force)
	end
end

if RunService:IsClient() then
	remote.OnClientEvent:Connect(Impulse.ApplyImpulse)
end

return Impulse