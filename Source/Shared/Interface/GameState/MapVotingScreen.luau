local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIAnimation = require(ReplicatedStorage.Shared.Interface.UILib.UIAnimation)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)

type ClientMapInfo = {
	Name: string,
	Icon: Content,
}

type Votes = {
    [string]: number
}

local screen = UIManager.WaitForUI("VotingScreen") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.VotingScreen)}
type Button = typeof(screen.Object.Sample)

local function voteFor(clone: Button): ()
    ReplicatedStorage.Remotes.ClientServer.VoteMap:FireServer(clone.Name)
    for _, v in screen.Object.Choices:GetChildren() do
        if v:IsA("ImageButton") then
            local button = v :: Button
            button.UIStroke.Enabled = v == clone
        end
    end
end

ReplicatedStorage.Remotes.ServerClient.TriggerMapVote.OnClientEvent:Connect(function(triggered: boolean, votableMaps: {ClientMapInfo})
    if not triggered then
        screen:ToggleVisible(false)

        for _, v in screen.Object.Choices:GetChildren() do
            if v:IsA("ImageButton") then
                v:Destroy()
            end
        end
        return
    end

    for _, v: ClientMapInfo in votableMaps do
        local clone = screen.Object.Sample:Clone()
        clone.ImageContent = if v.Icon ~= Content.none then v.Icon else Content.fromAssetId(116876920061584)
        clone.MapName.Text = v.Name
        clone.Name = v.Name
        clone.Visible = true
        clone.Parent = screen.Object.Choices :: any

        clone.MouseButton1Click:Connect(function()
            voteFor(clone)
        end)
    end

    screen:ToggleVisible(true)
end)

-- NOTE: UpdateMapVotes MUST come after TriggerMapVote, otherwise newly joined players will receive the events in the
-- wrong order, and the update will not work
ReplicatedStorage.Remotes.ServerClient.UpdateMapVotes.OnClientEvent:Connect(function(votes: Votes)
    local totalVotes = 0
    for _, v in votes do
        totalVotes += v
    end

    for _, v in screen.Object.Choices:GetChildren() do
        local button = v :: Button
        if button:IsA("ImageButton") then
            UIAnimation.Slider(button.ProgressBar, nil, votes[v.Name] or 0, totalVotes)
            button.ProgressBar.UIStroke.Enabled = (votes[v.Name] or 0) > 0
        end
    end
end)

return nil