import { Slot } from './slot';

export enum InventoryType {
  PLAYER = 'player',
  SHOP = 'shop',
  CONTAINER = 'container',
  CRAFTING = 'crafting',
}

export type AccountType = 'money' | 'bank' | 'black_money';

export type Inventory = {
  id: string;
  type: string;
  slots: number;
  items: Slot[];
  maxWeight?: number;
  label?: string;
  groups?: Record<string, number>;
  accounts?: AccountType[];
  crafting?: {
    id: number | string;
    type: string;
    xp?: {
      enabled: boolean;
      current: number;
      hideLocked: boolean;
    };
    permissions?: {
      canUse?: boolean;
      canMove?: boolean;
      canPack?: boolean;
      canManage?: boolean;
      isOwner?: boolean;
      roleId?: number | null;
      roleName?: string | null;
    };
    blueprints?: Record<string, any>;
    queue?: any[];
  };
  storage?: Inventory;
  permissions?: {
    canUse?: boolean;
    canMove?: boolean;
    canPack?: boolean;
    canManage?: boolean;
    isOwner?: boolean;
    roleId?: number | null;
    roleName?: string | null;
  };
};
