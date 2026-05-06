game 'common'

fx_version 'cerulean'
author 'OTHERPLANET'
description 'OP Loading Screen. This script is part of OP Multicharacter'
version '1.0.1'
lua54 'yes'

loadscreen 'web/build/index.html'
loadscreen_cursor 'yes'

loadscreen_manual_shutdown "yes"
files { 'web/**' }

dependency '/assetpacks'