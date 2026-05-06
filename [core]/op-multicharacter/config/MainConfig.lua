-- ─────────────────────────────────────────────────────────────────────────
-- OTHERPLANET / OP Multicharacter - Main Configuration File
-- (Information) ► This file controls language, clothing integration, currency,
--                 spawn selector, starter items, notifications and scenes.
-- (Information) ► Do not rename fields or change structure unless you know
--                 exactly how the script reads this config.
-- ─────────────────────────────────────────────────────────────────────────

Config = {}

-- ─────────────────────────────────────────────────────────────────────────
-- Locale & Debug                                                             
-- (Information) ► Locale controls which translation file is loaded.
-- (Information) ► Debug enables extra prints/logs for troubleshooting.
-- ─────────────────────────────────────────────────────────────────────────
Config.Locale = "en" -- Supported: EN / FR / HR / HU / LT / SK / SL / CZ / SV / TR / DE / EL / ES / PL
Config.Debug = false
Config.DisableBlackScreens = false
Config.DisableBugHunter = false
Config.EnableNativeBlackScreens = false -- Enabled DoScreenFadeIn and DoScreenFadeOut

-- IMPORTANT: DisableBlackScreens will disable all fade in/out animations, additional loading screens etc!

-- ─────────────────────────────────────────────────────────────────────────
-- Clothing & Tattoo System Detection                                             
-- (Information) ► Following clothing scripts will not start cutscene/spawn selector after character created: tgiann-clothing
-- ─────────────────────────────────────────────────────────────────────────

-- SUPPORTED CLOTHING SCRIPTS
-- skinchanger
-- crm-appearance
-- fivem-appearance
-- illenium-appearance
-- qb-clothing
-- rcore_clothing
-- tgiann-clothing
-- qs-appearance
-- qf_skinmenu
-- p_appearance
-- sn_appearance
-- origen_clothing
-- 4bit_appearance
-- bl_appearance
-- aty_clothing (integration is in beta phase)

Config.Clothing = "illenium-appearance"

-- SUPPORTED TATTOOS SCRIPTS
-- rcore_tattoos

Config.Tattoos = "none" -- none / rcore_tattoos

-- ─────────────────────────────────────────────────────────────────────────
-- Housing System Detection                                                  
-- (Information) ► Set your housing script to give started house for player
-- ─────────────────────────────────────────────────────────────────────────

-- SUPPORTED HOUSING SCRIPTS
-- nolag_properties
-- vms_housing
-- rtx_housing
-- bcs_housing

Config.Housing = "none" 

-- ─────────────────────────────────────────────────────────────────────────
-- Notify System Detection                                                  
-- (Information) ► Set your notification script
-- ─────────────────────────────────────────────────────────────────────────

-- Notify scripts:
-- okokNotify
-- vms_notify
-- ox_lib
-- brutal_notify
-- op_hud
-- ESX
-- QBCORE
-- QBOX

Config.Notify = "ox_lib"

-- ─────────────────────────────────────────────────────────────────────────
-- Currency Formatting                                                       
-- (Information) ► Visual currency format used in UI (JS Intl.NumberFormat).
-- (Information) ► Does not change actual economy, only how numbers are shown.
-- ─────────────────────────────────────────────────────────────────────────
Config.CurrencySettings = {
    -- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/NumberFormat
    currency = "USD",
    style    = "currency",
    format   = "en-US"
}

-- ─────────────────────────────────────────────────────────────────────────
-- Start Cutscene                                                            
-- (Information) ► Enables or disables the initial intro cutscene for players.
-- ─────────────────────────────────────────────────────────────────────────
Config.EnableStartCutScene = false
Config.CutSceneData = {
    welcomeTextHeader = "OTHERPLANET",
    welcomeTextDesc = "Welcome on the best server!"
}

-- ─────────────────────────────────────────────────────────────────────────
-- Player Switch Function                                                           
-- (Information) ► Enables or disables the player switch (Map zoom and zoom-out).
-- (Information) ► If you disabled Spawn Selector you can also adjust start
-- coordinates here!
-- ─────────────────────────────────────────────────────────────────────────
Config.SwitchPlayer = {
    enable = true, -- This will work only if spawn selector is disabled!
    startCoords = vec4(-1041.1938, -2744.3838, 21.3594, 330.1611), -- This will work only if spawn selector is disabled!
    disableSwitchOnNewCharacter = true, -- Disables switch on new character
}

