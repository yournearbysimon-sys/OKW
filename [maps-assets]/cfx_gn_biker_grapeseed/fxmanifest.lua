fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'Biker - Grapeseed'
author 'G&Ns Studio'
version '4.2.0'

this_is_a_map 'yes'

client_script {
    'gn_grapeseed_biker_entityset.lua'
}

data_file 'TIMECYCLEMOD_FILE' 'gn_biker_timecycles.xml'

files {
    'gn_biker_timecycles.xml'
}

escrow_ignore {
    'stream/**/*.ytd',
    'gn_grapeseed_biker_entityset.lua'
}
dependency '/assetpacks'