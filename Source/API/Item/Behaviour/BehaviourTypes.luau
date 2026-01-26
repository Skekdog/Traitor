
local BehaviourTypes = {}

export type HitscanResult = {
	Hit: {
		Part: BasePart,
		Normal: Vector3,
		RelativeCFrame: CFrame,
	}?,
	Position: Vector3,
}

export type Request = {HitscanResult}?

function BehaviourTypes.IsHitscanRequest(data: any): boolean
	if typeof(data) ~= "table" then
		warn("Invalid Request:", typeof(data))
		return false
	end

	if typeof(data.Position) ~= "Vector3" then
		warn("Invalid Request.Position:", typeof(data.Position))
		return false
	end

	if data.Hit == nil then
		return true
	end

	if typeof(data.Hit) ~= "table" then
		warn("Invalid Request.Hit:", typeof(data.Hit))
		return false
	end

	if typeof(data.Hit.Part) ~= "Instance" or not data.Hit.Part:IsA("BasePart") then
		warn("Invalid Request.Hit.Part:", typeof(data.Hit.Part))
		return false
	end

	if typeof(data.Hit.Normal) ~= "Vector3" then
		warn("Invalid Request.Hit.Normal:", typeof(data.Hit.Normal))
		return false
	end

	data.Hit.Normal = data.Hit.Normal.Unit

	if typeof(data.Hit.RelativeCFrame) ~= "CFrame" then
		warn("Invalid Request.Hit.RelativeCFrame:", typeof(data.Hit.RelativeCFrame))
		return false
	end

	return true
end

function BehaviourTypes.IsRequest(data: any): boolean
	if data == nil then
		return true
	end

	if typeof(data) ~= "table" then
		warn("Data was not a table: ", typeof(data))
		return false
	end

	for _, v in ipairs(data) do
		if not BehaviourTypes.IsHitscanRequest(v) then
			return false
		end
	end

	return true
end

return BehaviourTypes