fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

author 'G&N_s Studio'
description 'G&Ns Studio Warehouses 01'
version '4.3.0'

this_is_a_map 'yes'

shared_script 'entityset/config.lua'
client_script 'entityset/main.lua'

dependencies {
    'cfx_gn_collection',
    'cfx_gn_illegal_dlc'
}

data_file 'TIMECYCLEMOD_FILE' 'gn_warehouse_timecycles.xml'

files {
    'gn_warehouse_timecycles.xml'
}
escrow_ignore {
    'entityset/config.lua',
    'entityset/main.lua',
    'stream/**/*.ytd',
    'stream/placement/**/*'
}

dependency '/assetpacks'