-- ─────────────────────────────────────────────────────────────────────────
-- Spawn Selector                                                             
-- (Information) ► Controls the spawn menu that appears after character select.
-- (Information) ► "isLastLocation = true" will use last saved coordinates.
-- (Information) ► "spawnCoords = vec4(...)" defines static spawn locations.
-- ─────────────────────────────────────────────────────────────────────────
Config.SpawnSelector = {
    enable = false, 
    enableOnlyForNewCharacters = false,
    cameraDuration = 3000,
    locations = {
        ["1"] = {
            isLastLocation = true,
            spawnCoords    = false,
            label          = "Last Location",
            image          = "https://img.gta5-mods.com/q95/images/felix-s-movie-like-reshade/3d87bc-GTA52019-11-0912-35-04_Easy-Resize.com.jpg"
        },
        ["2"] = {
            isLastLocation = false,
            spawnCoords    = vec4(-268.8336, -956.3636, 30.2231, 205.1087),
            label          = "Los Santos",
            image          = "https://cdn.mos.cms.futurecdn.net/9QfCTPwV3DkPuUgBHrorom-1200-80.jpg"
        },
        ["3"] = {
            isLastLocation = false,
            spawnCoords    = vec4(-19.8265, 6497.2964, 30.5491, 51.6798),
            label          = "Paleto Bay",
            image          = "https://c4.wallpaperflare.com/wallpaper/143/671/687/grand-theft-auto-online-grand-theft-auto-v-mountain-chiliad-chiliad-mountain-state-wilderness-state-wilderness-paleto-bay-los-santos-wallpaper-preview.jpg"
        },
        ["4"] = {
            isLastLocation = false,
            spawnCoords    = vec4(1527.3490, 3774.9458, 33.5113, 193.8923),
            label          = "Sandy Shores",
            image          = "https://img.gta5-mods.com/q75/images/sandy-shores-remaster-ymap/c276b2-SandyShores1-min.png"
        },
    }
}

-- ─────────────────────────────────────────────────────────────────────────
-- Server Branding (UI Text & Logos)                                          
-- (Information) ► Controls server name, description and logo in the UI.
-- ─────────────────────────────────────────────────────────────────────────
Config.ServerDetails = {
    serverName        = "5STAR ROLEPLAY",
    serverCreatorDesc = "Create your new character and start journey on the best FiveM server.",
    serverLogo        = "https://data.otherplanet.dev/img/op-white.png"
}

-- ─────────────────────────────────────────────────────────────────────────
-- Starter Items                                                              
-- (Information) ► Optional items/money granted to new characters.
-- (Information) ► Works separately from itemShop in Config.Misc.
-- ─────────────────────────────────────────────────────────────────────────
Config.StarterItems = {
    enable = false,
    list = {
        {
            type      = "item",
            nameSpawn = "bread",
            quanity   = 3
        },
        {
            type      = "money", -- money, bank
            nameSpawn = "",      -- leave blank
            quanity   = 5000
        }
    }
}

-- ─────────────────────────────────────────────────────────────────────────
-- Miscellaneous Settings                                                     
-- (Information) ► General behaviour: notifications, character slots and
--                 optional item shop available on character creation.
-- ─────────────────────────────────────────────────────────────────────────
Config.Misc = {
    DefaultCharsAmount = 3,
    AllowCharacterDelete = true, 
    itemShop = {
        enable = true,
        money  = 6500, -- Starting budget for shop purchases
        items  = {
            {
                type      = "item",
                nameSpawn = "bread",
                label     = "Sandwich",
                price     = 500,
                maxQuanity = 5,
                image     = "https://data.otherplanet.dev/fivemicons/%5bfood%5d/hornsandwich.png",
            },
            {
                type      = "item",
                nameSpawn = "water",
                label     = "Water",
                price     = 250,
                maxQuanity = 5,
                image     = "https://data.otherplanet.dev/fivemicons/%5bfood%5d/water_bottle.png",
            },
            {
                type      = "item",
                nameSpawn = "phone",
                label     = "Phone",
                price     = 1500,
                maxQuanity = 1,
                image     = "https://data.otherplanet.dev/fivemicons/%5belectronics%5d/ifruit_blue.png",
            },
            {
                type      = "item",
                nameSpawn = "energydrink",
                label     = "Energy Drink",
                price     = 750,
                maxQuanity = 3,
                image     = "https://data.otherplanet.dev/fivemicons/%5bfood%5d/sprunk.png",
            },
            {
                type      = "car",
                nameSpawn = "blista",
                label     = "Blista",
                price     = 2000,
                maxQuanity = 1,
                image     = "https://cdn.majestic-files.com/public/master/static/img/vehicles/blista.png",
            },
            {
                type      = "car",
                nameSpawn = "bmx",
                label     = "BMX",
                price     = 800,
                maxQuanity = 1,
                image     = "https://cdn.majestic-files.com/public/master/static/img/vehicles/bmx.png",
            },
        }
    }
}

