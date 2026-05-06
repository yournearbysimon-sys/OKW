export type UtilityLayout = {
  left?: number[];
  right?: number[];
  bottom?: number[];
};

export type UtilityBackpackVariant = {
  drawable?: number;
  texture?: number;
};

export type UtilityBackpackItem = {
  slots?: number;
  weight?: number;
  blacklist?: string[] | Record<string, boolean>;
  whitelist?: string[] | Record<string, boolean>;
  appearance?: Record<string, UtilityBackpackVariant> | UtilityBackpackVariant;
};

export type UtilityConfig = {
  enabled?: boolean;
  slots?: number;
  slotIds?: number[];
  backpackSlotFallback?: number;
  armorSlotFallback?: number;
  useLegacyArmorSlotFallback?: boolean;
  autoUseParachuteOnEquip?: boolean;
  armorSearchSlotLimit?: number;
  repairProgressDuration?: number;
  backpackIdPrefixLength?: number;
  persistBackpackSizeMetadata?: boolean;
  legacyArmorPrefixes?: string[];
  parachuteItems?: string[];
  backpackAppearanceResource?: string;
  backpackComponentId?: number;
  backpackAppearancePollInterval?: {
    equipped?: number;
    idle?: number;
  };
  armorDamagePollInterval?: number;
  items?: Record<number, string[]>;
  labels?: Record<number, string>;
  icons?: Record<number, string | false>;
  iconSizes?: Record<number, number>;
  layout?: UtilityLayout;
  lockBackpackRemovalWithItems?: boolean;
  armorItems?: Record<string, { value: number; jobs?: string[] }>;
  armorDamageRate?: number;
  armorRepairItems?: Record<string, number>;
  backpackItems?: Record<string, UtilityBackpackItem>;
};
