fx_version 'cerulean'
game 'gta5'

author 'G&N_s Studio'
description 'Blaine County - Fire Department'
version '4.1.0'

this_is_a_map 'yes'

dependencies {
    '/gameBuild:2189',
    'cfx_gn_collection'
}
data_file 'TIMECYCLEMOD_FILE' 'gn_fire_timecycle.xml'

files {
    'gn_fire_timecycle.xml'
}

escrow_ignore {
    'stream/base/**/*',
    'stream/**/*.ytd',
    'stream/interior/ydr/prop_gn_fire_logo_01.ydr',
    'stream/interior/ydr/prop_gn_fire_logo_02.ydr',
    'stream/interior/ydr/prop_gn_fire_logo_dcl_01.ydr',
    'stream/interior/ydr/prop_gn_fire_logo_dcl_02.ydr',
    'stream/interior/ydr/prop_gn_fire_logo_dcl_03.ydr',
    'stream/interior/ydr/prop_gn_fire_logo_def_02.ydr',
    'stream/exterior/ydr/gn_bc_firestation_details.ydr'
}

dependency '/assetpacks'