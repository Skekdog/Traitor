local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local SharedTypes = require(ReplicatedStorage.Shared.SharedTypes)
local SafeTeleport = require(ReplicatedStorage.Shared.Util.SafeTeleport)

const ui = UIManager.WaitForUI<<typeof(UIManager.UnregisteredUIs.ServerList)>>("ServerList")

const function refresh(): ()
	const servers: {[string]: SharedTypes.ServerInfo} = ReplicatedStorage.Remotes.ClientServer.FetchServerList:InvokeServer()

	for _, object in ui.Object.ScrollingFrame:QueryDescendants("GuiObject") do
		object:Destroy()
	end

	for serverId, info in servers do
		const entry = ui.Object.ServerFrameTemplate:Clone()

		const isCurrentServer = serverId == game.JobId or RunService:IsStudio()
		if isCurrentServer then
			entry.LayoutOrder = -1
			entry.ServerId.Text = serverId:split("-")[1] .. "\n(CURRENT)"
		else
			entry.ServerId.Text = serverId:split("-")[1]
		end

		entry.Map.Text = info.Map
		entry.Gamemode.Text = info.Gamemode

		for _, userId in info.Players do
			local icon = entry.Players.ScrollingFrame.ImageButton:Clone()
			icon.ImageContent = Content.none

			task.spawn(function()
				-- bogus type error below
				const success, result = (pcall :: any)(Players.GetUserThumbnailAsync, Players, userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
				if success then
					icon.ImageContent = Content.fromUri(result)
				end
			end)

			if userId == Players.LocalPlayer.UserId then
				icon.LayoutOrder = -2
			else
				task.spawn(function()
					const success, result = pcall(Players.LocalPlayer.IsFriendsWithAsync, Players.LocalPlayer, userId)
					if success and result then
						icon.LayoutOrder = -1
					end
				end)
			end

			icon.Visible = true
			icon.Parent = entry.Players.ScrollingFrame
		end

		entry.Visible = true
		entry.Parent = ui.Object.ScrollingFrame :: any

		if not isCurrentServer then
			entry.Join.Activated:Connect(function()
				local options = Instance.new("TeleportOptions")
				options.ServerInstanceId = serverId

				SafeTeleport(info.PlaceId, {})
			end)
		end
	end
end

ui.Object:GetPropertyChangedSignal("Visible"):Connect(refresh)
ui.Object.Menu.Refresh.Activated:Connect(refresh)

return nil