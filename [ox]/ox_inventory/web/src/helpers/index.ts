import { Inventory, InventoryType, ItemData, Slot, SlotWithItem, State } from '../typings';
import { has, isEqual } from 'lodash';
import { store } from '../store';
import { Items } from '../store/items';
import { imagepath } from '../store/imagepath';
import { fetchNui } from '../utils/fetchNui';
import { SyntheticEvent, useEffect, useState } from 'react';

const MISSING_ITEM_IMAGE = 'item-missing-question.svg';

export const isSlotWithItem = (slot: Slot, strict: boolean = false): slot is SlotWithItem =>
  (slot.name !== undefined && slot.weight !== undefined) ||
  (strict && slot.name !== undefined && slot.count !== undefined && slot.weight !== undefined);

export const useCurrentTime = (interval = 100) => {
  const [now, setNow] = useState(Date.now());

  useEffect(() => {
    const timer = setInterval(() => setNow(Date.now()), interval);
    return () => clearInterval(timer);
  }, [interval]);

  return now;
};

export const itemDurability = (metadata: any, curTime: number) => {
  if (metadata?.durability === undefined) return;

  let durability = metadata.durability;

  if (durability > 100 && metadata.degrade)
    durability = ((metadata.durability - curTime) / (60 * metadata.degrade)) * 100;

  if (durability < 0) durability = 0;

  return durability;
};

export const getItemUrl = (item: string | SlotWithItem) => {
  const isObj = typeof item === 'object';

  if (isObj) {
    if (!item.name) return;

    const metadata = item.metadata;

    if (metadata?.imageurl) return `${metadata.imageurl}`;
    if (metadata?.image) return `${imagepath}/${metadata.image}.png`;
  }

  const itemName = isObj ? (item.name as string) : item;
  const itemData = Items[itemName];

  if (!itemData) return `${imagepath}/${itemName}.png`;
  if (itemData.image) return itemData.image;

  itemData.image = `${imagepath}/${itemName}.png`;

  return itemData.image;
};

export const getMissingItemImageUrl = () => `${imagepath}/${MISSING_ITEM_IMAGE}`;

export const handleItemImageError = (event: SyntheticEvent<HTMLImageElement, Event>) => {
  const image = event.currentTarget;
  const fallbackUrl = getMissingItemImageUrl();

  if (image.src.endsWith(`/${MISSING_ITEM_IMAGE}`)) {
    image.style.display = 'none';
    return;
  }

  image.style.display = '';
  image.src = fallbackUrl;
};

export const canStack = (sourceSlot: Slot, targetSlot: Slot) =>
  sourceSlot.name === targetSlot.name && isEqual(sourceSlot.metadata, targetSlot.metadata);

export const getTotalWeight = (items: Inventory['items']) =>
  items.reduce((totalWeight, slot) => (isSlotWithItem(slot) ? totalWeight + slot.weight : totalWeight), 0);

export const isContainer = (inventory: Inventory) => inventory.type === InventoryType.CONTAINER;

export const itemName = (item: Slot) => (isSlotWithItem(item) ? item.name : undefined);

export const getItemCount = (itemName: string, inventory?: Inventory, storage?: Inventory) => {
  const targetInventory = inventory || store.getState().inventory.leftInventory;

  let totalCount = 0;

  if (storage || (inventory && inventory.type === 'crafting_storage')) {
    const storageInv = storage || inventory;
    const matchingItems = storageInv?.items.filter((item) => {
      return isSlotWithItem(item) && item.name === itemName;
    });
    matchingItems?.forEach((item) => (totalCount += item.count || 0));
    return totalCount;
  }

  const matchingItems = targetInventory.items.filter((playerItem) => {
    return isSlotWithItem(playerItem) && playerItem.name === itemName;
  });

  matchingItems.forEach((item) => (totalCount += item.count || 0));

  return totalCount;
};

export const getItemData = async (itemName: string) => {
  const resp: ItemData | null = await fetchNui('getItemData', itemName);

  if (resp?.name) {
    Items[itemName] = resp;
    return resp;
  }
};

