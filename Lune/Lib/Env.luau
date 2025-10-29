local fs = require("@lune/fs")
local serde = require("@lune/serde")

assert(fs.isFile(".env"), "Missing .env file")
local env: {[string]: string?} = serde.decode("toml", fs.readFile(".env"))

return env