-- ─────────────────────────────────────────────────────────────────────────
-- Scenes Configuration                                                       
-- (Information) ► Defines cinematic scenes used for character selection.
-- (Information) ► Includes camera paths, characters placements, props,
--                 vehicles and weather presets per scene.
-- ─────────────────────────────────────────────────────────────────────────
Config.Scenes = {
    ["scene_1"] = {
        SceneCoords = vec4(49.2859, 7184.5527, 2.4002, 64.6467), -- Player will be teleported to this coords! This is really important.
        InitialCamTime          = 7.0,
        InitialCamCoords        = vec4(34.9546, 7199.9526, 10.2047, 248.3370),
        InitialCamLookAtCoords  = vec4(66.0174, 7188.3491, 1.4332, 59.7735),

        charactersPlacement = {
            {
                coords = vec4(67.7456, 7194.3882, 1.5501, 42.4638),
                animation = {
                    Dict = "missdocksshowoffcar@idle_a",
                    Lib  = "idle_b_5"
                },
                prop = false,
                weapon = false,
                camera = {
                    toCoords = vec4(64.6069, 7200.0630, 2.8786, 227.4351),
                    zoom     = 20.0,
                    duration = 2.0,
                },
                insideVehicle     = false,
                insideVehicleSeat = 0,
            },
            {
                coords    = vec4(66.0174, 7188.3491, 1.4332, 59.7735),
                animation = false,
                prop = false,
                weapon = false,
                camera = {
                    toCoords = vec4(61.9422, 7192.1289, 2.8725, 227.2279),
                    zoom     = 20.0,
                    duration = 3.0,
                },
                insideVehicle     = false, -- unique identifier of vehicle which you add in vehicles section.
                insideVehicleSeat = 1,       -- 1-4 Seat in vehicle
            },
            {
                coords = vec4(59.7110, 7183.2471, 1.6228, 322.9862),
                animation = {
                    Dict = "amb@world_human_drinking@coffee@male@idle_a",
                    Lib  = "idle_c"
                },
                prop = {
                    Prop = "ba_prop_battle_whiskey_bottle_2_s",
                    PropBone = 28422,
                    PropPlacement = {
                        0.0,
                        0.0,
                        0.05,
                        0.0,
                        0.0,
                        0.0
                    }
                },
                weapon = false,
                camera = {
                    toCoords = vec4(60.7500, 7188.7920, 2.8235, 170.8597),
                    zoom     = 20.0,
                    duration = 3.0,
                },
                insideVehicle     = false,
                insideVehicleSeat = 0,
            },
        },

        newCharacter = {
            -- Coords where you will create new character
            coords = vec4(-763.3376, 329.4693, 198.4861, 183.4883)
        },

        vehicles = {},

        customProps = {
            {
                name  = "xm_prop_base_tripod_lampb",
                coords = vec4(69.9330, 7188.8125, 1.1861, 274.8404),
            },
            {
                name  = "xm_prop_base_tripod_lampb",
                coords = vec4(67.5469, 7186.2432, 1.2403, 179.5323),
            },
        },
        weather = {
            hour    = 23,
            minute  = 0,
            weather = "SMOG", 
            -- EXTRASUNNY
            -- CLEAR
            -- CLOUDS
            -- SMOG
            -- FOGGY
            -- OVERCAST
            -- RAIN
            -- THUNDER
            -- CLEARING
            -- NEUTRAL
            -- SNOW
            -- BLIZZARD
            -- SNOWLIGHT
            -- XMAS
            -- HALLOWEEN
        }
    },
    --[[["cayo"] = {
        SceneCoords = vec4(4893.3608, -4903.8926, 3.4867, 174.4742), -- Player will be teleported to this coords! This is really important.
        InitialCamTime          = 7.0,
        InitialCamCoords        = vec4(4858.5122, -4922.6084, 11.4874, 220.0356),
        InitialCamLookAtCoords  = vec4(4881.5386, -4951.0298, 2.5879, 29.2787),

        charactersPlacement = {
            {
                coords = vec4(4881.5386, -4951.0298, 2.5879, 29.2787),
                animation = {
                    Dict = "anim_heist@arcade_combined@",
                    Lib  = "ped_female@_stand@_03b@_base_base"
                },
                prop = false,
                weapon = false,
                camera = {
                    toCoords = vec4(4880.2852, -4946.5171, 3.4353, 201.5674),
                    zoom     = 30.0,
                    duration = 3.0,
                },
                insideVehicle     = false,
                insideVehicleSeat = 0,
            },
            {
                coords    = vec4(4874.4858, -4952.9634, 3.2330, 359.0229),
                animation = {
                    Dict = "mrwitt@chin_support_on_floor",
                    Lib = "mrwitt"
                },
                prop = false,
                weapon = false,
                camera = {
                    toCoords = vec4(4876.6748, -4946.3887, 3.5261, 149.4190),
                    zoom     = 20.0,
                    duration = 3.0,
                },
                insideVehicle     = false, -- unique identifier of vehicle which you add in vehicles section.
                insideVehicleSeat = 0,       -- 1-4 Seat in vehicle
            }
        },
        newCharacter = {
            -- Coords where you will create new character
            coords = vec4(-763.3376, 329.4693, 198.4861, 183.4883)
        },
        vehicles = {},
        customProps = {},
        weather = {
            hour    = 12,
            minute  = 0,
            weather = "EXTRASUNNY", 
            -- EXTRASUNNY
            -- CLEAR
            -- CLOUDS
            -- SMOG
            -- FOGGY
            -- OVERCAST
            -- RAIN
            -- THUNDER
            -- CLEARING
            -- NEUTRAL
            -- SNOW
            -- BLIZZARD
            -- SNOWLIGHT
            -- XMAS
            -- HALLOWEEN
        }
    },
    --[[["xmas"] = {
        SceneCoords = vec4(173.6660, -912.0629, 31.3267, 258.4043), -- Player will be teleported to this coords! This is really important.
        InitialCamTime          = 7.0,
        InitialCamCoords        = vec4(190.3594, -941.9056, 35.9057, 47.8419),
        InitialCamLookAtCoords  = vec4(165.9147, -919.8946, 32.8227, 47.9994),

        charactersPlacement = {
            {
                coords    = vec4(163.3140, -926.8589, 30.6239, 218.1640),
                animation = {
                    Dict = "anim@scripted@player@fix_astu_ig8_weed_smoke_v1@male@",
                    Lib = "male_pos_a_p2_base"
                },
                prop = false,
                weapon = false,
                camera = {
                    toCoords = vec4(169.6110, -926.8345, 31.3267, 75.3578),
                    zoom     = 20.0,
                    duration = 3.0,
                },
                insideVehicle     = false, -- unique identifier of vehicle which you add in vehicles section.
                insideVehicleSeat = 0,       -- 1-4 Seat in vehicle
            },
            {
                coords = vec4(165.9431, -918.2198, 30.3717, 192.0681),
                animation = {
                    Dict = "anim@scripted@freemode@ig7_office_cell_floor@heeled@",
                    Lib  = "base_pose_01"
                },
                prop = false,
                weapon = false,
                camera = {
                    toCoords = vec4(168.6161, -925.0262, 31.3221, 11.7331),
                    zoom     = 50.0,
                    duration = 3.0,
                },
                insideVehicle     = false,
                insideVehicleSeat = 0,
            },
            {
                coords = vec4(173.1998, -917.3516, 30.3267, 151.3287),
                animation = {
                    Dict = "amb@world_human_aa_coffee@base",
                    Lib  = "base"
                },
                prop = {
                    Prop = "pata_christmasfood1",
                    PropBone = 28422,
                    PropPlacement = {
                        0.0100,
                        -0.1100,
                        -0.1300,
                        0.0,
                        0.0,
                        0.0
                    }
                },
                weapon = false,
                camera = {
                    toCoords = vec4(165.6446, -922.1199, 32.7531, 302.8799),
                    zoom     = 40.0,
                    duration = 3.0,
                },
                insideVehicle     = false,
                insideVehicleSeat = 0,
            },
        },
        newCharacter = {
            -- Coords where you will create new character
            coords = vec4(-763.3376, 329.4693, 198.4861, 183.4883)
        },
        vehicles = {},
        customProps = {},
        weather = {
            hour    = 21,
            minute  = 0,
            weather = "XMAS", 
            -- EXTRASUNNY
            -- CLEAR
            -- CLOUDS
            -- SMOG
            -- FOGGY
            -- OVERCAST
            -- RAIN
            -- THUNDER
            -- CLEARING
            -- NEUTRAL
            -- SNOW
            -- BLIZZARD
            -- SNOWLIGHT
            -- XMAS
            -- HALLOWEEN
        }
    },--]]
}

-- ──────────────────────────────────────────────────────────────────────────────
-- HUD Switch                                                    
-- (Information) ► Function will toggle hud when needed to provide best user experience!
-- ──────────────────────────────────────────────────────────────────────────────

Config.SwitchHud = function(toggle)
    if toggle then
        DisplayRadar(true)
        --TriggerEvent('op-hud:toggleHud', true)
        -- Display HUD
    else
        Citizen.CreateThread(function()
            Wait(1000)
            DisplayRadar(false)
            --TriggerEvent('op-hud:toggleHud', false)
            -- Hide HUD
        end)   
    end
end