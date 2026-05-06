fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'okw_revive_state_sync'
description 'Clears stuck death / fatal-injury state so ox_inventory can open after revive. Call exports after your EMS heals a player.'
version '1.0.0'

dependencies {
    'es_extended',
}

server_scripts {
    'server.lua',
}

client_scripts {
    'client.lua',
}
