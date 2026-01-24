
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
		return false
	end

	if typeof(data.Position) ~= "Vector3" then
		return false
	end

	if data.Hit == nil then
		return true
	end

	if typeof(data.Hit) ~= "table" then
		return false
	end

	if typeof(data.Hit.Part) ~= "Instance" or not data.Hit.Part:IsA("BasePart") then
		return false
	end

	if typeof(data.Hit.Normal) ~= "Vector3" or data.Hit.Normal.Unit ~= data.Hit.Normal then
		return false
	end

	if typeof(data.Hit.RelativeCFrame) ~= "CFrame" then
		return false
	end

	return true
end

function BehaviourTypes.IsRequest(data: any): boolean
	if data == nil then
		return true
	end

	if typeof(data) ~= "table" then
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