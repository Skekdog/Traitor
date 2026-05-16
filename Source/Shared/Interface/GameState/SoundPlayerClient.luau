local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local Gamepass = require(ReplicatedStorage.Shared.Monetisation.Gamepass)
local GamepassIDs = require(ReplicatedStorage.Shared.Monetisation.GamepassIDs)

local SoundPlayerClient = {}

local remote = GetRemote("SoundPlayer", ReplicatedStorage)

local ui = UIManager.WaitForUI("Sound Player") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs["Sound Player"])}

local textBox = ui.Object.TextBox
ui.Object:GetPropertyChangedSignal("Visible"):Connect(function()
	textBox.Text = ""
	if ui.Object.Visible then
		textBox:CaptureFocus()
	end
end)

function SoundPlayerClient.TryPlay(id: number): ()
	if not Gamepass.PromptIfNotOwned(GamepassIDs["Sound Player"], Players.LocalPlayer) then
		return
	end
	remote:FireServer(id)
end

ui.Object.TextBox.FocusLost:Connect(function(enterPressed): ()
	ui:ToggleVisible(false)
	if not enterPressed then
		return
	end

	local id = tonumber(textBox.Text)
	if not id then
		return
	end

	SoundPlayerClient.TryPlay(id)
end)

local function updateMute(player: Player): ()
	local isMuted = player:GetAttribute("SoundMuted")

	local char = player.Character
	if not char then
		return
	end

	local root = char.PrimaryPart
	if not root then
		return
	end

	local sound = root:FindFirstChild("SoundPlayer")
	if not sound or not sound:IsA("Sound") then
		return
	end

	sound.Volume = if isMuted then 0 else 0.5
end

local function setupRoot(player: Player, root: Instance): ()
	updateMute(player)

	root.ChildAdded:Connect(function(child)
		if child:IsA("Sound") and child.Name == "SoundPlayer" then
			updateMute(player)
		end
	end)
end

local function onPlayerAdded(player: Player): ()
	if player == Players.LocalPlayer then
		-- return
	end

	player:GetAttributeChangedSignal("SoundMuted"):Connect(function()
		updateMute(player)
	end)

	player.CharacterAdded:Connect(function(char)
		local root = char.PrimaryPart
		if root then
			setupRoot(player, root)
		end

		char:GetPropertyChangedSignal("PrimaryPart"):Connect(function()
			local newRoot = char.PrimaryPart
			if newRoot then
				setupRoot(player, newRoot)
			end
		end)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

return table.freeze(SoundPlayerClient)