--!nonstrict
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- @CloneTrooper1019, 2015
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local c = workspace.CurrentCamera
local player = game.Players.LocalPlayer
local userInput = game:GetService("UserInputService")

local selected = false
local speed = 60
local lastUpdate = 0

function getNextMovement(deltaTime)
	local nextMove = Vector3.new()
	-- Left/Right
	if userInput:IsKeyDown("A") or userInput:IsKeyDown("Left") then
		nextMove = Vector3.new(-1,0,0)
	elseif userInput:IsKeyDown("D") or userInput:IsKeyDown("Right") then
		nextMove = Vector3.new(1,0,0)
	end
	-- Forward/Back
	if userInput:IsKeyDown("W") or userInput:IsKeyDown("Up") then
		nextMove = nextMove + Vector3.new(0,0,-1)
	elseif userInput:IsKeyDown("S") or userInput:IsKeyDown("Down") then
		nextMove = nextMove + Vector3.new(0,0,1)
	end
	-- Up/Down
	if userInput:IsKeyDown("Space") then
		nextMove = nextMove + Vector3.new(0,1,0)
	elseif userInput:IsKeyDown("LeftControl") then
		nextMove = nextMove + Vector3.new(0,-1,0)
	end
	return CFrame.new( nextMove * (speed * deltaTime) )
end

function onSelected()
	local char = player.Character
	if char then
		local humanoid = char:WaitForChild("Humanoid")
		local root = char:WaitForChild("HumanoidRootPart")
		selected = true
		root.Anchored = true
		lastUpdate = tick()
		humanoid.PlatformStand = true
		while selected and char:IsDescendantOf(workspace) do
			wait()
			local delta = tick()-lastUpdate
			local look = (c.Focus.p-c.CoordinateFrame.p).unit
			local move = getNextMovement(delta)
			local pos = root.Position
			root.CFrame = CFrame.new(pos,pos+look) * move
			lastUpdate = tick()
		end
		root.Anchored = false
		root.Velocity = Vector3.new()
		humanoid.PlatformStand = false
	end
end

function onDeselected()
	selected = false
end

local function toggle()
	if selected then
		onDeselected()
	else
		onSelected()
	end
end

return {
	Start = onSelected,
	Stop = onDeselected,
	Toggle = toggle,
}