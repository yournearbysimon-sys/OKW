export type ItemCategoryData =
  | string
  | {
      name: string;
      icon?: string;
      order?: number;
    };

export type ItemButton = {
  label: string;
  group?: string;
};

export type WeaponEditorSlotConfig = {
  key: string;
  kind: 'ammo' | 'component';
  label: string;
  icon: string;
  ammoName?: string;
  componentType?: string;
  compatible?: string[];
};

export type ItemData = {
  name: string;
  label: string;
  stack: boolean;
  usable: boolean;
  close: boolean;
  count: number;
  rarity?: 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary';
  description?: string;
  buttons?: ItemButton[];
  ammoName?: string;
  image?: string;
  category?: ItemCategoryData;
  weapon?: boolean;
  component?: boolean;
  componentType?: string;
  weaponEditorSlots?: WeaponEditorSlotConfig[];
};
