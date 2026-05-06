fx_version "cerulean"
game "gta5"
lua54 "yes"

name "okw_hud_health_ecg"
author "OKW"
version "1.0.0"
description "ECG / BPM strip under player status HUD (transparent overlay)."

ui_page "web/index.html"

files {
    "web/index.html",
}

shared_script "config.lua"
client_script "client.lua"
