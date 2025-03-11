local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GetDisplayName = require(ReplicatedStorage.RoundRule.Common.GetDisplayName)
local ControlManager = require(script.Parent.ControlManager)
local GetAmmoDefinition = require(script.Parent.GetAmmoDefinition)
local GetDroppedItemState = require(script.Parent.GetDroppedItemState)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local ShowAlert = require(script.Parent.ShowAlert)
local UIManager = require(script.Parent.UIManager)
local ViewCorpse = require(script.Parent.ViewCorpse)

local module = {}

local plr = Players.LocalPlayer
local camera = workspace.CurrentCamera

local crosshairInfoUI = UIManager.WaitForUI("CrosshairInfo").Object :: typeof(UIManager.UnregisteredUIs.CrosshairInfo)
local playerInfo = crosshairInfoUI.PlayerInfo

local function showPlayerInfo(char: Model)
	local plr = Players:GetPlayerFromCharacter(char)
	if not plr then
        return
    end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
        return
    end

	local health = hum.Health
	if health <= 0 then
        return
    end

	local role = LocalRoundInfo.GetPlayerRole(plr.Name)
	playerInfo:FindFirstChild("Name").Text = plr.Name

	local healthPercent = health / hum.MaxHealth * 100
	local healthText = ""

	if healthPercent > 80 then
		healthText = "Healthy"
	elseif healthPercent > 60 then
		healthText = "Hurt"
	elseif healthPercent > 40 then
		healthText = "Wounded"
	elseif healthPercent > 20 then
		healthText = "Badly Wounded"
	else
		healthText = "Near Death"
	end

	playerInfo.Health.Text = healthText
	playerInfo.Health.TextColor3 = Color3.new(1, 0, 0):Lerp(Color3.new(1, 1, 1), healthPercent/100)

	local karma = 1000
	local karmaText = ""
	if karma > 900 then
		karmaText = "Reputable"
	elseif karma > 800 then
		karmaText = "Crude"
	elseif karma > 700 then
		karmaText = "Trigger-Happy"
	elseif karma > 600 then
		karmaText = "Dangerous"
	elseif karma > 500 then
		karmaText = "Liability"
	end

	playerInfo.Karma.Text = karmaText
	playerInfo.Karma.TextColor3 = Color3.new(1, 0.4, 0):Lerp(Color3.new(1, 1, 1), (karma - 600) / 400)

	if role then
		playerInfo.Role.Text = role:GetFormattedRoleName()
		playerInfo.Role.Visible = true
	else
		playerInfo.Role.Visible = false
	end

	local mark = plr:GetAttribute("Mark") :: string?
	playerInfo.Mark.Text = mark or ""
	playerInfo.Mark.TextColor3 = plr:GetAttribute("MarkColour") :: Color3 or Color3.new(0, 0, 0)

	playerInfo.Mark.Visible = not not mark

	playerInfo.Visible = true
	return true
end

local corpseHint = crosshairInfoUI.SearchCorpseHint
local function showCorpseHint(char: Model)
	local plr = Players.LocalPlayer

	if LocalRoundInfo.GetPlayerStatus(plr.Name) == "Alive" then
		if (plr:DistanceFromCharacter(char:GetPivot().Position) > 10) or ((camera.CFrame.Position - char:GetPivot().Position).Magnitude > 10) then
			return
		end
	end

	if char:GetAttribute("Unidentified") then
		corpseHint.Text = `<font color='#ffff00'>Unidentified</font> Body`
	else
		local role = LocalRoundInfo.GetPlayerRole(char.Name)
		if not role then
			return
		end

		corpseHint.Text = `{role:GetFormattedString(char.Name .. "'s")} Body`
	end
	corpseHint.Visible = true
end

local itemHint = workspace:WaitForChild("ItemHintGui")
local function showItemHint(instance: Instance)
	local state = GetDroppedItemState(instance)

	local ammo = if state.AmmoType then GetAmmoDefinition(state.AmmoType) else nil
	local maxAmmo = if ammo then ammo.Capacity else nil

	local frame = itemHint.Frame
	frame.ItemName.Text = if ammo and state.Kind == "AmmoState" then (ammo.DisplayName or ammo.Name) .. " Ammo" else GetDisplayName(state.Definition)
	frame.AmmoAvailable.Text = if state.StoredAmmo then `{state.StoredAmmo} / {maxAmmo}` else ""
	frame.AmmoType.Text = if ammo and state.Kind ~= "AmmoState" then GetDisplayName(ammo) .. " Ammo" else ""

	local count = 1
	if state.StoredAmmo then
		count += 1
	end
	if ammo and state.Kind ~= "AmmoState" then
		count += 1
	end

	itemHint.Border.Size = UDim2.fromScale(0.025, 0.333 * count)

	itemHint.Adornee = instance
	itemHint.Enabled = true
end

local params = RaycastParams.new()
params.IgnoreWater = true
params.FilterType = Enum.RaycastFilterType.Exclude
params.CollisionGroup = "Raycasts"

module.InteractTarget = nil :: Instance?
RunService.PostSimulation:Connect(function()
	local cameraSubject = workspace.CurrentCamera.CameraSubject
	if cameraSubject and cameraSubject.Parent and cameraSubject:IsA("Humanoid") then
		params.FilterDescendantsInstances = {cameraSubject.Parent}
	end

	local map = LocalRoundInfo.GetMap()
	if map then
		params:AddToFilter(map.Bounds)
	end
	
    local result = workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * 10000, params)
	-- 10000 distance because we should still be able to see players. Corpses can be viewed from distance 10, so we include that as a check there.

	playerInfo.Visible = false
	corpseHint.Visible = false
	itemHint.Enabled = false
	
    if result then
        module.InteractTarget = result.Instance
        assert(module.InteractTarget)

		if map then
			if module.InteractTarget:IsDescendantOf(map.ItemSpawns) or module.InteractTarget:IsDescendantOf(map.AmmoSpawns) then
				showItemHint(module.InteractTarget)
			end
		end

        local char = module.InteractTarget:FindFirstAncestorOfClass("Model")
        if not char then
            return
        end

        if char:IsDescendantOf(workspace.Corpses) then
            showCorpseHint(char)
        elseif char:IsDescendantOf(workspace.Characters) then
            showPlayerInfo(char)
        end

        return
    end
    module.InteractTarget = nil
end)

ControlManager.Register("Interact", function(action, state, input)
    if not module.InteractTarget then
        return Enum.ContextActionResult.Pass
    end
	local map = LocalRoundInfo.GetMap()

	if not map then
		return Enum.ContextActionResult.Pass
	end

	local model = module.InteractTarget:FindFirstAncestorOfClass("Model")
	if model and model:IsDescendantOf(workspace.Corpses) then
		if model:GetAttribute("Burning") then
			ShowAlert("Ouch! This corpse is on fire!")
			return Enum.ContextActionResult.Pass
		end
		
		ViewCorpse(model)

		return Enum.ContextActionResult.Sink
	end

	local char = plr.Character
	if not char then
		return Enum.ContextActionResult.Pass
	end
	
	return Enum.ContextActionResult.Pass
end)

return module