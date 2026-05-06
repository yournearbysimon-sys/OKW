import { Inventory } from './inventory';
import { Slot } from './slot';
import { WorldGiveDialog } from './dnd';
import { UtilityConfig } from './utility';
import { WeaponEditorSlotConfig } from './item';

export type State = {
  leftInventory: Inventory;
  rightInventory: Inventory;
  utility?: UtilityConfig;
  itemAmount: number;
  splitModifierPressed: boolean;
  isBusy: boolean;
  additionalMetadata: Array<{ metadata: string; value: string }>;
  history?: {
    leftInventory: Inventory;
    rightInventory: Inventory;
    backpackInventory?: Inventory;
    targetBackpackInventory?: Inventory;
  };
  weaponEditor?: {
    slot: number;
    itemName: string;
    inventoryId?: string | number;
    inventoryType?: string;
    slots: WeaponEditorSlotConfig[];
  };
  backpackInventory?: Inventory;
  targetBackpackInventory?: Inventory;
  craftingStorage?: Inventory;
  worldGiveDialog?: WorldGiveDialog;
};
