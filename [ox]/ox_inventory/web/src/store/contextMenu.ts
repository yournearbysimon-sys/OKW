import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { SlotWithItem } from '../typings';

interface ContextMenuState {
  coords: {
    x: number;
    y: number;
  } | null;
  item: SlotWithItem | null;
  inventoryId?: string | number;
  inventoryType?: string;
}

const initialState: ContextMenuState = {
  coords: null,
  item: null,
};

export const contextMenuSlice = createSlice({
  name: 'contextMenu',
  initialState,
  reducers: {
    openContextMenu(
      state,
      action: PayloadAction<{
        item: SlotWithItem;
        coords: { x: number; y: number };
        inventoryId?: string | number;
        inventoryType?: string;
      }>
    ) {
      state.coords = action.payload.coords;
      state.item = action.payload.item;
      state.inventoryId = action.payload.inventoryId;
      state.inventoryType = action.payload.inventoryType;
    },
    closeContextMenu(state) {
      state.coords = null;
    },
  },
});

export const { openContextMenu, closeContextMenu } = contextMenuSlice.actions;

export default contextMenuSlice.reducer;
