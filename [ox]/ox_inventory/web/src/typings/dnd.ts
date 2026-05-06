import { Inventory } from './inventory';
import { Slot, SlotWithItem } from './slot';

export type DragSource = {
  item: SlotWithItem;
  inventory: Inventory['type'];
  inventoryId?: Inventory['id'];
  image?: string;
};

export type DropTarget = {
  item: Pick<Slot, 'slot'>;
  inventory: Inventory['type'];
  inventoryId?: Inventory['id'];
};

export type GiveDragTarget = {
  targetId: number;
  targetName?: string;
};

export type GiveDragTargetState = {
  active: boolean;
  valid: boolean;
  targetId?: number;
  targetName?: string;
};

export type WorldGiveDialog = {
  item: SlotWithItem;
  inventoryId: Inventory['id'];
  inventoryType: Inventory['type'];
  target: GiveDragTarget;
};
