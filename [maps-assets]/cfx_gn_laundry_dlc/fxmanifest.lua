fx_version 'cerulean'
game 'gta5'

author 'G&N_s Studio'
description 'G&Ns Laundry Superlab'
version '4.1.0'

this_is_a_map 'yes'

dependencies {
    'cfx_gn_collection',
    'cfx_gn_illegal_dlc'
}

data_file 'TIMECYCLEMOD_FILE' 'gn_superlab_timecycles.xml'

files {
    'gn_superlab_timecycles.xml'
}
escrow_ignore {
    'stream/**/*.ytd',
    'stream/**/unlock_file/**/*'
}
dependency '/assetpacks'