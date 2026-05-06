fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author "G&N's Studio x Pichotm"
description 'G&Ns Vespucci PD - Elevator Script'
version '4.0.2'

files {
    'web/build/index.html',
    'web/build/**/*'
}

ui_page 'web/build/index.html'

shared_scripts {
    'config.lua',
}

client_script 'client/cl_*.lua'
server_script 'server/sv_*.lua'

escrow_ignore {
    'config.lua',
}
dependency '/assetpacks'