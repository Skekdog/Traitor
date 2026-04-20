local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetMapObject = require(ReplicatedStorage.API.GetMapObject)
local Types = require(ReplicatedStorage.API.Types)
local ForEachPart = require(ReplicatedStorage.Shared.RoundRule.Common.ForEachPart)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)

local PropDamage = {}

local serverLastHeldBy: {[Types.Prop]: {By: Types.Participant, At: number, Cons: {RBXScriptConnection}}?} = {}
local DAMAGE_TIME = 5
local ALLOW_SELF_DAMAGE_AFTER = 1

function PropDamage.GetController(prop: Types.MapObject): Player?
	local controllerId = prop:GetAttribute("ControllerId")
	if typeof(controllerId) ~= "number" then
		return nil
	end
	return Players:GetPlayerByUserId(controllerId)
end

local function onPropTouchedServer(prop: Types.Prop, otherPart: BasePart): ()
	assert(prop.Round)
	if not otherPart:IsDescendantOf(workspace) then
		return -- somehow happened, idk
	end

	if not prop.Model:IsDescendantOf(workspace) then
		return -- also somehow happens??
	end

	if PropDamage.GetController(prop.Model) then
		return
	end

	local lastHeld = serverLastHeldBy[prop]
	if not lastHeld then
		return
	end

	if workspace:GetServerTimeNow() - lastHeld.At > DAMAGE_TIME then
		serverLastHeldBy[prop] = nil
		for _, con in lastHeld.Cons do
			con:Disconnect()
		end
		return
	end

	local part = GetPrimaryPart(prop.Model)
	local energy = 0.5 * part.AssemblyMass * (part.AssemblyLinearVelocity.Magnitude ^ 2)
	if energy < 2000 then
		return
	end

	local damage = (energy - 2000) / 1000
	local params: Types.DamageParams = {
		Amount = damage,
		Source = "Crush",
		Attacker = lastHeld.By,
		Direction = part.AssemblyLinearVelocity,
	}

	prop:TryTakeDamage(params)

	local otherMapObject = GetMapObject(otherPart, {"Prop", "Character"})
	if not otherMapObject then
		return
	end

	local damageable = prop.Round:GetProp(otherMapObject) or if otherMapObject:IsA("Model") then prop.Round:GetParticipant(otherMapObject) else nil
	if damageable and (damageable ~= lastHeld.By or workspace:GetServerTimeNow() - lastHeld.At > ALLOW_SELF_DAMAGE_AFTER) then
		(damageable :: Types.Prop):TryTakeDamage(params)
	end
end

function PropDamage.SetLastHolder(prop: Types.Prop, participant: Types.Participant): ()
	if not serverLastHeldBy[prop] then
		prop.Model.Destroying:Connect(function()
			serverLastHeldBy[prop] = nil
		end)
	end
	local cons: {RBXScriptConnection} = {}
	serverLastHeldBy[prop] = {By = participant, At = workspace:GetServerTimeNow(), Cons = cons}
	ForEachPart(prop.Model, function(part)
		local con: RBXScriptConnection
		con = part.Touched:Connect(function(otherPart)
			onPropTouchedServer(prop, otherPart)
		end)
		table.insert(cons, con)
	end)
end

return table.freeze(PropDamage)