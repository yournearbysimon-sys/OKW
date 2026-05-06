Config = {}
--[[ 
Enables static lifts if you disable the "cfx_gn_vespucci_elevator_script" script provided.
	True = Enables static lifts.
	False = Disables static lifts to enable the lift script provided.
]]

Config.StaticElevators = false

--[[
	NOOSE HQ activation
	True  = vspd_garage_noose_enabled  (NOOSE extension visible)
	False = vspd_garage_noose_disabled (NOOSE extension hidden)
]]
Config.NooseInterior = true
-------------------------------------------------------------------
Config.IPL_POLL_INTERVAL = 100
-- mode: 'feed' (native UI), 'chat' (chat:addMessage), or 'none'
Config.Notify = {
	mode = 'feed',
	prefix = '[IPL]',
	debug = false,
}
Config.INTERIORS = {
	['int_gn_vspd_main_milo_'] = {
		locations = {
			vec3(-1085.496, -832.734253, 23.01342),
		},
		iplRules = {
			{
				label = 'Vespucci PD – Main r01',
				rooms = {
					{ name = 'r01' }
				},
				ipls = {
					-- 'int_gn_vspd_main_milo_',
					-- 'int_gn_vspd_floor1_milo_',
					'int_gn_vspd_floor3_milo_',
					'int_gn_vspd_floor4_milo_',
					'int_gn_vspd_ungrd_milo_',
					'int_gn_vspd_garage_milo_',
					-- 'int_gn_vspd_lift_01_milo_',
					'int_gn_vspd_lift_02_milo_',
				}
			}
		}
	},
	['int_gn_vspd_main_milo_r07'] = {
		locations = {
			vec3(-1085.496, -832.734253, 23.01342),
		},
		iplRules = {
			{
				label = 'Vespucci PD – Main r01 - r07',
				rooms = {
					{ name = 'r07' },
					{ name = 'r10' },
				},
				ipls = {
					-- 'int_gn_vspd_main_milo_',
					'int_gn_vspd_floor1_milo_',
					'int_gn_vspd_floor3_milo_',
					'int_gn_vspd_floor4_milo_',
					'int_gn_vspd_ungrd_milo_',
					'int_gn_vspd_garage_milo_',
					'int_gn_vspd_lift_01_milo_',
					-- 'int_gn_vspd_lift_02_milo_',
				}
			}
		}
	},
	['int_gn_vspd_main_milo_r11'] = {
		locations = {
			vec3(-1085.496, -832.734253, 23.01342),
		},
		iplRules = {
			{
				label = 'Vespucci PD – Main r01 - r07',
				rooms = {
					{ name = 'r11' },
				},
				ipls = {
					-- 'int_gn_vspd_main_milo_',
					-- 'int_gn_vspd_floor1_milo_',
					-- 'int_gn_vspd_floor3_milo_',
					-- 'int_gn_vspd_floor4_milo_',
					-- 'int_gn_vspd_ungrd_milo_',
					'int_gn_vspd_garage_milo_',
					-- 'int_gn_vspd_lift_01_milo_',
					-- 'int_gn_vspd_lift_02_milo_',
				}
			}
		}
	},
	['int_gn_vspd_floor1'] = {
		locations = {
			vec3(-1078.749, -820.513, 28.0773678),
		},
		iplRules = {
			{
				label = 'Vespucci PD – L3',
				-- Pas de room = s'applique à tout l'intérieur
				ipls = {
					'int_gn_vspd_ungrd_milo_',
					'int_gn_vspd_garage_milo_',
					'int_gn_vspd_floor4_milo_',
					'int_gn_vspd_floor3_milo_',
					'int_gn_vspd_lift_01_milo_',
				}
			}
		}
	},
	['int_gn_vspd_floor3'] = {
		locations = {
			vec3(-1099.89331, -835.1595, 31.5183849),
		},
		iplRules = {
			{
				label = 'Vespucci PD – L4',
				-- Pas de room = s'applique à tout l'intérieur
				ipls = {
					-- 'int_gn_vspd_main_milo_',
					'int_gn_vspd_floor1_milo_',
					-- 'int_gn_vspd_floor3_milo_',
					'int_gn_vspd_floor4_milo_',
					'int_gn_vspd_ungrd_milo_',
					'int_gn_vspd_garage_milo_',
					-- 'int_gn_vspd_lift_01_milo_',
					'int_gn_vspd_lift_02_milo_',
				}
			}
		}
	},
	['int_gn_vspd_floor4'] = {
		locations = {
			vec3(-1100.0426, -835.04364, 36.82528),
		},
		iplRules = {
			{
				label = 'Vespucci PD – L5',
				-- Pas de room = s'applique à tout l'intérieur
				ipls = {
					-- 'int_gn_vspd_main_milo_',
					'int_gn_vspd_floor1_milo_',
					'int_gn_vspd_floor3_milo_',
					-- 'int_gn_vspd_floor4_milo_',
					'int_gn_vspd_ungrd_milo_',
					'int_gn_vspd_garage_milo_',
					-- 'int_gn_vspd_lift_01_milo_',
					'int_gn_vspd_lift_02_milo_',
				}
			}
		}
	},
	['int_gn_vspd_lift_01_r01'] = {
		locations = {
			vec3(-1096.30676, -850.5642, 20.71751),
		},
		iplRules = {
			{
				label = 'Vespucci PD – Lift 01 R01',
				rooms = {
					{ name = 'r01_lift1' }
				},
				ipls = {
					'int_gn_vspd_floor1_milo_',
					'int_gn_vspd_ungrd_milo_',
					'int_gn_vspd_lift_02_milo_',
					-- 'int_gn_vspd_garage_milo_',
					'int_gn_vspd_floor4_milo_',
					'int_gn_vspd_floor3_milo_',
				}
			}
		}
	},
	['int_gn_vspd_lift_01_r02'] = {
		locations = {
			vec3(-1096.30676, -850.5642, 20.71751),
		},
		iplRules = {
			{
				label = 'Vespucci PD – Lift 01 R02',
				rooms = {
					{ name = 'r02_lift1' }
				},
				ipls = {
					'int_gn_vspd_floor1_milo_',
					'int_gn_vspd_ungrd_milo_',
					'int_gn_vspd_lift_02_milo_',
					'int_gn_vspd_garage_milo_',
					'int_gn_vspd_main_milo_',
					-- 'int_gn_vspd_floor4_milo_',
					-- 'int_gn_vspd_floor3_milo_',
				}
			}
		}
	},
	['int_gn_vspd_lift_02'] = {
		locations = {
			vec3(-1066.19385, -833.6211, 14.7454481),
		},
		iplRules = {
			{
				label = 'Vespucci PD – Lift2 R01',
				rooms = {
					{ name = 'r01_lift2' }
				},
				ipls = {
					'int_gn_vspd_main_milo_',
					'int_gn_vspd_floor1_milo_',
					'int_gn_vspd_floor3_milo_',
					'int_gn_vspd_floor4_milo_',
					-- 'int_gn_vspd_ungrd_milo_',
					-- 'int_gn_vspd_garage_milo_',
					'int_gn_vspd_lift_01_milo_',
					-- 'int_gn_vspd_lift_02_milo_',
				}
			}
		}
	},
	['int_gn_vspd_lift_02'] = {
		locations = {
			vec3(-1066.19385, -833.6211, 14.7454481),
		},
		iplRules = {
			{
				label = 'Vespucci PD – Lift2 R02',
				rooms = {
					{ name = 'r02_lift2' }
				},
				ipls = {
					-- 'int_gn_vspd_main_milo_',
					-- 'int_gn_vspd_floor1_milo_',
					'int_gn_vspd_floor3_milo_',
					'int_gn_vspd_floor4_milo_',
					'int_gn_vspd_ungrd_milo_',
					'int_gn_vspd_garage_milo_',
					'int_gn_vspd_lift_01_milo_',
					-- 'int_gn_vspd_lift_02_milo_',
				}
			}
		}
	},
	['int_gn_vspd_ungrd_milo_'] = {
		locations = {
			vec3(-1060.08362, -815.795, 12.2015524),
		},
		iplRules = {
			{
				label = 'Vespucci PD – Underground',
				ipls = {
					-- 'int_gn_vspd_main_milo_',
					'int_gn_vspd_floor1_milo_',
					'int_gn_vspd_floor3_milo_',
					'int_gn_vspd_floor4_milo_',
					-- 'int_gn_vspd_ungrd_milo_',
					-- 'int_gn_vspd_garage_milo_',
					'int_gn_vspd_lift_01_milo_',
					-- 'int_gn_vspd_lift_02_milo_',
				}
			}
		}
	},
	['int_gn_vspd_garage_milo_'] = {
		locations = {
			vec3(-1095.64331, -831.7493, 10.7244015),
		},
		iplRules = {
			{
				label = 'Vespucci PD – Garage',
				ipls = {
					'int_gn_vspd_main_milo_',
					'int_gn_vspd_floor1_milo_',
					'int_gn_vspd_floor3_milo_',
					'int_gn_vspd_floor4_milo_',
					-- 'int_gn_vspd_ungrd_milo_',
					-- 'int_gn_vspd_garage_milo_',
					-- 'int_gn_vspd_lift_01_milo_',
					-- 'int_gn_vspd_lift_02_milo_',
				}
			}
		}
	}
}

