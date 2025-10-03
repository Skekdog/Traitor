
local function GetAssemblyMass(root: BasePart, countRopes: boolean?, _processedParts: {[BasePart]: true?}?): number
	_processedParts = _processedParts or {}
	assert(_processedParts)
	if _processedParts[root] then
		return 0
	end

	_processedParts[root] = true

	local mass = root.Mass
	local joints = (root:GetJoints() :: any) :: {JointInstance | Constraint} -- GetJoints has an incorrect type

	for _, joint in joints do
		if joint:IsA("RopeConstraint") and not countRopes then
			continue
		end
		if joint:IsA("Constraint") then
			if joint.Attachment0 and joint.Attachment0.Parent and joint.Attachment0.Parent:IsA("BasePart") then
				mass += GetAssemblyMass(joint.Attachment0.Parent, countRopes, _processedParts)
			end

			if joint.Attachment1 and joint.Attachment1.Parent and joint.Attachment1.Parent:IsA("BasePart") then
				mass += GetAssemblyMass(joint.Attachment1.Parent, countRopes, _processedParts)
			end
		else
			if joint.Part1 then
				mass += GetAssemblyMass(joint.Part1, countRopes, _processedParts)
			end

			if joint.Part0 then
				mass += GetAssemblyMass(joint.Part0, countRopes, _processedParts)
			end
		end
	end

	return mass
end

return GetAssemblyMass