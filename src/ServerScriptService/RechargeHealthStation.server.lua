local CollectionService = game:GetService("CollectionService")

if #CollectionService:GetTagged("HealthStationRechargeable") < 1 then
    error("REMEMBER TO TAG THE HEALTH STATION AS HealthStationRechargeable")
end

while true do
    for _, v in CollectionService:GetTagged("HealthStationRechargeable") do
        v:SetAttribute("CurrentCharge", math.min(200, v:GetAttribute("CurrentCharge").Value+1))
    end
	task.wait(task.wait(1))
end