const getConfiguredUtilitySlotIds = () => {
  const utility = store.getState().inventory.utility;

  if (utility?.slotIds?.length) {
    return new Set(utility.slotIds.map((slotId) => Number(slotId)).filter((slotId) => slotId > 0));
  }

  if (utility?.items) {
    if (Array.isArray(utility.items)) {
      return new Set(
        utility.items
          .map((items, index) => (items !== undefined ? index + 1 : undefined))
          .filter((slotId): slotId is number => slotId !== undefined)
      );
    }

    return new Set(
      Object.keys(utility.items)
        .map((slotId) => Number(slotId))
        .filter((slotId) => slotId > 0)
    );
  }

  return new Set<number>([1, 2, 6, 7, 8, 9]);
};

const isRegularPlayerSlot = (slot: number) => {
  return !getConfiguredUtilitySlotIds().has(slot);
};

export const findAvailableSlot = (
  item: Slot,
  data: ItemData,
  items: Slot[],
  splitting?: boolean,
  targetType?: Inventory['type']
) => {
  if (!data.stack || splitting)
    return items.find(
      (target) =>
        target.name === undefined && (targetType === InventoryType.PLAYER ? isRegularPlayerSlot(target.slot) : true)
    );

  const stackableSlot = items.find(
    (target) =>
      target.name === item.name &&
      isEqual(target.metadata, item.metadata) &&
      (targetType === InventoryType.PLAYER ? isRegularPlayerSlot(target.slot) : true)
  );

  return (
    stackableSlot ||
    items.find(
      (target) =>
        target.name === undefined && (targetType === InventoryType.PLAYER ? isRegularPlayerSlot(target.slot) : true)
    )
  );
};

export const getTargetInventory = (
  state: State,
  sourceType: Inventory['type'],
  targetType?: Inventory['type'],
  sourceInventoryId?: Inventory['id'],
  targetInventoryId?: Inventory['id']
): { sourceInventory: Inventory; targetInventory: Inventory } => {
  const requireInventory = (
    inventory: Inventory | undefined,
    type: Inventory['type'],
    inventoryId?: Inventory['id']
  ) => {
    if (inventory) return inventory;
    throw new Error(`Inventory ${type}${inventoryId ? ` (${inventoryId})` : ''} was not found`);
  };

  const getBackpackInventory = (inventoryId?: Inventory['id']) => {
    if (inventoryId && state.backpackInventory?.id === inventoryId) return state.backpackInventory;
    if (inventoryId && state.targetBackpackInventory?.id === inventoryId) return state.targetBackpackInventory;
    return state.backpackInventory;
  };

  const getInventory = (type: Inventory['type'], inventoryId?: Inventory['id']) => {
    if (type === InventoryType.PLAYER) return state.leftInventory;
    if (type === 'backpack') return requireInventory(getBackpackInventory(inventoryId), type, inventoryId);
    if (type === 'crafting_storage') return state.craftingStorage!;
    return state.rightInventory;
  };

  if (!targetType) {
    if (sourceType === InventoryType.PLAYER)
      return { sourceInventory: state.leftInventory, targetInventory: state.rightInventory };
    if (sourceType === 'backpack') {
      return { sourceInventory: getInventory(sourceType, sourceInventoryId), targetInventory: state.leftInventory };
    }
    if (sourceType === 'crafting_storage') {
      return { sourceInventory: state.craftingStorage!, targetInventory: state.leftInventory };
    }
    return { sourceInventory: state.rightInventory, targetInventory: state.leftInventory };
  }

  return {
    sourceInventory: getInventory(sourceType, sourceInventoryId),
    targetInventory: getInventory(targetType, targetInventoryId),
  };
};

export const canPurchaseItem = (item: Slot, inventory: { type: Inventory['type']; groups: Inventory['groups'] }) => {
  if (inventory.type !== 'shop' || !isSlotWithItem(item)) return true;

  if (item.count !== undefined && item.count === 0) return false;

  if (item.grade === undefined || !inventory.groups) return true;

  const leftInventory = store.getState().inventory.leftInventory;

  if (!leftInventory.groups) return false;

  const reqGroups = Object.keys(inventory.groups);

  if (Array.isArray(item.grade)) {
    for (let i = 0; i < reqGroups.length; i++) {
      const reqGroup = reqGroups[i];

      if (leftInventory.groups[reqGroup] !== undefined) {
        const playerGrade = leftInventory.groups[reqGroup];
        for (let j = 0; j < item.grade.length; j++) {
          const reqGrade = item.grade[j];

          if (playerGrade === reqGrade) return true;
        }
      }
    }

    return false;
  } else {
    for (let i = 0; i < reqGroups.length; i++) {
      const reqGroup = reqGroups[i];
      if (leftInventory.groups[reqGroup] !== undefined) {
        const playerGrade = leftInventory.groups[reqGroup];

        if (playerGrade >= item.grade) return true;
      }
    }

    return false;
  }
};

