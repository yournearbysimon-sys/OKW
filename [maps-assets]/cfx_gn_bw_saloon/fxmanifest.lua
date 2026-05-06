fx_version 'cerulean'
game 'gta5'

author 'G&N_s Studio'
description 'Black_Wood_Saloon'
version '4.0.0'

this_is_a_map 'yes'

dependencies {
    '/gameBuild:2189'
}

data_file 'TIMECYCLEMOD_FILE' 'gusepe_timecycle_mods_saloon.xml'

files {
    'gusepe_timecycle_mods_saloon.xml',
}

escrow_ignore {
    'stream/base/**/*',
    'stream/**/*.ytd'
}

dependency '/assetpacks'