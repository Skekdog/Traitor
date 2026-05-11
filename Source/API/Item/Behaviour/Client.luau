local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Audio = require(ReplicatedStorage.API.Audio)
local GetMapObject = require(ReplicatedStorage.API.GetMapObject)
local GetMaterial = require(ReplicatedStorage.API.GetMaterial)
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local BehaviourTypes = require(script.Parent.BehaviourTypes)
local Checks = require(script.Parent.Checks)
local Raycasts = require(script.Parent.Raycasts)
local Types = require(ReplicatedStorage.API.Types)
local RoundInfoUI = require(ReplicatedStorage.Shared.Interface.GameState.RoundInfoUI)
local LocalAnimation = require(ReplicatedStorage.Shared.Character.LocalAnimation)
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
local Aim = require(ReplicatedStorage.Shared.Combat.Aim)
local BulletTracer = require(ReplicatedStorage.Shared.Combat.BulletTracer)
local HitSounds = require(ReplicatedStorage.Shared.Combat.HitSounds)
local Viewmodel = require(ReplicatedStorage.Shared.Combat.Viewmodel)
local ClientInventory = require(ReplicatedStorage.Shared.LocalState.ClientInventory)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)

local Client = {}

local lastEmptyClipSound = 0
local function tryPlayEmptyClipSound(item: Types.Item, action: "Primary" | "Alternate"): ()
	local interval = (if action == "Primary" then item.PrimaryInterval else item.AlternateInterval) or 1
	if lastEmptyClipSound < (os.clock() - interval) then
		Client.PlayEmptyClipSound()
		lastEmptyClipSound = os.clock()
	end
end

local remote = GetRemote("ItemFire")

function Client.DeductAmmo(item: Types.Item): ()
	if not item.Ammo then
		return
	end

	item.Ammo -= 1
	RoundInfoUI.UpdateAmmo()
end

function Client.ApplyInterval(item: Types.Item, action: "Primary" | "Alternate"): ()
	if action == "Primary" and item.PrimaryInterval then
		item.PrimaryLastUse = os.clock()
	elseif action == "Alternate" and item.AlternateInterval then
		item.AlternateLastUse = os.clock()
	end
end

function Client.MuzzleFlash(item: Types.Item): ()
	if item.HasMuzzleFlash then
		Viewmodel.MuzzleFlash()
	end
end

function Client.Recoil(item: Types.Item): ()
	Viewmodel.Recoil(item)
end

local emptyClipSound = ReplicatedStorage.Assets.ItemSounds.EmptyClip
function Client.PlayEmptyClipSound(): ()
	Audio.Play2D(emptyClipSound, true)
end

function Client.PlaySound(item: Types.Item, action: "Primary" | "Alternate"): ()
	if action == "Primary" and item.PrimarySound then
		Audio.Play2D(item.PrimarySound)
	elseif action == "Alternate" and item.AlternateSound then
		Audio.Play2D(item.AlternateSound)
	end
end

function Client.PlayAnimation(item: Types.Item, action: "Primary" | "Alternate"): ()
	if action == "Primary" and item.PrimaryAnimation then
		LocalAnimation.TryPlayAnimation(item.PrimaryAnimation, action .. "Fire")
		Viewmodel.PlayAnimation(item.PrimaryAnimation, action .. "Fire")
	elseif action == "Alternate" and item.AlternateAnimation then
		LocalAnimation.TryPlayAnimation(item.AlternateAnimation, action .. "Fire")
		Viewmodel.PlayAnimation(item.AlternateAnimation, action .. "Fire")
	end
end

function Client.GetViewmodelItem(): Types.MapObject?
	return Viewmodel.GetViewmodelItem()
end

function Client.RunAllChecks(item: Types.Item, action: "Primary" | "Alternate", noEffects: boolean?): boolean
	if not Checks.ActionEnabled(item, action) then
		return false
	end

	if not Checks.GamePhase(item, LocalRoundInfo.Phase() :: Types.Phase) then
		return false
	end

	if not Checks.Interval(item, "Primary") then
		return false
	end

	if not Checks.Reloading(item) then
		return false
	end

	if not Checks.Ammo(item) then
		if not noEffects and not Client.TryReloadWeapon(item) then
			tryPlayEmptyClipSound(item, action)
		end
		return false
	end

	if not Checks.Scoped(item, Aim.IsAiming()) then
		tryPlayEmptyClipSound(item, action)
		return false
	end

	return true
