local process = require("@lune/process")
local fs = require("@lune/fs")

local HOME = process.env["HOME"]
local STUDIO_PATH_LINUX = `{HOME}/.var/app/org.vinegarhq.Vinegar/data/vinegar/versions/`

local LOCALAPPDATA = process.env["LOCALAPPDATA"]
local STUDIO_PATH_WINDOWS = `{LOCALAPPDATA}/Roblox/Versions/`
local STUDIO_PATH_RSMM = `{LOCALAPPDATA}/Roblox Studio/`

local function locateStudioInstallation(): string
	if process.os == "linux" then
		if not fs.isDir(STUDIO_PATH_LINUX) then
			error("Could not locate studio installation: " .. STUDIO_PATH_LINUX)
		end

		local children = fs.readDir(STUDIO_PATH_LINUX)
		local version = children[1]

		if not version then
			error("Could not locate studio installation: " .. STUDIO_PATH_LINUX)
		end

		local installationPath = STUDIO_PATH_LINUX .. version
		if not fs.isDir(installationPath) then
			error("Could not locate studio installation: " .. STUDIO_PATH_LINUX)
		end

		return installationPath
	elseif process.os == "windows" then
		if fs.isDir(STUDIO_PATH_WINDOWS) then
			local children = fs.readDir(STUDIO_PATH_WINDOWS)
			local version = children[1]

			if not version then
				error("Could not locate studio installation: " .. STUDIO_PATH_WINDOWS)
			end

			local installationPath = STUDIO_PATH_WINDOWS .. version
			if not fs.isDir(installationPath) then
				error("Could not locate studio installation: " .. STUDIO_PATH_WINDOWS)
			end

			return installationPath
		elseif fs.isDir(STUDIO_PATH_RSMM) then
			return STUDIO_PATH_RSMM
		else
			error("Could not locate studio installation: " .. STUDIO_PATH_WINDOWS .. "\nOR: " .. STUDIO_PATH_RSMM)
		end
	else
		error("Platform unsupported")
	end
end

local function locatePlayerModule(): string
	return locateStudioInstallation() .. "/ExtraContent/scripts/PlayerScripts/StarterPlayer/PlayerModule"
end

local function CopyPlayerModule(destination: string): ()
	if fs.isDir(destination) then
		fs.removeDir(destination) -- Copying on its own is not entirely safe, as an update PlayerModule may have removed some files
	end

	fs.copy(locatePlayerModule(), destination, true)

	print("Copied successfully.")
end

return CopyPlayerModule
