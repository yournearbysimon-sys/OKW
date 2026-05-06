fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'

name 'Preload Studio throw items'
author 'Preload Studio'
version '1.0'
description 'Throw items from inventory'

dependencies {
	'ox_lib',
	'ox_inventory'
}

shared_scripts {
	'@ox_lib/init.lua'
}

server_scripts {
	'server.lua'
}

client_script 'client.lua'

files {
	'locales/*.json'
}

ox_libs {
	'math',
	'locale',
}


dependency '/assetpacks'