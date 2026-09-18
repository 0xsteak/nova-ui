local net = require('@lune/net')
local fs = require('@lune/fs')

local jestModelUrl = 'https://assetdelivery.roblox.com/v1/asset/?id=16031830738'

local content = net.request({
	url = jestModelUrl,
	method = 'GET',
})

print(content.statusCode, content.statusMessage)

fs.writeFile('Jest.rbxm', content.body)
