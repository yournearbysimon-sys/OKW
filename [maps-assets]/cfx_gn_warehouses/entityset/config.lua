Config = {}

Config.Interiors = {
    {   -- Location 1
        ipl = 'gn_warehouse_01_milo_',
        coords = vec3(831.335, -951.411, 27.959),
        entitySets = {
            { name = 'wh_b_empty', enable = false },            -- Empty warehouse with light      
            -- # Storage
            { name = 'wh_b_storage_a_empty', enable = true },   -- Simple empty storage
            { name = 'wh_b_storage_a_01', enable = true },      -- With more props
            -- # Meth laboratory
            { name = 'wh_b_meth_empty', enable = false },       -- Meth lab with machine only / not in operation
            { name = 'wh_b_meth_01', enable = false },          -- With more props / in operation
            -- # Coke laboratory
            { name = 'wh_b_coke_empty', enable = false },       -- Cocaine laboratory / not in operation
            { name = 'wh_b_coke_01', enable = false },          -- With more props / in operation
            -- # Storage b & weapon factory
            { name = 'wh_b_storage_b_empty', enable = false },  -- Simple empty storage (B)
            { name = 'wh_b_storage_b_weapon', enable = false }, -- Weapon factory with stotage (B)
            -- # Weed farms
            { name = 'wh_b_weed_empty', enable = false },       -- Weed farms / not in operation
            { name = 'wh_b_weed_stage_1a', enable = false },    -- Stage 1 weed plant
            { name = 'wh_b_weed_stage_1b', enable = false },    -- Stage 2 weed plant
            { name = 'wh_b_weed_stage_1c', enable = false },    -- Stage 3 weed plant
            { name = 'wh_b_weed_stage_1d', enable = false },    -- Stage 4 weed plant
            { name = 'wh_b_weed_stage_2a', enable = false },    -- Weed drying
            { name = 'wh_b_weed_storage', enable = false }      -- Weed storage
        }
    },
    {   -- Location 2
        ipl = 'gn_warehouse_02_milo_',
        coords = vec3(748.0043, -1290.9478, 27.71616),
        entitySets = {
            { name = 'wh_s_empty', enable = false },            -- Empty warehouse with light      
            -- # Storage
            { name = 'wh_s_storage_a_empty', enable = true },   -- Simple empty storage
            { name = 'wh_s_storage_a_01', enable = true },      -- With more props
            -- # Meth laboratory
            { name = 'wh_s_meth_empty', enable = false },       -- Meth lab with machine only / not in operation
            { name = 'wh_s_meth_01', enable = false },          -- With more props / in operation
            -- # Coke laboratory
            { name = 'wh_s_coke_empty', enable = false },       -- Cocaine laboratory / not in operation
            { name = 'wh_s_coke_01', enable = false },          -- With more props / in operation
            -- # Storage b & weapon factory
            { name = 'wh_s_storage_b_empty', enable = false },  -- Simple empty storage (B)
            { name = 'wh_s_storage_b_weapon', enable = false }, -- Weapon factory with stotage (B)
            -- # Weed farms
            { name = 'wh_s_weed_empty', enable = false },       -- Weed farms / not in operation
            { name = 'wh_s_weed_stage_1a', enable = false },    -- Stage 1 weed plant
            { name = 'wh_s_weed_stage_1b', enable = false },    -- Stage 2 weed plant
            { name = 'wh_s_weed_stage_1c', enable = false },    -- Stage 3 weed plant
            { name = 'wh_s_weed_stage_1d', enable = false },    -- Stage 4 weed plant
            { name = 'wh_s_weed_stage_2a', enable = false }    -- Weed drying
        }
    },
    {   -- Location 3
        ipl = 'gn_warehouse_03_milo_',
        coords = vec3(941.46515, -1556.3794, 32.526455),
        entitySets = {
            { name = 'wh_b_empty', enable = false },            -- Empty warehouse with light      
            -- # Storage
            { name = 'wh_b_storage_a_empty', enable = false },   -- Simple empty storage
            { name = 'wh_b_storage_a_01', enable = false },      -- With more props
            -- # Meth laboratory
            { name = 'wh_b_meth_empty', enable = true },       -- Meth lab with machine only / not in operation
            { name = 'wh_b_meth_01', enable = true },          -- With more props / in operation
            -- # Coke laboratory
            { name = 'wh_b_coke_empty', enable = false },       -- Cocaine laboratory / not in operation
            { name = 'wh_b_coke_01', enable = false },          -- With more props / in operation
            -- # Storage b & weapon factory
            { name = 'wh_b_storage_b_empty', enable = false },  -- Simple empty storage (B)
            { name = 'wh_b_storage_b_weapon', enable = false }, -- Weapon factory with stotage (B)
            -- # Weed farms
            { name = 'wh_b_weed_empty', enable = false },       -- Weed farms / not in operation
            { name = 'wh_b_weed_stage_1a', enable = false },    -- Stage 1 weed plant
            { name = 'wh_b_weed_stage_1b', enable = false },    -- Stage 2 weed plant
            { name = 'wh_b_weed_stage_1c', enable = false },    -- Stage 3 weed plant
            { name = 'wh_b_weed_stage_1d', enable = false },    -- Stage 4 weed plant
            { name = 'wh_b_weed_stage_2a', enable = false },    -- Weed drying
            { name = 'wh_b_weed_storage', enable = false }      -- Weed storage
        }
    },
    {   -- Location 4
        ipl = 'gn_warehouse_04_milo_',
        coords = vec3(937.27466, -1697.1504, 31.52084),
        entitySets = {
            { name = 'wh_s_empty', enable = false },            -- Empty warehouse with light      
            -- # Storage
            { name = 'wh_s_storage_a_empty', enable = false },   -- Simple empty storage
            { name = 'wh_s_storage_a_01', enable = false },      -- With more props
            -- # Meth laboratory
            { name = 'wh_s_meth_empty', enable = true },       -- Meth lab with machine only / not in operation
            { name = 'wh_s_meth_01', enable = true },          -- With more props / in operation
            -- # Coke laboratory
            { name = 'wh_s_coke_empty', enable = false },       -- Cocaine laboratory / not in operation
            { name = 'wh_s_coke_01', enable = false },          -- With more props / in operation
            -- # Storage b & weapon factory
            { name = 'wh_s_storage_b_empty', enable = false },  -- Simple empty storage (B)
            { name = 'wh_s_storage_b_weapon', enable = false }, -- Weapon factory with stotage (B)
            -- # Weed farms
            { name = 'wh_s_weed_empty', enable = false },       -- Weed farms / not in operation
            { name = 'wh_s_weed_stage_1a', enable = false },    -- Stage 1 weed plant
            { name = 'wh_s_weed_stage_1b', enable = false },    -- Stage 2 weed plant
            { name = 'wh_s_weed_stage_1c', enable = false },    -- Stage 3 weed plant
            { name = 'wh_s_weed_stage_1d', enable = false },    -- Stage 4 weed plant
            { name = 'wh_s_weed_stage_2a', enable = false }    -- Weed drying
        }
    },
    {   -- Location 5
        ipl = 'gn_warehouse_05_milo_',
        coords = vec3(858.12476, -2380.473, 31.777784),
        entitySets = {
            { name = 'wh_s_empty', enable = false },            -- Empty warehouse with light      
            -- # Storage
            { name = 'wh_s_storage_a_empty', enable = false },   -- Simple empty storage
            { name = 'wh_s_storage_a_01', enable = false },      -- With more props
            -- # Meth laboratory
            { name = 'wh_s_meth_empty', enable = false },       -- Meth lab with machine only / not in operation
            { name = 'wh_s_meth_01', enable = false },          -- With more props / in operation
            -- # Coke laboratory
            { name = 'wh_s_coke_empty', enable = false },       -- Cocaine laboratory / not in operation
            { name = 'wh_s_coke_01', enable = true },          -- With more props / in operation
            -- # Storage b & weapon factory
            { name = 'wh_s_storage_b_empty', enable = false },  -- Simple empty storage (B)
            { name = 'wh_s_storage_b_weapon', enable = false }, -- Weapon factory with stotage (B)
            -- # Weed farms
            { name = 'wh_s_weed_empty', enable = false },       -- Weed farms / not in operation
            { name = 'wh_s_weed_stage_1a', enable = false },    -- Stage 1 weed plant
            { name = 'wh_s_weed_stage_1b', enable = false },    -- Stage 2 weed plant
            { name = 'wh_s_weed_stage_1c', enable = false },    -- Stage 3 weed plant
            { name = 'wh_s_weed_stage_1d', enable = false },    -- Stage 4 weed plant
            { name = 'wh_s_weed_stage_2a', enable = false }    -- Weed drying
        }
    },
    {   -- Location 6
        ipl = 'gn_warehouse_06_milo_',
        coords = vec3(1072.1244, -2402.5798, 32.006943),
        entitySets = {
            { name = 'wh_b_empty', enable = false },            -- Empty warehouse with light      
            -- # Storage
            { name = 'wh_b_storage_a_empty', enable = false },   -- Simple empty storage
            { name = 'wh_b_storage_a_01', enable = false },      -- With more props
            -- # Meth laboratory
            { name = 'wh_b_meth_empty', enable = false },       -- Meth lab with machine only / not in operation
            { name = 'wh_b_meth_01', enable = false },          -- With more props / in operation
            -- # Coke laboratory
            { name = 'wh_b_coke_empty', enable = true },       -- Cocaine laboratory / not in operation
            { name = 'wh_b_coke_01', enable = true },          -- With more props / in operation
            -- # Storage b & weapon factory
            { name = 'wh_b_storage_b_empty', enable = false },  -- Simple empty storage (B)
            { name = 'wh_b_storage_b_weapon', enable = false }, -- Weapon factory with stotage (B)
            -- # Weed farms
            { name = 'wh_b_weed_empty', enable = false },       -- Weed farms / not in operation
            { name = 'wh_b_weed_stage_1a', enable = false },    -- Stage 1 weed plant
            { name = 'wh_b_weed_stage_1b', enable = false },    -- Stage 2 weed plant
            { name = 'wh_b_weed_stage_1c', enable = false },    -- Stage 3 weed plant
            { name = 'wh_b_weed_stage_1d', enable = false },    -- Stage 4 weed plant
            { name = 'wh_b_weed_stage_2a', enable = false },    -- Weed drying
            { name = 'wh_b_weed_storage', enable = false }      -- Weed storage
        }
    },
    {   -- Location 7
        ipl = 'gn_warehouse_07_milo_',
        coords = vec3(1204.6417, -3124.1738, 6.9598494),
        entitySets = {
            { name = 'wh_b_empty', enable = false },            -- Empty warehouse with light      
            -- # Storage
            { name = 'wh_b_storage_a_empty', enable = false },   -- Simple empty storage
            { name = 'wh_b_storage_a_01', enable = false },      -- With more props
            -- # Meth laboratory
            { name = 'wh_b_meth_empty', enable = false },       -- Meth lab with machine only / not in operation
            { name = 'wh_b_meth_01', enable = false },          -- With more props / in operation
            -- # Coke laboratory
            { name = 'wh_b_coke_empty', enable = false },       -- Cocaine laboratory / not in operation
            { name = 'wh_b_coke_01', enable = false },          -- With more props / in operation
            -- # Storage b & weapon factory
            { name = 'wh_b_storage_b_empty', enable = true },  -- Simple empty storage (B)
            { name = 'wh_b_storage_b_weapon', enable = true }, -- Weapon factory with stotage (B)
            -- # Weed farms
            { name = 'wh_b_weed_empty', enable = false },       -- Weed farms / not in operation
            { name = 'wh_b_weed_stage_1a', enable = false },    -- Stage 1 weed plant
            { name = 'wh_b_weed_stage_1b', enable = false },    -- Stage 2 weed plant
            { name = 'wh_b_weed_stage_1c', enable = false },    -- Stage 3 weed plant
            { name = 'wh_b_weed_stage_1d', enable = false },    -- Stage 4 weed plant
            { name = 'wh_b_weed_stage_2a', enable = false },    -- Weed drying
            { name = 'wh_b_weed_storage', enable = false }      -- Weed storage
        }
    },
    {   -- Location 8
        ipl = 'gn_warehouse_08_milo_',
        coords = vec3(1711.6317, -1539.6176, 114.08106),
        entitySets = {
            { name = 'wh_b_empty', enable = false },            -- Empty warehouse with light      
            -- # Storage
            { name = 'wh_b_storage_a_empty', enable = false },   -- Simple empty storage
            { name = 'wh_b_storage_a_01', enable = false },      -- With more props
            -- # Meth laboratory
            { name = 'wh_b_meth_empty', enable = false },       -- Meth lab with machine only / not in operation
            { name = 'wh_b_meth_01', enable = false },          -- With more props / in operation
            -- # Coke laboratory
            { name = 'wh_b_coke_empty', enable = false },       -- Cocaine laboratory / not in operation
            { name = 'wh_b_coke_01', enable = false },          -- With more props / in operation
            -- # Storage b & weapon factory
            { name = 'wh_b_storage_b_empty', enable = false },  -- Simple empty storage (B)
            { name = 'wh_b_storage_b_weapon', enable = false }, -- Weapon factory with stotage (B)
            -- # Weed farms
            { name = 'wh_b_weed_empty', enable = true },       -- Weed farms / not in operation
            { name = 'wh_b_weed_stage_1a', enable = false },    -- Stage 1 weed plant
            { name = 'wh_b_weed_stage_1b', enable = false },    -- Stage 2 weed plant
            { name = 'wh_b_weed_stage_1c', enable = false },    -- Stage 3 weed plant
            { name = 'wh_b_weed_stage_1d', enable = false },    -- Stage 4 weed plant
            { name = 'wh_b_weed_stage_2a', enable = true },    -- Weed drying
            { name = 'wh_b_weed_storage', enable = true }      -- Weed storage
        }
    },
    {   -- Location 9
        ipl = 'gn_warehouse_09_milo_',
        coords = vec3(-1224.6583, -731.8027, 23.101988),
        entitySets = {
            { name = 'wh_s_empty', enable = false },            -- Empty warehouse with light      
            -- # Storage
            { name = 'wh_s_storage_a_empty', enable = false },   -- Simple empty storage
            { name = 'wh_s_storage_a_01', enable = false },      -- With more props
            -- # Meth laboratory
            { name = 'wh_s_meth_empty', enable = false },       -- Meth lab with machine only / not in operation
            { name = 'wh_s_meth_01', enable = false },          -- With more props / in operation
            -- # Coke laboratory
            { name = 'wh_s_coke_empty', enable = false },       -- Cocaine laboratory / not in operation
            { name = 'wh_s_coke_01', enable = false },          -- With more props / in operation
            -- # Storage b & weapon factory
            { name = 'wh_s_storage_b_empty', enable = true },  -- Simple empty storage (B)
            { name = 'wh_s_storage_b_weapon', enable = true }, -- Weapon factory with stotage (B)
            -- # Weed farms
            { name = 'wh_s_weed_empty', enable = false },       -- Weed farms / not in operation
            { name = 'wh_s_weed_stage_1a', enable = false },    -- Stage 1 weed plant
            { name = 'wh_s_weed_stage_1b', enable = false },    -- Stage 2 weed plant
            { name = 'wh_s_weed_stage_1c', enable = false },    -- Stage 3 weed plant
            { name = 'wh_s_weed_stage_1d', enable = false },    -- Stage 4 weed plant
            { name = 'wh_s_weed_stage_2a', enable = false }    -- Weed drying
        }
    },
    {   -- Location 11
        ipl = 'gn_warehouse_11_milo_',
        coords = vec3(-619.93604, -1770.6952, 25.382507),
        entitySets = {
            { name = 'wh_s_empty', enable = false },            -- Empty warehouse with light      
            -- # Storage
            { name = 'wh_s_storage_a_empty', enable = false },   -- Simple empty storage
            { name = 'wh_s_storage_a_01', enable = false },      -- With more props
            -- # Meth laboratory
            { name = 'wh_s_meth_empty', enable = false },       -- Meth lab with machine only / not in operation
            { name = 'wh_s_meth_01', enable = false },          -- With more props / in operation
            -- # Coke laboratory
            { name = 'wh_s_coke_empty', enable = false },       -- Cocaine laboratory / not in operation
            { name = 'wh_s_coke_01', enable = false },          -- With more props / in operation
            -- # Storage b & weapon factory
            { name = 'wh_s_storage_b_empty', enable = false },  -- Simple empty storage (B)
            { name = 'wh_s_storage_b_weapon', enable = false }, -- Weapon factory with stotage (B)
            -- # Weed farms
            { name = 'wh_s_weed_empty', enable = true },       -- Weed farms / not in operation
            { name = 'wh_s_weed_stage_1a', enable = false },    -- Stage 1 weed plant
            { name = 'wh_s_weed_stage_1b', enable = false },    -- Stage 2 weed plant
            { name = 'wh_s_weed_stage_1c', enable = false },    -- Stage 3 weed plant
            { name = 'wh_s_weed_stage_1d', enable = false },    -- Stage 4 weed plant
            { name = 'wh_s_weed_stage_2a', enable = true }    -- Weed drying
        }
    },
    {   -- Location 12
        ipl = 'gn_warehouse_12_milo_',
        coords = vec3(-83.39932, -1811.9147, 28.375294),
        entitySets = {
            { name = 'wh_b_empty', enable = false },            -- Empty warehouse with light      
            -- # Storage
            { name = 'wh_b_storage_a_empty', enable = false },   -- Simple empty storage
            { name = 'wh_b_storage_a_01', enable = false },      -- With more props
            -- # Meth laboratory
            { name = 'wh_b_meth_empty', enable = false },       -- Meth lab with machine only / not in operation
            { name = 'wh_b_meth_01', enable = false },          -- With more props / in operation
            -- # Coke laboratory
            { name = 'wh_b_coke_empty', enable = false },       -- Cocaine laboratory / not in operation
            { name = 'wh_b_coke_01', enable = false },          -- With more props / in operation
            -- # Storage b & weapon factory
            { name = 'wh_b_storage_b_empty', enable = false },  -- Simple empty storage (B)
            { name = 'wh_b_storage_b_weapon', enable = false }, -- Weapon factory with stotage (B)
            -- # Weed farms
            { name = 'wh_b_weed_empty', enable = true },       -- Weed farms / not in operation
            { name = 'wh_b_weed_stage_1a', enable = false },    -- Stage 1 weed plant
            { name = 'wh_b_weed_stage_1b', enable = false },    -- Stage 2 weed plant
            { name = 'wh_b_weed_stage_1c', enable = true },    -- Stage 3 weed plant
            { name = 'wh_b_weed_stage_1d', enable = false },    -- Stage 4 weed plant
            { name = 'wh_b_weed_stage_2a', enable = true },    -- Weed drying
            { name = 'wh_b_weed_storage', enable = true }      -- Weed storage
        }
    },
    {   -- Location 13
        ipl = 'gn_warehouse_13_milo_',
        coords = vec3(-118.69137, -2506.2393, 7.5335727),
        entitySets = {
            { name = 'wh_s_empty', enable = false },            -- Empty warehouse with light      
            -- # Storage
            { name = 'wh_s_storage_a_empty', enable = false },   -- Simple empty storage
            { name = 'wh_s_storage_a_01', enable = false },      -- With more props
            -- # Meth laboratory
            { name = 'wh_s_meth_empty', enable = true },       -- Meth lab with machine only / not in operation
            { name = 'wh_s_meth_01', enable = true },          -- With more props / in operation
            -- # Coke laboratory
            { name = 'wh_s_coke_empty', enable = false },       -- Cocaine laboratory / not in operation
            { name = 'wh_s_coke_01', enable = false },          -- With more props / in operation
            -- # Storage b & weapon factory
            { name = 'wh_s_storage_b_empty', enable = false },  -- Simple empty storage (B)
            { name = 'wh_s_storage_b_weapon', enable = false }, -- Weapon factory with stotage (B)
            -- # Weed farms
            { name = 'wh_s_weed_empty', enable = false },       -- Weed farms / not in operation
            { name = 'wh_s_weed_stage_1a', enable = false },    -- Stage 1 weed plant
            { name = 'wh_s_weed_stage_1b', enable = false },    -- Stage 2 weed plant
            { name = 'wh_s_weed_stage_1c', enable = false },    -- Stage 3 weed plant
            { name = 'wh_s_weed_stage_1d', enable = false },    -- Stage 4 weed plant
            { name = 'wh_s_weed_stage_2a', enable = false }    -- Weed drying
        }
    },
    {   -- Location 14
        ipl = 'gn_warehouse_14_milo_',
        coords = vec3(-323.65515, -2448.7007, 7.4408236),
        entitySets = {
            { name = 'wh_s_empty', enable = false },            -- Empty warehouse with light      
            -- # Storage
            { name = 'wh_s_storage_a_empty', enable = false },   -- Simple empty storage
            { name = 'wh_s_storage_a_01', enable = false },      -- With more props
            -- # Meth laboratory
            { name = 'wh_s_meth_empty', enable = false },       -- Meth lab with machine only / not in operation
            { name = 'wh_s_meth_01', enable = false },          -- With more props / in operation
            -- # Coke laboratory
            { name = 'wh_s_coke_empty', enable = false },       -- Cocaine laboratory / not in operation
            { name = 'wh_s_coke_01', enable = true },          -- With more props / in operation
            -- # Storage b & weapon factory
            { name = 'wh_s_storage_b_empty', enable = false },  -- Simple empty storage (B)
            { name = 'wh_s_storage_b_weapon', enable = false }, -- Weapon factory with stotage (B)
            -- # Weed farms
            { name = 'wh_s_weed_empty', enable = false },       -- Weed farms / not in operation
            { name = 'wh_s_weed_stage_1a', enable = false },    -- Stage 1 weed plant
            { name = 'wh_s_weed_stage_1b', enable = false },    -- Stage 2 weed plant
            { name = 'wh_s_weed_stage_1c', enable = false },    -- Stage 3 weed plant
            { name = 'wh_s_weed_stage_1d', enable = false },    -- Stage 4 weed plant
            { name = 'wh_s_weed_stage_2a', enable = false }    -- Weed drying
        }
    },
    {   -- Location 15
        ipl = 'gn_warehouse_15_milo_',
        coords = vec3(57.531727, 170.6523, 106.199425),
        entitySets = {
            { name = 'wh_b_empty', enable = false },            -- Empty warehouse with light      
            -- # Storage
            { name = 'wh_b_storage_a_empty', enable = false },   -- Simple empty storage
            { name = 'wh_b_storage_a_01', enable = false },      -- With more props
            -- # Meth laboratory
            { name = 'wh_b_meth_empty', enable = true },       -- Meth lab with machine only / not in operation
            { name = 'wh_b_meth_01', enable = true },          -- With more props / in operation
            -- # Coke laboratory
            { name = 'wh_b_coke_empty', enable = false },       -- Cocaine laboratory / not in operation
            { name = 'wh_b_coke_01', enable = false },          -- With more props / in operation
            -- # Storage b & weapon factory
            { name = 'wh_b_storage_b_empty', enable = false },  -- Simple empty storage (B)
            { name = 'wh_b_storage_b_weapon', enable = false }, -- Weapon factory with stotage (B)
            -- # Weed farms
            { name = 'wh_b_weed_empty', enable = false },       -- Weed farms / not in operation
            { name = 'wh_b_weed_stage_1a', enable = false },    -- Stage 1 weed plant
            { name = 'wh_b_weed_stage_1b', enable = false },    -- Stage 2 weed plant
            { name = 'wh_b_weed_stage_1c', enable = false },    -- Stage 3 weed plant
            { name = 'wh_b_weed_stage_1d', enable = false },    -- Stage 4 weed plant
            { name = 'wh_b_weed_stage_2a', enable = false },    -- Weed drying
            { name = 'wh_b_weed_storage', enable = false }      -- Weed storage
        }
    },
    {   -- Location 16
        ipl = 'gn_warehouse_16_milo_',                          
        coords = vec3(2799.0369, 1457.8043, 25.984213),
        entitySets = {
            { name = 'wh_b_empty', enable = false },            -- Empty warehouse with light      
            -- # Storage
            { name = 'wh_b_storage_a_empty', enable = false },   -- Simple empty storage
            { name = 'wh_b_storage_a_01', enable = false },      -- With more props
            -- # Meth laboratory
            { name = 'wh_b_meth_empty', enable = false },       -- Meth lab with machine only / not in operation
            { name = 'wh_b_meth_01', enable = false },          -- With more props / in operation
            -- # Coke laboratory
            { name = 'wh_b_coke_empty', enable = false },       -- Cocaine laboratory / not in operation
            { name = 'wh_b_coke_01', enable = false },          -- With more props / in operation
            -- # Storage b & weapon factory
            { name = 'wh_b_storage_b_empty', enable = true },  -- Simple empty storage (B)
            { name = 'wh_b_storage_b_weapon', enable = true }, -- Weapon factory with stotage (B)
            -- # Weed farms
            { name = 'wh_b_weed_empty', enable = false },       -- Weed farms / not in operation
            { name = 'wh_b_weed_stage_1a', enable = false },    -- Stage 1 weed plant
            { name = 'wh_b_weed_stage_1b', enable = false },    -- Stage 2 weed plant
            { name = 'wh_b_weed_stage_1c', enable = false },    -- Stage 3 weed plant
            { name = 'wh_b_weed_stage_1d', enable = false },    -- Stage 4 weed plant
            { name = 'wh_b_weed_stage_2a', enable = false },    -- Weed drying
            { name = 'wh_b_weed_storage', enable = false }      -- Weed storage
        }
    },
    {   -- Location 17
        ipl = 'gn_warehouse_17_milo_',                          
        coords = vec3(159.36989, 6373.3604, 32.965424),
        entitySets = {
            { name = 'wh_s_empty', enable = false },            -- Empty warehouse with light      
            -- # Storage
            { name = 'wh_s_storage_a_empty', enable = false },   -- Simple empty storage
            { name = 'wh_s_storage_a_01', enable = false },      -- With more props
            -- # Meth laboratory
            { name = 'wh_s_meth_empty', enable = false },       -- Meth lab with machine only / not in operation
            { name = 'wh_s_meth_01', enable = false },          -- With more props / in operation
            -- # Coke laboratory
            { name = 'wh_s_coke_empty', enable = false },       -- Cocaine laboratory / not in operation
            { name = 'wh_s_coke_01', enable = true },          -- With more props / in operation
            -- # Storage b & weapon factory
            { name = 'wh_s_storage_b_empty', enable = false },  -- Simple empty storage (B)
            { name = 'wh_s_storage_b_weapon', enable = false }, -- Weapon factory with stotage (B)
            -- # Weed farms
            { name = 'wh_s_weed_empty', enable = false },       -- Weed farms / not in operation
            { name = 'wh_s_weed_stage_1a', enable = false },    -- Stage 1 weed plant
            { name = 'wh_s_weed_stage_1b', enable = false },    -- Stage 2 weed plant
            { name = 'wh_s_weed_stage_1c', enable = false },    -- Stage 3 weed plant
            { name = 'wh_s_weed_stage_1d', enable = false },    -- Stage 4 weed plant
            { name = 'wh_s_weed_stage_2a', enable = false }    -- Weed drying
        }
    },
    {   -- Location 18
        ipl = 'gn_warehouse_18_milo_',                          
        coords = vec3(34.39386, 6470.9946, 32.86032),
        entitySets = {
            { name = 'wh_b_empty', enable = false },            -- Empty warehouse with light      
            -- # Storage
            { name = 'wh_b_storage_a_empty', enable = false },   -- Simple empty storage
            { name = 'wh_b_storage_a_01', enable = false },      -- With more props
            -- # Meth laboratory
            { name = 'wh_b_meth_empty', enable = false },       -- Meth lab with machine only / not in operation
            { name = 'wh_b_meth_01', enable = false },          -- With more props / in operation
            -- # Coke laboratory
            { name = 'wh_b_coke_empty', enable = false },       -- Cocaine laboratory / not in operation
            { name = 'wh_b_coke_01', enable = false },          -- With more props / in operation
            -- # Storage b & weapon factory
            { name = 'wh_b_storage_b_empty', enable = false },  -- Simple empty storage (B)
            { name = 'wh_b_storage_b_weapon', enable = false }, -- Weapon factory with stotage (B)
            -- # Weed farms
            { name = 'wh_b_weed_empty', enable = true },       -- Weed farms / not in operation
            { name = 'wh_b_weed_stage_1a', enable = false },    -- Stage 1 weed plant
            { name = 'wh_b_weed_stage_1b', enable = false },    -- Stage 2 weed plant
            { name = 'wh_b_weed_stage_1c', enable = false },    -- Stage 3 weed plant
            { name = 'wh_b_weed_stage_1d', enable = false },    -- Stage 4 weed plant
            { name = 'wh_b_weed_stage_2a', enable = true },    -- Weed drying
            { name = 'wh_b_weed_storage', enable = true }      -- Weed storage
        }
    },
}
