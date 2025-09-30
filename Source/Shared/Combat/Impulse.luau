local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GetMapObject = require(ReplicatedStorage.API.GetMapObject)
local GetRemote = require(ReplicatedStorage.API.GetRemote)

local Impulse = {}

local remote = GetRemote("Impulse", ReplicatedStorage.Remotes.ServerClient)

function Impulse.CanImpulse(part: BasePart): boolean
	return not part:IsGrounded()
end

function Impulse.ApplyImpulse(part: BasePart, force: Vector3): ()
	if RunService:IsServer() then
		local mapObject = GetMapObject(part, "Prop")
		if mapObject then

		end
        local owner = part:GetNetworkOwner()
        if owner then
            return remote:FireClient(owner, part, force)
        end
    end

    part:ApplyImpulse(force)
end

if RunService:IsClient() then
	remote.OnClientEvent:Connect(Impulse.ApplyImpulse)
end

return Impulse