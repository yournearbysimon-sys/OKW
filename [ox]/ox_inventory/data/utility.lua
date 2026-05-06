return {
    enabled = true,
    slots = 6,
    slotIds = { 1, 2, 6, 7, 8, 9 },

    backpackSlotFallback = 6,
    armorSlotFallback = 7,
    useLegacyArmorSlotFallback = true,
    autoUseParachuteOnEquip = true,
    lockBackpackRemovalWithItems = true,
    armorSearchSlotLimit = 9,

    backpackIdPrefixLength = 3,
    persistBackpackSizeMetadata = true,
    repairProgressDuration = 5000,
    legacyArmorPrefixes = { 'armour' },
    parachuteItems = { 'parachute' },

    backpackAppearanceResource = 'illenium-appearance',
    backpackComponentId = 5,
    backpackAppearancePollInterval = {
        equipped = 1000,
        idle = 2500,
    },

    armorDamagePollInterval = 200,
    armorDamageRate = 0.5,
    items = {
        [1] = {},
        [2] = {},
        [6] = { 'backpack_small', 'backpack_medium', 'backpack_large' },
        [7] = { 'armour', 'armour_heavy' },
        [8] = { 'phone' },
        [9] = { 'parachute' },
    },
    labels = {
        [1] = 'Weapon Slot 1',
        [2] = 'Weapon Slot 2',
        [6] = 'Backpack',
        [7] = 'Armor',
        [8] = 'Phone',
        [9] = 'Parachute',
    },

    icons = {
        [1] = 'web/images/weapon2.svg',
        [2] = 'web/images/rifle-CjmmE0yk.svg',
        [6] = 'web/images/backpack.svg',
        [7] = 'web/images/vest-Dsoiv4XK.svg',
        [8] = 'web/images/phone.svg',
        [9] = 'web/images/parachute.svg',
    },

    iconSizes = {
        [1] = 65,
        [2] = 65,
        [6] = 65,
        [7] = 65,
        [8] = 65,
        [9] = 65,
    },

    layout = {
        left = { 6, 7, 8 },
        right = { 9, 1, 2 },
    },

    armorItems = {
        armour = {
            value = 50,
            jobs = {},
        },
        armour_heavy = {
            value = 100,
            jobs = { 'police', 'sheriff', 'bcso', 'fib' },
        },
    },

    armorRepairItems = {
        armor_repair_kit = 20,
        armor_plates = 20,
    },

    backpackItems = {
        backpack_small = {
            slots = 10,
            weight = 50000,
            blacklist = {},
            appearance = {
                male = { drawable = 41, texture = 0 },
                female = { drawable = 41, texture = 0 },
            },
        },
        backpack_medium = {
            slots = 20,
            weight = 100000,
            blacklist = {},
            appearance = {
                male = { drawable = 45, texture = 0 },
                female = { drawable = 45, texture = 0 },
            },
        },
        backpack_large = {
            slots = 30,
            weight = 150000,
            blacklist = {},
            appearance = {
                male = { drawable = 82, texture = 0 },
                female = { drawable = 82, texture = 0 },
            },
        },
    },
}
