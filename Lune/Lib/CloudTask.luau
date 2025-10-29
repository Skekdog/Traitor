--[=[
MIT License

Copyright (c) 2022 JohnnyMorganz

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]=]

-- Script adapted from Luau LSP

local serde = require("@lune/serde")
local task = require("@lune/task")
local net = require("@lune/net")
local Env = require("./Env")

local CLOUD_TASK_KEY = Env.CLOUD_TASK_KEY or error("Missing CLOUD_TASK_KEY")
local UNIVERSE_ID = 4059912034
local PLACE_ID = 11411951000

local UPLOAD_PLACE_URL = `https://apis.roblox.com/universes/v1/{UNIVERSE_ID}/places/{PLACE_ID}/versions?versionType=Saved`
local TASK_URL = `https://apis.roblox.com/cloud/v2/universes/{UNIVERSE_ID}/places/{PLACE_ID}/versions/\{placeVersion}/luau-execution-session-tasks`

type LuauTask = {
	path: string,
	createTime: string,
	updateTime: string,
	user: string,
	state: "STATE_UNSPECIFIED" | "QUEUED" | "PROCESSING" | "CANCELLED" | "COMPLETE" | "FAILED",
	script: string,
}

local function uploadPlace(universeId: number, placeId: number, data: string): number
	print("Uploading place file...")

	local response = net.request({
		url = UPLOAD_PLACE_URL,
		method = "POST",
		headers = {
			["x-api-key"] = CLOUD_TASK_KEY,
			["Content-Type"] = "application/octet-stream",
		},
		body = data,
	})

	assert(response.ok, `uploadPlace failed: {response.body}`)

	return serde.decode("json", response.body).versionNumber
end

local function startTask(universeId: number, placeId: number, placeVersion: number, scriptContents: string): LuauTask
	local response = net.request({
		method = "POST",
		url = TASK_URL:gsub("{placeVersion}", tostring(placeVersion)),
		headers = {
			["Content-Type"] = "application/json",
			["x-api-key"] = CLOUD_TASK_KEY,
		},
		body = serde.encode("json", {
			script = scriptContents,
		}),
	})

	if not response.ok then
		error(`Create task request failed: {response.body}`)
	end

	return serde.decode("json", response.body)
end

local function awaitTaskCompletion(taskPath: string): LuauTask
	while true do
		local response = net.request({
			method = "GET",
			url = `https://apis.roblox.com/cloud/v2/{taskPath}`,
			headers = {
				["X-API-Key"] = CLOUD_TASK_KEY,
			},
		})

		assert(response.ok, `Get task request failed: {response.body}`)

		local cloudTask = serde.decode("json", response.body)
		if cloudTask.state ~= "PROCESSING" then
			return cloudTask
		else
			task.wait(3)
		end
	end
end

local function getTaskLogs(taskPath: string): string
	local response = net.request({
		method = "GET",
		url = `https://apis.roblox.com/cloud/v2/{taskPath}/logs`,
		headers = {
			["X-API-Key"] = CLOUD_TASK_KEY,
		},
	})

	if not response.ok then
		error(`Get task logs failed: {response.body}`)
	end

	return table.concat(serde.decode("json", response.body).luauExecutionSessionTaskLogs[1].messages, "\n")
end

local function runLuauTask(universeId: number, placeId: number, placeVersion: number, scriptContents: string)
	print("Executing Luau task...")

	local cloudTask = startTask(universeId, placeId, placeVersion, scriptContents)
	cloudTask = awaitTaskCompletion(cloudTask.path)
	local logs = getTaskLogs(cloudTask.path)

	print(logs)

	if cloudTask.state == "COMPLETE" then
		print("Luau task completed successfully")
	else
		error("Luau task failed")
	end
end

local function CloudTask(placeData: string, scriptContents: string): ()
	local placeVersion = uploadPlace(UNIVERSE_ID, PLACE_ID, placeData)
	runLuauTask(UNIVERSE_ID, PLACE_ID, placeVersion, scriptContents)
end

return CloudTask