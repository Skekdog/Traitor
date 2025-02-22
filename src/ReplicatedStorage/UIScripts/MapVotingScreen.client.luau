local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIAnimation = require(ReplicatedStorage.UIAnimation)
local UIManager = require(ReplicatedStorage.UIManager)

type ClientMapInfo = {
	Name: string,
	Icons: {
        ["16:9"]: string?,
        ["4:3"]: string?,
        ["1:1"]: string?,
    },
}

type Votes = {
    [string]: number
}

local screen = UIManager.WaitForUI("VotingScreen") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.VotingScreen)}
type Button = typeof(screen.Object.Sample)

ReplicatedStorage.ServerClient.UpdateMapVotes.OnClientEvent:Connect(function(votes: Votes)
    local totalVotes = 0
    for _, v in votes do
        totalVotes += v
    end

    for _, v in screen.Object.Choices:GetChildren() do
        if v:IsA("ImageButton") then
            UIAnimation.Slider((v :: Button).ProgressBar, nil, votes[v.Name] or 0, totalVotes)
        end
    end
end)

local function voteFor(clone: Button): ()
    ReplicatedStorage.ClientServer.VoteMap:FireServer(clone.Name)
    for _, v in screen.Object.Choices:GetChildren() do
        if v:IsA("ImageButton") then
            local button = v :: Button
            button.UIStroke.Enabled = v == clone
        end
    end
end

ReplicatedStorage.ServerClient.TriggerMapVote.OnClientEvent:Connect(function(triggered: boolean, votableMaps: {ClientMapInfo})
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
        clone.Image = v.Icons["16:9"] or "rbxassetid://78464994818646"
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