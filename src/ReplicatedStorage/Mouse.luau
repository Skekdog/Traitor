local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetDisplayName = require(ReplicatedStorage.RoundRule.Common.GetDisplayName)
local GetAmmoDefinition = require(script.Parent.GetAmmoDefinition)
local GetDroppedItemState = require(script.Parent.GetDroppedItemState)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local UIManager = require(script.Parent.UIManager)

local module = {}

local camera = workspace.CurrentCamera

local crosshairInfoUI = UIManager.WaitForUI("CrosshairInfo").Object :: typeof(UIManager.UnregisteredUIs.CrosshairInfo)
local playerInfo = crosshairInfoUI.PlayerInfo

function module.ShowPlayerInfo(char: Model)
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
function module.ShowCorpseHint(char: Model)
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

local function makeLabelVisible(label: TextLabel, visible: boolean, text: string, lastCount: number): number
	if visible then
		label.Text = text
		label.Visible = true
		return lastCount + 1
	end
	label.Visible = false
	return lastCount
end

local itemHint = workspace:WaitForChild("ItemHintGui")
function module.ShowItemHint(instance: Instance)
	instance = instance:FindFirstAncestorWhichIsA("BasePart") or instance
	local state = GetDroppedItemState(instance)

	local ammo = if state.AmmoType then GetAmmoDefinition(state.AmmoType) else nil
	local maxAmmo = if ammo then ammo.Capacity else nil

	local frame = itemHint.Frame

	local count = 1

	local displayAmmoAvailable = not not (state.StoredAmmo and state.StoredAmmo ~= math.huge)
	local displayAmmoType = not not (ammo and state.Kind ~= "AmmoState") and ammo.Capacity ~= math.huge and ammo.ReserveCapacity ~= 0

	local ammoTypeText = if ammo then GetDisplayName(ammo) .. " Ammo" else ""

	frame.ItemName.Text = if ammo and state.Kind == "AmmoState" then (ammo.DisplayName or ammo.Name) .. " Ammo" else GetDisplayName(state.Definition)
	count = makeLabelVisible(frame.AmmoAvailable, displayAmmoAvailable, `{state.StoredAmmo} / {maxAmmo}`, count)
	count = makeLabelVisible(frame.AmmoType, displayAmmoType, ammoTypeText, count)

	itemHint.Border.Size = UDim2.fromScale(0.025, 0.333 * count)

	itemHint.Adornee = instance
	itemHint.Enabled = true
end

function module.Reset(): ()
	playerInfo.Visible = false
	corpseHint.Visible = false
	itemHint.Enabled = false
end

return module