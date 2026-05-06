fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'Preload-gizmo'
description 'Standalone gizmo'
version '1.0.0'

ui_page 'web/build/index.html'

client_scripts {
    'client/gizmo.lua',
}

shared_scripts {
    '@ox_lib/init.lua'
}

files {
    'client/dataview.lua',
    'web/build/index.html',
    'web/build/**/*',
}

dependencies {
    'ox_lib'
}

dependency '/assetpacks'