export const canCraftItem = (
  item: Slot,
  inventoryType: string,
  reserved: { [key: string]: number } = {},
  storage?: Inventory
) => {
  if (!isSlotWithItem(item) || inventoryType !== 'crafting') return true;
  if (!item.ingredients) return true;

  const leftInventory = store.getState().inventory.leftInventory;
  if (item.blueprint) {
    const craftingData = store.getState().inventory.rightInventory?.crafting;
    if (craftingData?.blueprints && !craftingData.blueprints[item.blueprint]) {
      return false;
    }
  }

  // @ts-ignore
  if (item.xp?.required) {
    const craftingData = store.getState().inventory.rightInventory?.crafting;
    // @ts-ignore
    if (craftingData?.xp?.enabled && (craftingData.xp.current || 0) < item.xp.required) {
      return false;
    }
  }

  const ingredientItems = Object.entries(item.ingredients);

  const remainingItems = ingredientItems.filter(([ingredientName, requiredCount]) => {
    const globalItem = Items[ingredientName];

    if (requiredCount >= 1) {
      if (globalItem && globalItem.count >= requiredCount) return false;
    }

    const reservedCount = reserved[ingredientName] || 0;

    let totalAvailableCount = 0;

    // Check player inventory
    if (!storage) {
      leftInventory.items.forEach((playerItem) => {
        if (isSlotWithItem(playerItem) && playerItem.name === ingredientName) {
          if (requiredCount < 1) {
            // durability check
            if (playerItem.metadata?.durability >= requiredCount * 100) {
              totalAvailableCount += 1;
            }
          } else {
            totalAvailableCount += playerItem.count;
          }
        }
      });
    }

    // Check storage inventory if provided
    if (storage) {
      const storageItems = storage.items || [];
      storageItems.forEach((storageItem: Slot) => {
        if (isSlotWithItem(storageItem) && storageItem.name === ingredientName) {
          if (requiredCount < 1) {
            if (storageItem.metadata?.durability >= requiredCount * 100) {
              totalAvailableCount += 1;
            }
          } else {
            totalAvailableCount += storageItem.count;
          }
        }
      });
    }

    totalAvailableCount -= reservedCount;

    return totalAvailableCount < requiredCount * 1;
  });

  return remainingItems.length === 0;
};

export const getCraftItemCount = (item: Slot, reserved: { [key: string]: number } = {}, storage?: Inventory) => {
  if (!isSlotWithItem(item) || !item.ingredients) return 'infinity';

  if (item.blueprint) {
    const craftingData = store.getState().inventory.rightInventory?.crafting;
    if (craftingData?.blueprints && !craftingData.blueprints[item.blueprint]) return 0;
  }

  const leftInventory = store.getState().inventory.leftInventory;
  const ingredientItems = Object.entries(item.ingredients);

  let maxCount = Infinity;

  for (const [ingredient, ingredientCount] of ingredientItems) {
    let availableCountInInventory = 0;

    if (!storage) {
      leftInventory.items.forEach((playerItem) => {
        if (isSlotWithItem(playerItem) && playerItem.name === ingredient) {
          availableCountInInventory += playerItem.count || 0;
        }
      });
    }

    if (storage) {
      const storageItems = storage.items || [];
      storageItems.forEach((sItem) => {
        if (isSlotWithItem(sItem) && sItem.name === ingredient) {
          availableCountInInventory += sItem.count || 0;
        }
      });
    }

    if (availableCountInInventory === 0) {
      return 0;
    }

    const reservedCount = reserved[ingredient] || 0;
    availableCountInInventory -= reservedCount;

    if (availableCountInInventory < 0) availableCountInInventory = 0;

    const possibleCount = Math.floor(availableCountInInventory / ingredientCount);

    if (possibleCount < maxCount) maxCount = possibleCount;
  }

  return maxCount;
};
