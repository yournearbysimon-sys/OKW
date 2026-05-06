fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'G&N_s Studio'
description 'G&N_s Vespucci Police Department'
version '4.4.1'

this_is_a_map 'yes'

dependencies {
    'cfx_gn_collection',
    'cfx_gn_pd_props_dlc'
}

client_scripts {
    'config.lua',
    'client/ipl_manager.lua'
}

data_file 'TIMECYCLEMOD_FILE' 'gn_vspd_timecycle.xml'

files {
    'gn_vspd_timecycle.xml'
}

escrow_ignore {
    'stream/assets/**/*',
    'stream/base/**/*',
    'stream/exterior/**/*',
    'stream/ytd/**/*',
    'stream/int_lift/**/*',
    'stream/**/*.ytd',
    'stream/**/*visual.ydr',
    'stream/**/*proxy.ydr',
    'stream/**/*dcl.ydr',
    'stream/**/*dcl*.ydr',
    'stream/**/*light.ydr',
    'stream/**/*light*.ydr',
    'stream/**/*ceiling.ydr',
    'stream/**/*ceiling*.ydr',
    'stream/**/*plants*.ydr',
    'stream/**/*mirror.ydr',
    'stream/**/*miror*.ydr',
    'stream/**/*food.ydr',
    'stream/**/*barrier*.ydr',
    'stream/**/*rails*.ydr',
    'stream/**/*pipe*.ydr',
    'config.lua',
    'client/ipl_manager.lua',
    'stream/int_main/gn_vspd_main_r01_recept_text.ydr',
    'stream/int_main/gn_vspd_tv_scrn_main_lobby.ydr',
    'stream/int_main/gn_vspd_tv_scrn_main_waintinglobby.ydr',
    'stream/int_main/gn_vspd_tv_scrn_main_corridorback.ydr',
    'stream/int_floor1/gn_vspd_tv_scrn_floor1_meeting.ydr',
    'stream/int_floor1/gn_vspd_tv_scrn_floor1_meeting_b.ydr',
    'stream/int_floor4/gn_vspd_tv_scrn_f4_waiting.ydr',
    'stream/int_floor4/gn_vspd_tv_scrn_f4_meeting.ydr',
    'stream/int_ungrd/gn_vspd_tv_scrn_ungrd_briefing.ydr',
    'stream/assets/prop_gn_vspd_glassdoor1_l.ydr',
    'stream/assets/prop_gn_vspd_glassdoor1_r.ydr'
}
dependency '/assetpacks'