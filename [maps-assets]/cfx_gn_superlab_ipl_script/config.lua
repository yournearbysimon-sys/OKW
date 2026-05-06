Config = {}

-- Easy config
LosSantos_lab = true
SandyShores_lab = true
UndergroundTP_lab = true --tp = -495.358, -697.582, -149.164, 181.92

-- Configuration pour les superlabs
Config.Superlabs = {
    LosSantos = {
        Enabled = LosSantos_lab,
        ipl = "int_gn_superlab_ls_milo_",
        mlo = "int_gn_superlab",
        pos = {1494.9196, -2355.0576, 61.88931},
        EntitySet = {
            On = "with_access",
            Off = "without_access"
        },
        Laundry = {
            mlo = "int_gn_laundry",
            pos = {1492.382, -2352.5186, 65.36935},
            EntitySet = {
                On = "with_superlab_access",
                Off = "without_superlab_access"
            }
        }
    },
    SandyShores = {
        Enabled = SandyShores_lab,
        ipl = "int_gn_superlab_ss_milo_",
        mlo = "int_gn_superlab",
        pos = {1698.9072, 3600.5715, 31.456112},
        EntitySet = {
            On = "with_access",
            Off = "without_access"
        },
        Laundry = {
            mlo = "int_gn_laundry",
            pos = {1695.4424, 3601.5095, 34.93615},
            EntitySet = {
                On = "with_superlab_access",
                Off = "without_superlab_access"
            }
        }
    },
    Underground = {
        Enabled = UndergroundTP_lab,
        ipl = "int_gn_superlab_underground_milo_",
        pos = {-500.0, -700.0, -150.0},
        EntitySet = {
            On = "with_access",
            Off = "without_access"
        }
    }
}

