import { State } from '../typings';

type BackpackStateKey = 'backpackInventory' | 'targetBackpackInventory';

export const getBackpackSlotId = (state: State) => {
  let backpackSlotId = 6;
  const utilityItems = state.utility?.items;
  const backpackItems = state.utility?.backpackItems;

  if (!utilityItems || !backpackItems) {
    return backpackSlotId;
  }

  for (const [slot, items] of Object.entries(utilityItems)) {
    if (!Array.isArray(items)) continue;

    if (items.some((itemName) => backpackItems[itemName])) {
      backpackSlotId = Array.isArray(utilityItems) ? Number(slot) + 1 : Number(slot);
      break;
    }
  }

  return backpackSlotId;
};

const reconcileNamedBackpackInventory = (
  state: State,
  key: BackpackStateKey,
  ownerInventory?: State['leftInventory']
) => {
  if (!state[key]) return;

  const backpackItems = state.utility?.backpackItems;

  if (!ownerInventory || !backpackItems) {
    state[key] = undefined;
    return;
  }

  const backpackSlotId = getBackpackSlotId(state);
  const backpackSlot = ownerInventory.items?.[backpackSlotId - 1];
  const backpackContainer = backpackSlot?.metadata?.container;

  if (!backpackSlot?.name || !backpackItems[backpackSlot.name]) {
    state[key] = undefined;
    return;
  }

  // Some slot refreshes only send a partial backpack item update while the
  // container itself is still open. In that case we should keep the current
  // backpack panel instead of immediately hiding it.
  if (!backpackContainer) {
    return;
  }

  if (state[key]!.id !== backpackContainer) {
    state[key] = undefined;
  }
};

export const reconcileBackpackInventories = (state: State) => {
  reconcileNamedBackpackInventory(state, 'backpackInventory', state.leftInventory);

  if (state.rightInventory.type === 'otherplayer') {
    reconcileNamedBackpackInventory(state, 'targetBackpackInventory', state.rightInventory);
  } else {
    state.targetBackpackInventory = undefined;
  }
};
