local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ControlManager = require(script.Parent.ControlManager)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local UIManager = require(script.Parent.UIManager)
local CorpseInfo = require(script.Parent.UIManager.UIScripts.CorpseInfo)

local plr = Players.LocalPlayer
local camera = workspace.CurrentCamera

local crosshairInfoUI = UIManager.WaitForUI("CrosshairInfo").Object :: typeof(UIManager.UnregisteredUIs.CrosshairInfo)
local playerInfo = crosshairInfoUI.PlayerInfo

UIManager.WaitForUI("Crosshair"):ToggleVisible(UserInputService.TouchEnabled and not UserInputService.MouseEnabled)
local mouse = plr:GetMouse()
mouse.Icon = "rbxassetid://10801958931"

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

	local participant = LocalRoundInfo.GetParticipantInfo(plr.Name)
	if not participant then
        return
    end

	local role = LocalRoundInfo.GetRole(participant.Role)
	playerInfo:FindFirstChild("Name").Text = plr.Name

	local healthPercent = health / hum.MaxHealth * 100
	local healthText = ""

	if healthPercent >= 80 then
		healthText = "Healthy"
	elseif healthPercent >= 60 then
		healthText = "Hurt"
	elseif healthPercent >= 40 then
		healthText = "Wounded"
	elseif healthPercent >= 20 then
		healthText = "Badly Wounded"
	else
		healthText = "Near Death"
	end

	playerInfo.Health.Text = healthText
	playerInfo.Health.TextColor3 = Color3.new(1, 0, 0):Lerp(Color3.new(1, 1, 1), healthPercent/100)

	local karma = 1000
	local karmaText = ""
	if karma >= 900 then
		karmaText = "Reputable"
	elseif karma >= 800 then
		karmaText = "Crude"
	elseif karma >= 700 then
		karmaText = "Trigger-Happy"
	elseif karma >= 600 then
		karmaText = "Dangerous"
	elseif karma >= 500 then
		karmaText = "Liability"
	end

	playerInfo.Karma.Text = karmaText	
	playerInfo.Karma.TextColor3 = Color3.new(1, 0, 0):Lerp(Color3.new(1, 1, 1), karma / 1000)

	if role then
		playerInfo.Role.TextColor3 = role.Colour
		playerInfo.Role.Text = role.Name
	else
		playerInfo.Role.Text = ""
	end

	playerInfo.Mark.Text = plr:GetAttribute("Mark") or ""
	playerInfo.Mark.TextColor3 = plr:GetAttribute("MarkColour") or Color3.new(0, 0, 0)

	playerInfo.Visible = true
	return true
end

local corpseHint = crosshairInfoUI.SearchCorpseHint
local function showCorpseHint(char: Model)
	local plr = Players.LocalPlayer

	if (plr:DistanceFromCharacter(char:GetPivot().Position) > 10) or ((camera.CFrame.Position - char:GetPivot().Position).Magnitude > 10) then
		return
	end

	local key = ControlManager.GetFirstKeyCode("Interact")

	if char:GetAttribute("Unidentified") then
		corpseHint.Text = `<font color='#ffff00'>Unidentified</font> Body\nPress {key} to Search`
	else
		local info = LocalRoundInfo.GetParticipantInfo(char.Name) or LocalRoundInfo.GetOwnParticipant()
		assert(info)
		corpseHint.Text = `{info.FormattedName}'s Body\nPress {key} to Search`
	end
	corpseHint.Visible = true
end

local params = RaycastParams.new()
params.IgnoreWater = true
params.FilterType = Enum.RaycastFilterType.Exclude
params.CollisionGroup = "Raycasts"

local interactTarget: Instance?
RunService.PostSimulation:Connect(function()
    params.FilterDescendantsInstances = {plr.Character :: Model}
    local result = workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * 10000, params)
	-- 10000 distance because we should still be able to see players. Corpses can be viewed from distance 10, so we include that as a check there.

	playerInfo.Visible = false
	corpseHint.Visible = false
	
    if result then
        interactTarget = result.Instance
        assert(interactTarget)

        local char = interactTarget:FindFirstAncestorOfClass("Model")
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
    interactTarget = nil
end)

ControlManager.Register("Interact", true, function(action, state, input, toggled)
    if not interactTarget then
        return Enum.ContextActionResult.Pass
    end
	local map = LocalRoundInfo.GetMap()

	if not map then
		return Enum.ContextActionResult.Pass
	end

	local model = interactTarget:FindFirstAncestorOfClass("Model")
	if model and model:IsDescendantOf(workspace.Corpses) then
		CorpseInfo(ReplicatedStorage.RoundHandler.SearchCorpse:InvokeServer(model))
		return Enum.ContextActionResult.Sink
	end

	local char = plr.Character
	if not char then
		return Enum.ContextActionResult.Pass
	end

	local actionItems = map:FindFirstChild("ActionItems")
	local doors = map:FindFirstChild("Doors")
	local props = map:FindFirstChild("Props")

	if (actionItems and actionItems:IsAncestorOf(interactTarget)) or (doors and doors:IsAncestorOf(interactTarget)) or (props and props:IsAncestorOf(interactTarget)) then
		ReplicatedStorage.ClientServer.Interaction:FireServer(interactTarget)
		return Enum.ContextActionResult.Sink
	end

	return Enum.ContextActionResult.Pass
end)