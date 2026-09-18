local process = require('@lune/process')
local fs = require('@lune/fs')
local serde = require('@lune/serde')

local config = serde.decode('json', fs.readFile('rocale.config.json'))

process.exec('rojo', {
	'build',
	'-o',
	'Place.rbxl',
	'place.project.json',
})

process.exec('rocale-cli', {
	'run',
	'-u',
	`{config.UNIVERSE_ID}`,
	'-p',
	`{config.PLACE_ID}`,
	'--apiKey',
	config.ROBLOX_API_KEY,
	'--load.place',
	'Place.rbxl',
	'--script',
	'scripts/run-tests.luau',
}, { stdio = 'forward' })
