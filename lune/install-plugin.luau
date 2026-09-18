local fs = require('@lune/fs')
local process = require('@lune/process')

local os = process.os
local pluginName = process.args[1]
local pluginDir = 'plugins/' .. pluginName
local installScript = pluginDir .. '/install.' .. if os == 'windows' then 'bat' else 'sh'

if os == 'linux' then
	return print('linux is not supported')
end

if not fs.isDir(pluginDir) then
	return print(`plugin "{pluginName}" not found`)
end

if not fs.isFile(installScript) then
	return print('install script not found')
end

process.exec(installScript, nil, {
	cwd = pluginDir,
	stdio = {
		stdout = 'inherit',
		stderr = 'inherit',
	},
})
