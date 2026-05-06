Elevator = Elevator or {}
Elevator.Config = Elevator.Config or {}

Elevator.Config.IsDev = GetConvarInt("sh_dev", 0) == 1
Elevator.Config.MoveTime = 4

Elevator.Config.BaseKey = "gn_vsc_elv_"
Elevator.Config.Language = "en"

-- Door timing configurations (in seconds)
Elevator.Config.DoorOpenTime = 2    -- Time to open doors
Elevator.Config.DoorWaitTime = 1    -- Time doors stay open
Elevator.Config.DoorCloseTime = 2   -- Time to close doors

Elevator.Config.DisableInteraction = false -- If true, allow to set a custom system to interact with the elevator

Elevator.Config.States = {
    first_elevator = {
        rtTexture = "gn_elev_col_1_ext",
        rtModel = "script_rt_gn_vspd_elev_num_01",
        rtTexture2 = "gn_elev_col_1_int",
        rtModel2 = "gn_vspd_lift_01",
        baseTexture = "script_rt_gn_elev_col_1_int",
        model = "gn_vspd_lift_01",
        position = vec3(-1096.7806396484, -849.98577880859, 19.516122817993),
        rotation = vec3(0, 0, 38.2510077),
        distance = 15.0,
        ipls = { "gn_vspd_strm_ipl", "int_gn_vspd_main_milo_", "int_gn_vspd_floor3_milo_", "int_gn_vspd_floor4_milo_", "int_gn_vspd_garage_milo_" },
        entitySets = {
            { name = "vspd_main_liftdoor",   position = vec3(-1085.496, -832.734253, 23.01342) },
            { name = "vspd_garage_liftdoor", position = vec3(-1095.64331, -831.7493, 10.7244015) },
            { name = "vspd_floor3_liftdoor", position = vec3(-1099.89331, -835.1595, 31.5183849) },
            { name = "vspd_floor4_liftdoor", position = vec3(-1100.0426, -835.04364, 36.82528) },
        },
        outsidePanel = { position = vec2(-1097.83, -848.65), radius = 1.5, animOffset = vec3(-0.85896646976471, -0.35962551832199, 0.0), model = "prop_gn_vspd_elev_panel_01" },
        doorLeft = { rotation = vec3(0, 0, 38.2510077 + 180), position = vec3(-1096.6864013672, -848.89770507812, 4.0578351020813), model = "v_ilev_garageliftdoor" },
        doorRight = { rotation = vec3(0, 0, -141.7489923 + 180), position = vec3(-1097.8643798828, -849.82629394531, 4.0578331947327), model = "v_ilev_garageliftdoor" },
        doorOffset = 4.0578351020813 - 5.264835357666,
        insidePanelOffset = vec3(1.0475616455078, 0.66312754154205, 0.093784332275391),
        floors = {
            {
                label = "Garage (P)",
                indicator = "-2",
                position = vec3(-1096.7806396484, -849.98577880859, 5.264835357666),
                rotation = vec3(0, 0, -38.2510077),
                texture = "script_rt_gn_elev_numfloor_-2",
                panel = vec3(-1098.141, -849.79, 4.061),
                doors = {
                    left = {
                        position = vec3(-1096.7569580078, -848.81158447266, 4.0613479614258)
                    },
                    right = {
                        position = vec3(-1097.9317626953, -849.73779296875, 4.0613460540771)
                    }
                }
            },
            {
                label = "L1",
                indicator = "1",
                position = vec3(-1096.7806396484, -849.98577880859, 19.516122817993),
                rotation = vec3(0, 0, -38.2510077),
                texture = "script_rt_gn_elev_numfloor_01",
                panel = vec3(-1098.141, -849.79, 18.313),
                doors = {
                    left = { position = vec3(-1096.7569580078, -848.81158447266, 18.312633514404) },
                    right = { position = vec3(-1097.9317626953, -849.73779296875, 18.312633514404) }
                }
            },
            {
                label = "L3",
                indicator = "3",
                position = vec3(-1096.7806396484, -849.98577880859, 27.035245895386),
                rotation = vec3(0, 0, -38.2510077),
                texture = "script_rt_gn_elev_numfloor_03",
                panel = vec3(-1098.141, -849.79, 25.832),
                doors = {
                    left = { position = vec3(-1096.7569580078, -848.81158447266, 25.831756591797) },
                    right = { position = vec3(-1097.9317626953, -849.73779296875, 25.831756591797) }
                }
            },
            {
                label = "L4",
                indicator = "4",
                position = vec3(-1096.7806396484, -849.98577880859, 31.153017044067),
                rotation = vec3(0, 0, -38.2510077),
                texture = "script_rt_gn_elev_numfloor_04",
                panel = vec3(-1098.141, -849.79, 29.95),
                doors = {
                    left = { position = vec3(-1096.7531738281, -848.81292724609, 29.946006774902) },
                    right = { position = vec3(-1097.932, -849.7377, 29.94953) }
                }
            },
            {
                label = "L5",
                indicator = "5",
                position = vec3(-1096.7806396484, -849.98577880859, 34.483459472656),
                rotation = vec3(0, 0, -38.2510077),
                texture = "script_rt_gn_elev_numfloor_05",
                panel = vec3(-1098.141, -849.79, 33.28),
                doors = {
                    left = { position = vec3(-1096.7563476562, -848.80895996094, 33.281959533691) },
                    right = { position = vec3(-1097.9328613281, -849.73931884766, 33.276439666748) }
                }
            },
            {
                label = "Roof Top (rt)",
                indicator = "6",
                position = vec3(-1096.7806396484, -849.98577880859, 38.132328033447),
                rotation = vec3(0, 0, -38.2510077),
                texture = "script_rt_gn_elev_numfloor_06",
                panel = vec3(-1098.136, -849.768, 36.892),
                doors = {
                    left = { position = vec3(-1096.7618408203, -848.83404541016, 36.965579986572) },
                    right = { position = vec3(-1097.9366455078, -849.76025390625, 36.965579986572) }
                }
            }
        }
    },
    second_elevator = {
        rtTexture = "gn_elev_col_2_ext",
        rtModel = "script_rt_gn_vspd_elev_num_02",
        rtTexture2 = "gn_elev_col_2_int",
        rtModel2 = "gn_vspd_lift_02",
        baseTexture = "script_rt_gn_elev_col_2_int",
        model = "gn_vspd_lift_02",
        position = vec3(-1066.5274658203, -833.16033935547, 19.516122817993),
        rotation = vec3(0, 0, 38.2510077),
        distance = 15.0,
        ipls = { "int_gn_vspd_main_milo_", "int_gn_vspd_floor1_milo_", "int_gn_vspd_garage_milo_", "int_gn_vspd_ungrd_milo_" },
        entitySets = {
            { name = "vspd_floor1_liftdoor", position = vec3(-1078.749, -820.513, 28.0773678) },
            { name = "vspd_main_liftdoor",   position = vec3(-1085.496, -832.734253, 23.01342) },
            { name = "vspd_garage_liftdoor", position = vec3(-1095.64331, -831.7493, 10.7244015) },
            { name = "vspd_ungrd_liftdoor",  position = vec3(-1060.08362, -815.795, 12.2015524) },
        },
        outsidePanel = { position = vec2(-1067.33, -832.13), radius = 1.5, animOffset = vec3(-0.85896646976471, -0.35962551832199, 0.0), model = "prop_gn_vspd_elev_panel_01" },
        doorLeft = { rotation = vec3(0, 0, 38.2510077 + 180), position = vec3(-1066.4367675781, -832.07110595703, 4.0614128112793), model = "v_ilev_garageliftdoor" },
        doorRight = { rotation = vec3(0, 0, -141.7489923 + 180), position = vec3(-1067.6115722656, -832.99731445312, 4.0614128112793), model = "v_ilev_garageliftdoor" },
        doorOffset = 4.0578351020813 - 5.264835357666,
        insidePanelOffset = vec3(1.0475616455078, 0.66312754154205, 0.093784332275391),
        floors = {
            {
                label = "Garage (P)",
                indicator = "-2",
                position = vec3(-1066.5274658203, -833.16033935547, 5.2649040222168),
                rotation = vec3(0, 0, -38.2510077),
                texture = "script_rt_gn_elev_numfloor_-2",
                panel = vec3(-1067.888, -832.965, 4.062),
                doors = {
                    left = { position = vec3(-1066.5037841797, -831.98620605469, 4.0614128112793) },
                    right = { position = vec3(-1067.6785888672, -832.91241455078, 4.0614128112793) }
                }
            },
            {
                label = "-1",
                indicator = "-1",
                position = vec3(-1066.5274658203, -833.16033935547, 11.155040740967),
                rotation = vec3(0, 0, -38.2510077),
                texture = "script_rt_gn_elev_numfloor_-1",
                panel = vec3(-1067.888, -832.965, 9.952),
                doors = {
                    left = { position = vec3(-1066.5036621094, -831.98620605469, 9.9515514373779) },
                    right = { position = vec3(-1067.6784667969, -832.91235351562, 9.9515514373779) }
                }
            },
            {
                label = "L1",
                indicator = "1",
                position = vec3(-1066.5274658203, -833.16033935547, 19.515947341919),
                rotation = vec3(0, 0, -38.2510077),
                texture = "script_rt_gn_elev_numfloor_01",
                panel = vec3(-1067.888, -832.965, 18.313),
                doors = {
                    left = { position = vec3(-1066.5037841797, -831.98614501953, 18.31245803833) },
                    right = { position = vec3(-1067.6785888672, -832.91235351562, 18.31245803833) }
                }
            },
            {
                label = "L2",
                indicator = "2",
                position = vec3(-1066.5274658203, -833.16033935547, 23.274580001831),
                rotation = vec3(0, 0, -38.2510077),
                texture = "script_rt_gn_elev_numfloor_02",
                panel = vec3(-1067.888, -832.965, 22.071),
                doors = {
                    left = { position = vec3(-1066.5037841797, -831.98614501953, 22.071090698242) },
                    right = { position = vec3(-1067.6785888672, -832.91235351562, 22.071090698242) }
                }
            },
            {
                label = "L3",
                indicator = "3",
                position = vec3(-1066.5274658203, -833.16033935547, 27.035552978516),
                rotation = vec3(0, 0, -38.2510077),
                texture = "script_rt_gn_elev_numfloor_03",
                panel = vec3(-1067.888, -832.965, 25.832),
                doors = {
                    left = { position = vec3(-1066.5036621094, -831.98620605469, 25.832065582275) },
                    right = { position = vec3(-1067.6784667969, -832.91235351562, 25.832063674927) }
                }
            }
        }
    },
}

Elevator.Config.Phrases = {
    en = {
        call_elevator = "~INPUT_CONTEXT~ to call the elevator.",
        select_floor = "~INPUT_CONTEXT~ to select a floor.",
    },
    fr = {
        call_elevator = "~INPUT_CONTEXT~ pour appeler l'ascenseur.",
        select_floor = "~INPUT_CONTEXT~ pour choisir un étage.",
    }
}

function GetStateKey(elevatorId, variable)
    return Elevator.Config.BaseKey .. elevatorId .. variable
end

function GetElevatorConfigs()
    return Elevator.Config.States
end
exports("GetElevatorConfigs", GetElevatorConfigs)