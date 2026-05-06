import { createSlice, current, isFulfilled, isPending, isRejected, PayloadAction } from '@reduxjs/toolkit';
import type { RootState } from '.';
import {
  moveSlotsReducer,
  refreshSlotsReducer,
  setupInventoryReducer,
  stackSlotsReducer,
  swapSlotsReducer,
} from '../reducers';
import { State } from '../typings';
import { defaultUtilityConfig } from './utility';
import { WeaponEditorSlotConfig } from '../typings/item';

const initialState: State = {
  leftInventory: {
    id: '',
    type: '',
    slots: 0,
    maxWeight: 0,
    items: [],
  },
  rightInventory: {
    id: '',
    type: '',
    slots: 0,
    maxWeight: 0,
    items: [],
  },
  utility: defaultUtilityConfig,
  additionalMetadata: new Array(),
  itemAmount: 0,
  splitModifierPressed: false,
  isBusy: false,
};

export const inventorySlice = createSlice({
  name: 'inventory',
  initialState,
  reducers: {
    stackSlots: stackSlotsReducer,
    swapSlots: swapSlotsReducer,
    setupInventory: setupInventoryReducer,
    moveSlots: moveSlotsReducer,
    refreshSlots: refreshSlotsReducer,
    setAdditionalMetadata: (state, action: PayloadAction<Array<{ metadata: string; value: string }>>) => {
      const metadata = [];

      for (let i = 0; i < action.payload.length; i++) {
        const entry = action.payload[i];
        if (!state.additionalMetadata.find((el) => el.value === entry.value)) metadata.push(entry);
      }

      state.additionalMetadata = [...state.additionalMetadata, ...metadata];
    },
    setItemAmount: (state, action: PayloadAction<number>) => {
      state.itemAmount = action.payload;
    },
    setSplitModifierPressed: (state, action: PayloadAction<boolean>) => {
      state.splitModifierPressed = action.payload;
    },
    setContainerWeight: (state, action: PayloadAction<number>) => {
      const container = state.leftInventory.items.find((item) => item.metadata?.container === state.rightInventory.id);

      if (!container) return;

      container.weight = action.payload;
    },
    updateCraftingQueue: (state, action: PayloadAction<any[]>) => {
      if (state.rightInventory.crafting) {
        state.rightInventory.crafting.queue = action.payload;
      }
    },
    openWorldGiveDialog: (state, action: PayloadAction<State['worldGiveDialog']>) => {
      state.worldGiveDialog = action.payload;
    },
    closeWorldGiveDialog: (state) => {
      state.worldGiveDialog = undefined;
    },
    openWeaponEditor: (
      state,
      action: PayloadAction<{
        slot: number;
        itemName: string;
        inventoryId?: string | number;
        inventoryType?: string;
        slots: WeaponEditorSlotConfig[];
      }>
    ) => {
      state.weaponEditor = action.payload;
    },
    closeWeaponEditor: (state) => {
      state.weaponEditor = undefined;
    },
  },
  extraReducers: (builder) => {
    builder.addMatcher(isPending, (state) => {
      state.isBusy = true;

      state.history = {
        leftInventory: current(state.leftInventory),
        rightInventory: current(state.rightInventory),
        backpackInventory: state.backpackInventory ? current(state.backpackInventory) : undefined,
        targetBackpackInventory: state.targetBackpackInventory ? current(state.targetBackpackInventory) : undefined,
      };
    });
    builder.addMatcher(isFulfilled, (state) => {
      state.isBusy = false;
    });
    builder.addMatcher(isRejected, (state) => {
      if (state.history && state.history.leftInventory && state.history.rightInventory) {
        state.leftInventory = state.history.leftInventory;
        state.rightInventory = state.history.rightInventory;
        state.backpackInventory = state.history.backpackInventory;
        state.targetBackpackInventory = state.history.targetBackpackInventory;
      }
      state.isBusy = false;
    });
  },
});

export const {
  setAdditionalMetadata,
  setItemAmount,
  setSplitModifierPressed,
  setupInventory,
  swapSlots,
  moveSlots,
  stackSlots,
  refreshSlots,
  setContainerWeight,
  updateCraftingQueue,
  openWorldGiveDialog,
  closeWorldGiveDialog,
  openWeaponEditor,
  closeWeaponEditor,
} = inventorySlice.actions;
export const selectLeftInventory = (state: RootState) => state.inventory.leftInventory;
export const selectRightInventory = (state: RootState) => state.inventory.rightInventory;
export const selectOwnerBackpackInventory = (state: RootState) => state.inventory.backpackInventory;
export const selectBackpackInventory = selectOwnerBackpackInventory;
export const selectTargetBackpackInventory = (state: RootState) => state.inventory.targetBackpackInventory;
export const selectCraftingStorage = (state: RootState) => state.inventory.craftingStorage;
export const selectItemAmount = (state: RootState) => state.inventory.itemAmount;
export const selectIsBusy = (state: RootState) => state.inventory.isBusy;
export const selectUtility = (state: RootState) => state.inventory.utility;
export const selectWorldGiveDialog = (state: RootState) => state.inventory.worldGiveDialog;
export const selectWeaponEditor = (state: RootState) => state.inventory.weaponEditor;

export default inventorySlice.reducer;