Config.RadiusIpls = {
	enableNotifications = true,
	entries = {
		{ ipl = "int_gn_vspd_main_milo_",   pos = vector3(-1085.496, -832.734253, 23.01342),   radius = 100 },
		{ ipl = "int_gn_vspd_floor1_milo_", pos = vector3(-1078.749, -820.513, 28.0773678),    radius = 21 },
		{ ipl = "int_gn_vspd_floor3_milo_", pos = vector3(-1099.89331, -835.1595, 31.5183849), radius = 18 },
		{ ipl = "int_gn_vspd_floor4_milo_", pos = vector3(-1100.0426, -835.04364, 36.82528),   radius = 18 },
		{ ipl = "int_gn_vspd_ungrd_milo_",  pos = vector3(-1060.08362, -815.795, 12.2015524),  radius = 80 },
		{ ipl = "int_gn_vspd_garage_milo_", pos = vector3(-1095.64331, -831.7493, 10.7244015), radius = 90 },
		{ ipl = "int_gn_vspd_lift_01_milo_", pos = vector3(-1096.30676, -850.5642, 20.71751),   radius = 40 },
		{ ipl = "int_gn_vspd_lift_02_milo_", pos = vector3(-1066.19385, -833.6211, 14.7454481), radius = 40 },
	}
}
Config.IplLodMapping = {
	["int_gn_vspd_main_milo_"] = "gn_vspd_lod_main",
	["int_gn_vspd_floor4_milo_"] = "gn_vspd_lod_floor4",
	["int_gn_vspd_ungrd_milo_"] = "gn_vspd_lod_ungrd",
	["int_gn_vspd_garage_milo_"] = "gn_vspd_lod_garage",
}
