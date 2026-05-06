import { CaseReducer, PayloadAction } from '@reduxjs/toolkit';
import { itemDurability } from '../helpers';
import { inventorySlice } from '../store/inventory';
import { Items } from '../store/items';
import { InventoryType, Slot, State } from '../typings';
import { getBackpackSlotId, reconcileBackpackInventories } from './backpackState';

export type ItemsPayload = { item: Slot; inventory?: InventoryType };

interface Payload {
  items?: ItemsPayload | ItemsPayload[];
  itemCount?: Record<string, number>;
  weightData?: { inventoryId: string; maxWeight: number };
  slotsData?: { inventoryId: string; slots: number };
  craftingXp?: { xp: number };
}

export const refreshSlotsReducer: CaseReducer<State, PayloadAction<Payload>> = (state, action) => {
  if (action.payload.items) {
    if (!Array.isArray(action.payload.items)) action.payload.items = [action.payload.items];
    const curTime = Math.floor(Date.now() / 1000);
    const backpackSlotId = getBackpackSlotId(state);
    let shouldReconcileBackpacks = false;

    Object.values(action.payload.items)
      .filter((data) => !!data)
      .forEach((data) => {
        let targetInventory;

        if (data.inventory === InventoryType.PLAYER) {
          targetInventory = state.leftInventory;
        } else if (state.backpackInventory && data.inventory === state.backpackInventory.id) {
          targetInventory = state.backpackInventory;
        } else if (state.targetBackpackInventory && data.inventory === state.targetBackpackInventory.id) {
          targetInventory = state.targetBackpackInventory;
        } else if (state.craftingStorage && data.inventory === state.craftingStorage.id) {
          targetInventory = state.craftingStorage;
        } else {
          targetInventory = state.rightInventory;
        }

        if (targetInventory) {
          data.item.durability = itemDurability(data.item.metadata, curTime);
          targetInventory.items[data.item.slot - 1] = data.item;

          if (
            data.item.slot === backpackSlotId &&
            (data.inventory === InventoryType.PLAYER ||
              data.inventory === state.leftInventory.id ||
              (state.rightInventory.type === 'otherplayer' && data.inventory === state.rightInventory.id))
          ) {
            shouldReconcileBackpacks = true;
          }
        }
      });

    // Force re-render for crafting inventories so canCraftItem recalculates
    if (state.rightInventory.type === InventoryType.CRAFTING) {
      state.rightInventory = { ...state.rightInventory };
    }
    if (state.craftingStorage) {
      state.craftingStorage = { ...state.craftingStorage };
    }

    if (shouldReconcileBackpacks) {
      reconcileBackpackInventories(state);
    }
  }

  if (action.payload.itemCount) {
    const items = Object.entries(action.payload.itemCount);

    for (let i = 0; i < items.length; i++) {
      const item = items[i][0];
      const count = items[i][1];

      if (Items[item]!) {
        Items[item]!.count += count;
      } else console.log(`Item data for ${item} is undefined`);
    }
  }

  // Refresh maxWeight when SetMaxWeight is ran while an inventory is open
  if (action.payload.weightData) {
    const inventoryId = action.payload.weightData.inventoryId;
    const inventoryMaxWeight = action.payload.weightData.maxWeight;
    const inv =
      inventoryId === state.leftInventory.id
        ? 'leftInventory'
        : inventoryId === state.rightInventory.id
        ? 'rightInventory'
        : state.backpackInventory && inventoryId === state.backpackInventory.id
        ? 'backpackInventory'
        : state.targetBackpackInventory && inventoryId === state.targetBackpackInventory.id
        ? 'targetBackpackInventory'
        : state.craftingStorage && inventoryId === state.craftingStorage.id
        ? 'craftingStorage'
        : null;

    if (!inv) return;

    (state as any)[inv].maxWeight = inventoryMaxWeight;
  }

  if (action.payload.slotsData) {
    const { inventoryId } = action.payload.slotsData;
    const { slots } = action.payload.slotsData;

    const inv =
      inventoryId === state.leftInventory.id
        ? 'leftInventory'
        : inventoryId === state.rightInventory.id
        ? 'rightInventory'
        : state.backpackInventory && inventoryId === state.backpackInventory.id
        ? 'backpackInventory'
        : state.targetBackpackInventory && inventoryId === state.targetBackpackInventory.id
        ? 'targetBackpackInventory'
        : state.craftingStorage && inventoryId === state.craftingStorage.id
        ? 'craftingStorage'
        : null;

    if (!inv) return;

    (state as any)[inv].slots = slots;
    inventorySlice.caseReducers.setupInventory(state, {
      type: 'setupInventory',
      payload: {
        leftInventory: inv === 'leftInventory' ? state.leftInventory : undefined,
        rightInventory: inv === 'rightInventory' ? state.rightInventory : undefined,
        backpackInventory: inv === 'backpackInventory' ? state.backpackInventory : undefined,
        targetBackpackInventory: inv === 'targetBackpackInventory' ? state.targetBackpackInventory : undefined,
      },
    });
  }

  if (action.payload.craftingXp) {
    const xpValue = action.payload.craftingXp.xp;

    if (state.rightInventory.type === InventoryType.CRAFTING) {
      state.rightInventory.crafting = state.rightInventory.crafting || { id: 0, type: 'basic' };
      const xpInfo = state.rightInventory.crafting.xp;
      if (xpInfo) {
        xpInfo.current = xpValue;
      } else {
        state.rightInventory.crafting.xp = {
          enabled: true,
          current: xpValue,
          hideLocked: false,
        };
      }
    }
  }
};
