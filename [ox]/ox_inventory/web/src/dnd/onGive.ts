import { store } from '../store';
import { fetchNui } from '../utils/fetchNui';

export const onGive = (item: any) => {
  const {
    inventory: { itemAmount },
  } = store.getState();
  fetchNui('giveItem', { slot: item.slot, count: itemAmount, inventoryId: item.inventoryId });
};
