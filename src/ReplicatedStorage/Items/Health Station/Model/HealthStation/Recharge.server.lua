local toolData = script.Parent.Parent:WaitForChild("ToolData")
while true do
	task.wait(toolData:GetAttribute("RechargeRate"))
	toolData.CurrentCharge.Value = math.min(200,toolData.CurrentCharge.Value+1)
end