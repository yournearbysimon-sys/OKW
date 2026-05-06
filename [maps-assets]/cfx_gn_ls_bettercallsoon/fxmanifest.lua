fx_version 'cerulean'
game 'gta5'

author 'G&N_s Studio'
description 'Better Call Soon - Los Santos'
version '4.1.0'

this_is_a_map 'yes'

dependencies {
    '/gameBuild:2189',
    'cfx_gn_collection'
}

data_file 'TIMECYCLEMOD_FILE' 'gn_bettercall_timecycle.xml'

files {
    'gn_bettercall_timecycle.xml'
}

escrow_ignore {
    'stream/base/**/*',
    'stream/**/*.ytd'
}
dependency '/assetpacks'