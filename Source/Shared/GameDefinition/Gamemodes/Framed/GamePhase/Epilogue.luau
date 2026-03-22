local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local GetAliveRoles = require(script.Parent.Parent.Roles.GetAliveRoles)
local HighlightCharacter = require(script.Parent.Parent.GameState.HighlightCharacter)
local Types = require(ReplicatedStorage.API.Types)
local RedHanded = require(ReplicatedStorage.Shared.GameDefinition.Gamemodes.Framed.GameState.RedHanded)

local escape = ReplicatedStorage.Assets.Gamemode.Framed.Escape

local EPILOGUE_DURATION = 45

local Epilogue = {}

local participant: Types.Participant?
local exitCFrame: CFrame?

local remote = GetRemote("Epilogue", script)

function Epilogue.IsEpilogue(round: Types.Round): boolean
	return round.Extras.FramedEpilogue == true
end

function Epilogue.Begin(framed: Types.Participant): ()
	participant = framed
	local round = framed.Round
	round.Extras.FramedEpilogue = true
	round:SetPhase("Playing", EPILOGUE_DURATION)

	local exits = round:GetMap().Structure.PlayerSpawns:GetChildren()
	local chosenExit = exits[math.random(1, #exits)]

	exitCFrame = nil
	if chosenExit and chosenExit:IsA("BasePart") then
		exitCFrame = chosenExit.CFrame * CFrame.fromEulerAnglesXYZ(0, 0, math.rad(90))
	end

	assert(exitCFrame, "Could not find exit")

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {round:GetMap().Structure.Static}
	params.FilterType = Enum.RaycastFilterType.Include
	params.IgnoreWater = true
	local result = workspace:Raycast(exitCFrame.Position, Vector3.new(0, -10, 0), params)

	if result then
		exitCFrame = CFrame.new(result.Position) * CFrame.new(0, escape.Part.Size.X / 2, 0) * CFrame.fromEulerAnglesXYZ(0, 0, math.rad(90))
	end

	RedHanded.SetPermanent(framed)
	remote:FireClient(framed.Player, exitCFrame)

	local char = framed:GetCharacter()
	if not char then
		return
	end

	HighlightCharacter(char, true, "Kill", GetAliveRoles(round, {"Police", "Undercover"}))
end

function Epilogue.Finish(): ()
	exitCFrame = nil
	if participant then
		remote:FireClient(participant.Player)
	end

	participant = nil
end

if RunService:IsClient() then
	local exit: typeof(escape)?
	local ScreenMessage = require(ReplicatedStorage.Shared.Interface.Util.ScreenMessage)
	local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
	remote.OnClientEvent:Connect(function(escapeCFrame: CFrame?): ()
		if exit then
			exit:Destroy()
			exit = nil
		end

		if not escapeCFrame then
			return
		end

		local map = LocalRoundInfo.Map()
		if not map then
			return
		end

		exit = escape:Clone()
		assert(exit)

		exit.Name = "FramedEpilogueExit"
		exit:PivotTo(escapeCFrame)
		exit.Parent = map.Structure.Dynamic :: any

		exit.Part.Touched:Connect(function(part)
			local char = Players.LocalPlayer.Character
			if not char or not part:IsDescendantOf(char) then
				return
			end

			remote:FireServer()
		end)

		ScreenMessage("Standard", "Escape!\nPolice are hunting you!", {LabelProperties = {
			BackgroundTransparency = 0.65,
			BackgroundColor3 = Color3.new(0, 0, 0),
			Size = UDim2.fromScale(1, 0.3),
			TextColor3 = Color3.fromRGB(240, 44, 28),
			TextStrokeColor3 = Color3.new(0, 0, 0),
			TextStrokeTransparency = 0,
		}})
	end)
else
	remote.OnServerEvent:Connect(function(plr)
		if not participant or participant.Player ~= plr then
			return
		end

		if not exitCFrame then
			return
		end

		local distance = plr:DistanceFromCharacter(exitCFrame.Position)
		if distance == 0 or distance > 15 then
			return
		end

		if not participant:IsAlive() then
			return
		end

		participant.Round:Finish(participant)
	end)
end

return table.freeze(Epilogue)