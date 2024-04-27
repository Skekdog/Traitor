local CollectionService = game:GetService("CollectionService")

while true do
    for _,v in CollectionService:GetTagged("HealthStationRechargeable") do
        v:SetAttribute("CurrentCharge", math.min(200, v:GetAttribute("CurrentCharge").Value+1))
    end
	task.wait(task.wait(1))
end