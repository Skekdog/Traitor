local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIManager = require(script.Parent.Parent)
local UIAnimation = require(script.Parent.Parent.Parent.UIAnimation)

type ClientMapInfo = {
	Name: string,
	ImageId: string,
}

type Votes = {
    [string]: {number}
}

local screen = UIManager.WaitForUI("VotingScreen") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.VotingScreen)}
type Button = typeof(screen.Object.Sample)

ReplicatedStorage.ServerClient.UpdateMapVotes.OnClientEvent:Connect(function(votes: Votes)
    local totalVotes = 0
    for _, v in votes do
        totalVotes += #v
    end

    for i, v in votes do
        local clone = screen.Object.Choices:FindFirstChild(i) :: Button?
        if clone then
            UIAnimation.Slider(clone.ProgressBar, nil, #v, totalVotes)
        end
    end
end)

local function voteFor(clone: Button): ()
    ReplicatedStorage.RoundHandler.VoteMap:FireServer(clone.Name)
    for _, v: Button in screen.Object.Choices:GetChildren() do
        if v:IsA("ImageButton") then
            v.UIStroke.Enabled = v == clone
        end
    end
end

return function(allow: boolean): ()
    screen:ToggleVisible(allow)

    if not allow then
        for _, v in screen.Object.Choices:GetChildren() do
            if v:IsA("ImageButton") then
                v:Destroy()
            end
        end
        return
    end

    for _, v: ClientMapInfo in ReplicatedStorage.RoundHandler.GetMaps:InvokeServer() do
        local clone = screen.Object.Sample:Clone()
        clone.Image = v.ImageId
        clone.MapName.Text = v.Name
        clone.Name = v.Name
        clone.Visible = true
        clone.Parent = screen.Object.Choices
    
        clone.MouseButton1Click:Connect(function()
            voteFor(clone)
        end)
    end
end
