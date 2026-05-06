local categories = {
	weapons = { name = 'Weapons', icon = 'swords', order = 10 },
	food = { name = 'Food', icon = 'restaurant', order = 20 },
	tools = { name = 'Tools', icon = 'build', order = 30 },
	clothes = { name = 'Clothes', icon = 'checkroom', order = 40 },
	medical = { name = 'Medical', icon = 'medical_services', order = 50 },
	materials = { name = 'Materials', icon = 'inventory_2', order = 60 },
	utility = { name = 'Utility', icon = 'tune', order = 70 },
	documents = { name = 'Documents', icon = 'badge', order = 80 },
}

return {

	-- ══════════════════════════════════════════
	--  CRAFTING BENCHES
	-- ══════════════════════════════════════════

	['bench_basic'] = {
		label = 'Basic Crafting Bench',
		weight = 1000,
		stack = false,
		close = true,
		rarity = 'uncommon',
		description = 'A basic bench for crafting simple items.',
		category = categories.tools,
		prop = 'prop_tool_bench02',
		client = {
			image = 'bench.png',
		}
	},
	['bench_advanced'] = {
		label = 'Advanced Crafting Bench',
		weight = 2000,
		stack = false,
		close = true,
		rarity = 'rare',
		description = 'An advanced bench for crafting complex items.',
		category = categories.tools,
		client = {
			image = 'bench.png',
		}
	},

	-- ══════════════════════════════════════════
	--  STORAGE
	-- ══════════════════════════════════════════

	['stash_carton_small'] = {
		label = 'Small Storage Box',
		weight = 900,
		stack = false,
		close = true,
		rarity = 'common',
		description = 'A small storage box for light personal use.',
		category = categories.utility,
		prop = 'prop_cardbordbox_02a',
		client = {
			image = 'stash_carton_small.png',
		}
	},
	['stash_crate_medium'] = {
		label = 'Wooden Storage Crate',
		weight = 2200,
		stack = false,
		close = true,
		rarity = 'uncommon',
		description = 'A wooden crate for storing tools, materials, and supplies.',
		category = categories.utility,
		prop = 'prop_box_wood05a',
		client = {
			image = 'stash_crate_medium.png',
		}
	},
	['stash_container_large'] = {
		label = 'Large Shipping Container',
		weight = 9000,
		stack = false,
		close = true,
		rarity = 'rare',
		description = 'A large container for heavy shared storage.',
		category = categories.utility,
		prop = 'prop_container_05a',
		client = {
			image = 'stash_container_large.png',
		}
	},
	['stash_locker_secure'] = {
		label = 'Steel Jewelry Safe',
		weight = 3500,
		stack = false,
		close = true,
		rarity = 'epic',
		description = 'A reinforced steel safe for jewelry, cash, and other valuables.',
		category = categories.utility,
		prop = 'prop_ld_int_safe_01',
		client = {
			image = 'stash_locker_secure.png',
		}
	},

	-- ══════════════════════════════════════════
	--  TOOLS & BLUEPRINTS
	-- ══════════════════════════════════════════

	['blueprint'] = {
		label = 'Blueprint',
		weight = 100,
		stack = false,
		close = true,
		rarity = 'rare',
		description = 'A blueprint required to craft specific items.',
		category = categories.tools,
		client = {
			image = 'blueprint.png',
		}
	},
	['lockpick'] = {
		label = 'Lockpick',
		weight = 160,
		rarity = 'rare',
		category = categories.tools
	},
	['blowpipe'] = {
		label = 'Blowtorch',
		weight = 2,
		stack = true,
		close = true,
		rarity = 'uncommon',
		category = categories.tools,
	},
	['carokit'] = {
		label = 'Body Kit',
		weight = 3,
		stack = true,
		close = true,
		rarity = 'uncommon',
		category = categories.tools,
	},
	['carotool'] = {
		label = 'Tools',
		weight = 2,
		stack = true,
		close = true,
		rarity = 'common',
		category = categories.tools,
	},
	['fixkit'] = {
		label = 'Repair Kit',
		weight = 3,
		stack = true,
		close = true,
		rarity = 'uncommon',
		category = categories.tools,
	},
	['fixtool'] = {
		label = 'Repair Tools',
		weight = 2,
		stack = true,
		close = true,
		rarity = 'common',
		category = categories.tools,
	},
	['armor_repair_kit'] = {
		label = 'Armor Repair Kit',
		weight = 2000,
		stack = true,
		close = true,
		rarity = 'rare',
		description = 'Used to repair damaged body armor.',
		category = categories.tools,
	},
	['armor_plates'] = {
		label = 'Armor Plates',
		weight = 500,
		stack = true,
		close = true,
		rarity = 'uncommon',
		description = 'Heavy plates used to reinforce body armor.',
		category = categories.tools,
	},

	-- ══════════════════════════════════════════
	--  RADIO & SIGNAL EQUIPMENT
	-- ══════════════════════════════════════════

	['radio'] = {
		label = 'Radio',
		weight = 1000,
		stack = false,
		consume = 0,
		allowArmed = true,
		rarity = 'uncommon',
		category = categories.tools,
		client = {
			export = 'radio-zombi.UseRadioItem'
		}
	},
	['survival_radio'] = {
		label = 'Survival Radio',
		weight = 1200,
		stack = false,
		consume = 0,
		allowArmed = true,
		rarity = 'rare',
		description = 'A rugged handheld radio that depends on powered relay towers.',
		category = categories.tools,
		client = {
			export = 'radio-seystm.UseRadioItem'
		}
	},
	['signal_radar'] = {
		label = 'Signal Radar',
		weight = 9000,
		stack = false,
		close = true,
		rarity = 'epic',
		description = 'Deploys a radar tower for relay coverage.',
		category = categories.tools,
		client = {
			export = 'radio-zombi.UseRadarItem'
		}
	},
	['signal_generator'] = {
		label = 'Relay Generator',
		weight = 7000,
		stack = false,
		close = true,
		rarity = 'rare',
		description = 'Portable generator used to power a relay site.',
		category = categories.tools,
		client = {
			export = 'radio-zombi.UseGeneratorItem'
		}
	},
	['radio_control_device'] = {
		label = 'Relay Control Unit',
		weight = 2500,
		stack = false,
		close = true,
		rarity = 'rare',
		description = 'Configuration unit for managing relay permissions, channels, and links.',
		category = categories.tools,
		client = {
			export = 'radio-zombi.UseControlItem'
		}
	},
	['signal_upgrade_kit'] = {
		label = 'Relay Upgrade Kit',
		weight = 1800,
		stack = true,
		close = true,
		rarity = 'epic',
		description = 'Improves relay range and efficiency when installed on a tower.',
	},

	-- ══════════════════════════════════════════
	--  FOOD & DRINK
	-- ══════════════════════════════════════════

	['testburger'] = {
		label = 'Test Burger',
		weight = 220,
		degrade = 60,
		rarity = 'common',
		category = categories.food,
		client = {
			image = 'burger_chicken.png',
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'burger',
			usetime = 2500,
			export = 'ox_inventory_examples.testburger'
		},
		server = {
			export = 'ox_inventory_examples.testburger',
			test = 'what an amazingly delicious burger, amirite?'
		},
		buttons = {
			{
				label = 'Lick it',
				action = function(slot)
					print('You licked the burger')
				end
			},
			{
				label = 'Squeeze it',
				action = function(slot)
					print('You squeezed the burger :(')
				end
			},
			{
				label = 'What do you call a vegan burger?',
				group = 'Hamburger Puns',
				action = function(slot)
					print('A misteak.')
				end
			},
			{
				label = 'What do frogs like to eat with their hamburgers?',
				group = 'Hamburger Puns',
				action = function(slot)
					print('French flies.')
				end
			},
			{
				label = 'Why were the burger and fries running?',
				group = 'Hamburger Puns',
				action = function(slot)
					print('Because they\'re fast food.')
				end
			}
		},
		consume = 0.3
	},
	['burger'] = {
		label = 'Burger',
		weight = 220,
		rarity = 'common',
		category = categories.food,
		client = {
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'burger',
			usetime = 2500,
			notification = 'You ate a delicious burger'
		},
		prop = `prop_cs_burger_01`
	},
	['sprunk'] = {
		label = 'Sprunk',
		weight = 350,
		rarity = 'common',
		category = categories.food,
		client = {
			status = { thirst = 200000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
			usetime = 2500,
			notification = 'You quenched your thirst with a sprunk'
		}
	},
	['mustard'] = {
		label = 'Mustard',
		weight = 500,
		rarity = 'common',
		category = categories.food,
		client = {
			status = { hunger = 25000, thirst = 25000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_food_mustard`, pos = vec3(0.01, 0.0, -0.07), rot = vec3(1.0, 1.0, -1.5) },
			usetime = 2500,
			notification = 'You.. drank mustard'
		}
	},
	['water'] = {
		label = 'Water',
		weight = 500,
		rarity = 'common',
		category = categories.food,
		client = {
			status = { thirst = 200000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_ld_flow_bottle`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) },
			usetime = 2500,
			cancel = true,
			notification = 'You drank some refreshing water'
		},
		prop = `prop_ld_flow_bottle`,
	},
	['alive_chicken'] = {
		label = 'Living Chicken',
		weight = 1,
		stack = true,
		close = true,
		rarity = 'uncommon',
		category = categories.food,
	},
	['bread'] = {
		label = 'Bread',
		weight = 1,
		stack = true,
		close = true,
		rarity = 'common',
		category = categories.food,
	},
	['fish'] = {
		label = 'Fish',
		weight = 1,
		stack = true,
		close = true,
		rarity = 'common',
		category = categories.food,
	},
	['packaged_chicken'] = {
		label = 'Chicken Fillet',
		weight = 1,
		stack = true,
		close = true,
		rarity = 'common',
		category = categories.food,
	},
	['slaughtered_chicken'] = {
		label = 'Slaughtered Chicken',
		weight = 1,
		stack = true,
		close = true,
		rarity = 'common',
		category = categories.food,
	},

	-- ══════════════════════════════════════════
	--  MEDICAL
	-- ══════════════════════════════════════════

	['bandage'] = {
		label = 'Bandage',
		weight = 115,
		rarity = 'common',
		category = categories.medical,
		client = {
			anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
			prop = { model = `prop_rolled_sock_02`, pos = vec3(-0.14, -0.14, -0.08), rot = vec3(-50.0, -50.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 2500,
		}
	},
	['medikit'] = {
		label = 'Medikit',
		weight = 2,
		stack = true,
		close = true,
		rarity = 'rare',
		category = categories.medical,
	},

	-- ══════════════════════════════════════════
	--  MATERIALS
	-- ══════════════════════════════════════════

	['garbage'] = {
		label = 'Garbage',
		rarity = 'common',
		category = categories.materials,
	},
	['scrapmetal'] = {
		label = 'Scrap Metal',
		weight = 80,
		rarity = 'common',
		category = categories.materials,
	},
	['cannabis'] = {
		label = 'Cannabis',
		weight = 3,
		stack = true,
		close = true,
		rarity = 'uncommon',
		category = categories.materials,
	},
	['clothe'] = {
		label = 'Cloth',
		weight = 1,
		stack = true,
		close = true,
		rarity = 'common',
		category = categories.materials,
	},
	['copper'] = {
		label = 'Copper',
		weight = 1,
		stack = true,
		close = true,
		rarity = 'uncommon',
		category = categories.materials,
	},
	['cutted_wood'] = {
		label = 'Cut Wood',
		weight = 1,
		stack = true,
		close = true,
		rarity = 'common',
		category = categories.materials,
	},
	['diamond'] = {
		label = 'Diamond',
		weight = 1,
		stack = true,
		close = true,
		rarity = 'legendary',
		category = categories.materials,
	},
	['essence'] = {
		label = 'Gas',
		weight = 1,
		stack = true,
		close = true,
		rarity = 'common',
		category = categories.materials,
	},
	['fabric'] = {
		label = 'Fabric',
		weight = 1,
		stack = true,
		close = true,
		rarity = 'common',
		category = categories.materials,
	},
	['gazbottle'] = {
		label = 'Gas Bottle',
		weight = 2,
		stack = true,
		close = true,
		rarity = 'uncommon',
		category = categories.materials,
	},
	['gold'] = {
		label = 'Gold',
		weight = 1,
		stack = true,
		close = true,
		rarity = 'epic',
		category = categories.materials,
	},
	['iron'] = {
		label = 'Iron',
		weight = 1,
		stack = true,
		close = true,
		rarity = 'common',
		category = categories.materials,
	},
	['marijuana'] = {
		label = 'Marijuana',
		weight = 2,
		stack = true,
		close = true,
		rarity = 'uncommon',
		category = categories.materials,
	},
	['packaged_plank'] = {
		label = 'Packaged Wood',
		weight = 1,
		stack = true,
		close = true,
		rarity = 'common',
		category = categories.materials,
	},
	['petrol'] = {
		label = 'Oil',
		weight = 1,
		stack = true,
		close = true,
		rarity = 'common',
		category = categories.materials,
	},
	['petrol_raffin'] = {
		label = 'Processed Oil',
		weight = 1,
		stack = true,
		close = true,
		rarity = 'uncommon',
		category = categories.materials,
	},
	['stone'] = {
		label = 'Stone',
		weight = 1,
		stack = true,
		close = true,
		rarity = 'common',
		category = categories.materials,
	},
	['washed_stone'] = {
		label = 'Washed Stone',
		weight = 1,
		stack = true,
		close = true,
		rarity = 'uncommon',
		category = categories.materials,
	},
	['wood'] = {
		label = 'Wood',
		weight = 1,
		stack = true,
		close = true,
		rarity = 'common',
		category = categories.materials,
	},
	['wool'] = {
		label = 'Wool',
		weight = 1,
		stack = true,
		close = true,
		rarity = 'uncommon',
		category = categories.materials,
	},

	-- ══════════════════════════════════════════
	--  UTILITY & MISC
	-- ══════════════════════════════════════════

	['black_money'] = {
		label = 'Dirty Money',
		rarity = 'rare',
		category = categories.utility,
	},
	['money'] = {
		label = 'Money',
		prop = `prop_anim_cash_pile_02`,
		rarity = 'uncommon',
		category = categories.utility,
	},
	['parachute'] = {
		label = 'Parachute',
		weight = 8000,
		stack = false,
		rarity = 'rare',
		category = categories.utility,
		client = {
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 1500
		}
	},
	['paperbag'] = {
		label = 'Paper Bag',
		weight = 1,
		stack = false,
		close = false,
		consume = 0,
		rarity = 'common',
		category = categories.utility,
	},
	['backpack_small'] = {
		label = 'Small Backpack',
		weight = 100,
		stack = false,
		close = false,
		consume = 0,
		rarity = 'common',
		category = categories.utility,
		client = {
			image = 'bag1.png'
		}
	},
	['backpack_medium'] = {
		label = 'Medium Backpack',
		weight = 100,
		stack = false,
		close = false,
		consume = 0,
		rarity = 'uncommon',
		category = categories.utility,
		client = {
			image = 'bag2.png'
		}
	},
	['backpack_large'] = {
		label = 'Large Backpack',
		weight = 100,
		stack = false,
		close = false,
		consume = 0,
		rarity = 'rare',
		category = categories.utility,
		client = {
			image = 'bag3.png'
		}
	},
	['phone'] = {
		label = 'Phone',
		weight = 190,
		stack = false,
		consume = 0,
		rarity = 'uncommon',
		category = categories.utility,
		client = {
			add = function(total)
				if total > 0 then
					pcall(function() return exports.npwd:setPhoneDisabled(false) end)
				end
			end,

			remove = function(total)
				if total < 1 then
					pcall(function() return exports.npwd:setPhoneDisabled(true) end)
				end
			end
		}
	},

	-- ══════════════════════════════════════════
	--  CLOTHES
	-- ══════════════════════════════════════════

	['clothing'] = {
		label = 'Clothing',
		consume = 0,
		rarity = 'common',
		category = categories.clothes,
	},
	['panties'] = {
		label = 'Knickers',
		weight = 10,
		consume = 0,
		rarity = 'common',
		category = categories.clothes,
		client = {
			status = { thirst = -100000, stress = -25000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_cs_panties_02`, pos = vec3(0.03, 0.0, 0.02), rot = vec3(0.0, -13.5, -1.5) },
			usetime = 2500,
		}
	},

	-- ══════════════════════════════════════════
	--  DOCUMENTS & CARDS
	-- ══════════════════════════════════════════

	['identification'] = {
		label = 'Identification',
		rarity = 'uncommon',
		category = categories.documents,
		client = {
			image = 'card_id.png'
		}
	},
	['mastercard'] = {
		label = 'Fleeca Card',
		stack = false,
		weight = 10,
		rarity = 'rare',
		category = categories.documents,
		client = {
			image = 'card_bank.png'
		}
	},
	['crew_sd_card'] = {
		label = 'Crew SD Card',
		weight = 15,
		stack = false,
		close = false,
		rarity = 'epic',
		description = 'A tablet SD card that unlocks the crew network application.',
		category = categories.documents,
		client = {
			image = 'crew_sd_card.png'
		}
	},
	['example_sd_card'] = {
		label = 'example_sd_card',
		weight = 15,
		stack = false,
		close = false,
		rarity = 'uncommon',
		description = 'A tablet SD card that unlocks the crew network application.',
		category = categories.documents,
		client = {
			image = 'crew_sd_card.png'
		}
	},
	['tablet'] = {
		label = 'Tablet',
		weight = 850,
		stack = false,
		close = true,
		consume = 0,
		rarity = 'rare',
		description = 'A portable tablet used to access tablet applications.',
		category = categories.documents,
		client = {
			image = 'phone.png',
			export = 'apex-tablet.UseTabletItem'
		}
	},

	-- ══════════════════════════════════════════
	--  RACING & MISC
	-- ══════════════════════════════════════════

	['racing_gps'] = {
		['name'] = 'racing_gps',
		['label'] = 'Racing GPS',
		['weight'] = 500,
		['type'] = 'item',
		['image'] = 'racing_gps.png',
		['unique'] = true,
		['useable'] = true,
		['shouldClose'] = true,
		['rarity'] = 'rare',
		['client'] = {
			export = 'cw-racingapp.openRacingApp'
		}
	},
}