end

function Client.RunAllEffects(item: Types.Item, action: "Primary" | "Alternate"): ()
	Client.DeductAmmo(item)
	Client.MuzzleFlash(item)
	Client.Recoil(item)
	Client.PlaySound(item, action)
	Client.PlayAnimation(item, action)
	Client.ApplyInterval(item, action)
end

function Client.PrimaryFire(item: Types.Item, origin: Vector3, direction: Vector3, noEffects: boolean?): string | {string} | boolean
	local char = LocalCharacter.Character()
	if not char then
		return "NoCharacter"
	end

	if not Client.RunAllChecks(item, "Primary", noEffects) then
		return false
	end

	if not noEffects then
		Client.RunAllEffects(item, "Primary")
	end

	if not item.IsProjectileSimulated then
		local params = Raycasts.GetDefaultRaycastParams(char)

		local hits = {}
		for i = 1, item.ProjectileCount or 1 do
			local spreadDirection = Raycasts.GetRaycastDirection(direction, item.Spread or 0)
			local result = Raycasts.Hitscan(params, origin, spreadDirection, item.MaxDistance or 10000, item.CheckInitialIntersection, item.CheckInitialIntersection)

			if item.Projectile and not noEffects then
				BulletTracer(item.Projectile, item.ProjectileSpeed or 100, origin, result.Position)
			end

			table.insert(hits, result)

			if not result.Hit then
				continue
			end

			if not GetMapObject(result.Hit.Part, "Character") and not noEffects then
				local hitSound: Sound
				if item.HitSound then
					hitSound = item.HitSound
				else
					local sounds = HitSounds[GetMaterial(result.Hit.Part)] or HitSounds.Default
					hitSound = sounds[math.random(#sounds)]
				end
				Audio.PlayAt(hitSound, result.Position)
			end
		end

		local data: BehaviourTypes.Request = hits

		item:SetServerData("Primary", data)
	end

	return true
end

function Client.Aim(item: Types.Item): boolean
	if item.IsAimable then
		Aim.ToggleAim(item)
	end
	return true
end

function Client.TryReloadWeapon(item: Types.Item): boolean
	local ammoDefinition = item.AmmoDefinition
	if not ammoDefinition then
		return false
	end

	if item.Ammo >= ammoDefinition.Capacity or item.IsReloading then
		return false
	end

	local reserve = ClientInventory.GetReserveAmmo(ammoDefinition.Name)
	if reserve <= 0 then
		return false
	end

	item.IsReloading = true

	ReplicatedStorage.Remotes.ClientServer.ReloadWeapon:FireServer(item.Name)

	if item.UseShells then
		local oldFreq = Viewmodel.ReloadSpring.angularFrequency
		if oldFreq ~= 0 then
			Viewmodel.ReloadSpring.angularFrequency = 0
			Viewmodel.ReloadSpring.p = Vector3.new(10000, 100000, 10000)
		end

		local lastAmmo = item.Ammo
		while ClientInventory.EquippedItem() == item do
			if item.Ammo > lastAmmo then
				lastAmmo = item.Ammo
				if item.ReloadSound then
					Audio.Play2D(item.ReloadSound)
				end
			elseif item.Ammo ~= lastAmmo then
				lastAmmo = item.Ammo
			end

			-- not in the loop condition because we still want to play reload sound when inserting the final shell
			if not item.IsReloading then
				break
			end

			task.wait()
		end

		if oldFreq ~= 0 then
			Viewmodel.ReloadSpring.angularFrequency = oldFreq
			Viewmodel.ReloadSpring.p = Vector3.new(10, 5, 10)
		end
	else
		Viewmodel.ReloadSpring.p = Vector3.new(10, 5, 10)

		if item.ReloadSound then
			Audio.Play2D(item.ReloadSound)
		end
	end

	return true
end

function Client.ServerFire(action: "Primary" | "Alternate", item: Types.Item, origin: Vector3, direction: Vector3): ()
	remote:FireServer(item.Name, action, origin, direction, item:GetServerData(action))
	item:SetServerData(action, nil)
end

return table.freeze(Client)