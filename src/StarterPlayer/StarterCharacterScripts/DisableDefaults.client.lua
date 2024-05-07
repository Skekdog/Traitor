local char = script.Parent

local hum = char:FindFirstChildOfClass("Humanoid") :: Humanoid
hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
hum:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)

local root = char:WaitForChild("HumanoidRootPart", 2)
if root then
	local run = root:WaitForChild("Running", 1)
	local death = root:WaitForChild("Died", 1)
	
	if run then run:Destroy() end
	if death then death:Destroy() end
end