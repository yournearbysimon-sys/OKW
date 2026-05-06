import { CaseReducer, PayloadAction } from '@reduxjs/toolkit';
import { getItemData, itemDurability } from '../helpers';
import { Items } from '../store/items';
import { Inventory, State, UtilityConfig } from '../typings';
import { defaultUtilityConfig } from '../store/utility';

const normalizeUtilityItems = (items: UtilityConfig['items']) => {
  if (!items) return items;

  if (Array.isArray(items)) {
    return items.reduce<Record<number, string[]>>((accumulator, entry, index) => {
      if (!Array.isArray(entry)) return accumulator;

      const normalizedEntry = entry.filter((itemName): itemName is string => typeof itemName === 'string' && !!itemName);

      if (normalizedEntry.length > 0 || entry.length === 0) {
        accumulator[index + 1] = normalizedEntry;
      }

      return accumulator;
    }, {});
  }

  return Object.entries(items).reduce<Record<number, string[]>>((accumulator, [slot, entry]) => {
    if (!Array.isArray(entry)) return accumulator;

    accumulator[Number(slot)] = entry.filter((itemName): itemName is string => typeof itemName === 'string' && !!itemName);
    return accumulator;
  }, {});
};

const normalizeUtilityConfig = (utility: UtilityConfig): UtilityConfig => ({
  ...utility,
  items: normalizeUtilityItems(utility.items),
});

export const setupInventoryReducer: CaseReducer<
  State,
  PayloadAction<{
    leftInventory?: Inventory;
    rightInventory?: Inventory;
    backpackInventory?: Inventory | false;
    targetBackpackInventory?: Inventory | false;
    utility?: UtilityConfig;
  }>
> = (state, action) => {
  const { leftInventory, rightInventory, utility } = action.payload;
  const curTime = Math.floor(Date.now() / 1000);
  const normalizeInventory = (inventory: Inventory, type?: Inventory['type']) => ({
    ...inventory,
    ...(type ? { type } : {}),
    items: Array.from(Array(inventory.slots), (_, index) => {
      const items = inventory.items || {};
      const item = Object.values(items).find((entry) => entry?.slot === index + 1) || {
        slot: index + 1,
      };

      if (!item.name) return item;

      if (typeof Items[item.name] === 'undefined') {
        getItemData(item.name);
      }

      item.durability = itemDurability(item.metadata, curTime);
      return item;
    }),
  });

  if (utility) {
    state.utility = normalizeUtilityConfig(utility);
  } else if (!state.utility) {
    state.utility = defaultUtilityConfig;
  }

  if (leftInventory) state.leftInventory = normalizeInventory(leftInventory);

  const isPlaceholderRightInventory =
    !!rightInventory && rightInventory.type === 'newdrop' && !rightInventory.id && !rightInventory.label;

  const shouldPreserveOpenContainer =
    isPlaceholderRightInventory &&
    !leftInventory &&
    state.rightInventory?.type === 'container' &&
    !!state.rightInventory?.id;

  if (rightInventory && !shouldPreserveOpenContainer) state.rightInventory = normalizeInventory(rightInventory);

  if (leftInventory !== undefined) {
    if (leftInventory?.storage) {
      const storage = leftInventory.storage;
      state.craftingStorage = normalizeInventory(storage, 'crafting_storage');
    } else {
      state.craftingStorage = undefined;
    }
  }

  if ('backpackInventory' in action.payload) {
    const { backpackInventory } = action.payload;
    state.backpackInventory = backpackInventory ? normalizeInventory(backpackInventory) : undefined;
  }

  if ('targetBackpackInventory' in action.payload) {
    const { targetBackpackInventory } = action.payload;
    state.targetBackpackInventory = targetBackpackInventory ? normalizeInventory(targetBackpackInventory) : undefined;
  }

  state.splitModifierPressed = false;
  state.isBusy = false;
};
