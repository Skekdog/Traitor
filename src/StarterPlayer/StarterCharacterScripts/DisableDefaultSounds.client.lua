local root = script.Parent:WaitForChild("HumanoidRootPart",2)

if root then
	local run = root:WaitForChild("Running",1)
	local death = root:WaitForChild("Died",1)
	
	if run then run:Destroy() end
	if death then death:Destroy() end
end