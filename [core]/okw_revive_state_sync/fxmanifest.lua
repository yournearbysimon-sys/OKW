fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'okw_revive_state_sync'
description 'Clears stuck death / fatal-injury / invBusy state so ox_inventory can open. Auto-sync on esx:onPlayerSpawn; optional export for EMS revive without spawn.'
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
