fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name 'Preload-ox_crafttree'
author 'Preload Studio'
description 'crafting skill tree'
version '1.0.0'

dependencies {
    'ox_lib',
    'ox_inventory',
}

shared_script '@ox_lib/init.lua'

client_script 'client/main.lua'

ui_page 'web/build/index.html'

files {
    'locales/*.json',
    'web/build/index.html',
    'web/build/**/*',
}

dependency '/assetpacks'