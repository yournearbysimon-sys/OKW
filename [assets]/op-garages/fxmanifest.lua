fx_version "cerulean"

description "Best Garage System for fivem servers."
author "OTHERPLANET"
version '2.5.7'

lua54 'yes'

game 'gta5'

ui_page 'web/build/index.html'

shared_scripts {
	'@ox_lib/init.lua',
	'framework/shared.lua',
	'config/MainConfig.lua',
	'locales/*.lua',
}

client_scripts {
	'@PolyZone/client.lua',
	'@PolyZone/BoxZone.lua',
	'@PolyZone/EntityZone.lua',
	'@PolyZone/CircleZone.lua',
	'@PolyZone/ComboZone.lua',
	'config/MainConfig.lua',
	'framework/client/shared.lua',
	'framework/client/esx.lua',
	'framework/client/qb.lua',
	'framework/client/qbox.lua',
	'client/**',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'config/ServerConfig.lua',
	'framework/server/esx.lua',
	'framework/server/qb.lua',
	'framework/server/qbox.lua',
	'server/**',
}

files {
	'web/build/index.html',
	'web/build/**/*',
	'dui/dui.html'
}

escrow_ignore {
	'client/editable/**',
	'client/library/**',
	'config/**',
	'locales/**',
	'framework/**',
	'server/editable/**'
}
dependency '/assetpacks'