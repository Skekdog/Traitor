local module = {}

function module.LerpNumber(num1: number, num2: number, decimal: number): number --Linearly interpolates a number
	return num1 + ((num2 - num1) * decimal)
end

return module