
local config = {
	lute = {
		lint = {
			rulepaths = {"Lints"},
			ignores = {"Lints/*.luau"},
			ruleconfigs = {
				unused_variable = {
					off = true,
				},
				reassigned_parameter = {
					off = false,
				},
			},
		},
	},
}

return config