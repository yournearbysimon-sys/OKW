fx_version 'cerulean'
-- use_experimental_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'

author 'Gusepe'
description 'G&Ns Studio Superlab IPL'
version '1.0.1'


client_script {
    'config.lua',
    'client/main.lua'
}

escrow_ignore {
    'config.lua',
    'client/main.lua'
}
dependency '/assetpacks'