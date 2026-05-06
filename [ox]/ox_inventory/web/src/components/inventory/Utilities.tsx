import React from 'react';
import { useIntersection } from '../../hooks/useIntersection';
import { useAppSelector } from '../../store';
import { selectLeftInventory, selectUtility } from '../../store/inventory';
import InventorySlot from './InventorySlot';
import { Locale } from '../../store/locale';
import { CharacterBody } from './CharacterBody';
import { Inventory } from '../../typings';

interface UtilsProps {
  inventory?: Inventory;
  staticPosition?: boolean;
}

const getUtilityData = (data: any, slot: number) => {
  if (!data) return undefined;
  if (Array.isArray(data)) return data[slot - 1];
  return data[slot];
};

const resolveIconPath = (icon: string) => {
  if (icon.startsWith('web/images')) {
    if (typeof window !== 'undefined' && !('invokeNative' in window)) {
      return icon.replace('web/images/', 'images/');
    }

    return `nui://ox_inventory/${icon}`;
  }

  if (icon.startsWith('nui://') && typeof window !== 'undefined' && !('invokeNative' in window)) {
    return icon.replace('nui://ox_inventory/web/images/', 'images/').replace('nui://ox_inventory/', '');
  }

  return icon;
};

const fallbackIcons: Record<string, string> = {
  backpack: 'web/images/backpack.svg',
  bodyArmor: 'web/images/armour.png',
  phone: 'web/images/phone.svg',
  parachute: 'web/images/parachute.svg',
  weapon1: 'web/images/weapon2.svg',
  weapon2: 'web/images/rifle-CjmmE0yk.svg',
};

const normalizeUtilityLabel = (label: string, fallback: string) => {
  const normalized = label.trim().toLowerCase();

  switch (normalized) {
    case 'backpack':
      return Locale.backpack || fallback;
    case 'armor':
    case 'body armor':
      return Locale.body_armor || fallback;
    case 'phone':
      return Locale.phone || fallback;
    case 'parachute':
      return Locale.parachute || fallback;
    case 'weapon slot':
      return Locale.weapon_slot || fallback;
    case 'weapon slot 1':
      return `${Locale.weapon_slot || 'Weapon Slot'} 1`;
    case 'weapon slot 2':
      return `${Locale.weapon_slot || 'Weapon Slot'} 2`;
    default:
      return label;
  }
};

const Utilities: React.FC<UtilsProps> = ({ inventory, staticPosition }) => {
  const leftInventoryFromStore = useAppSelector(selectLeftInventory);
  const leftInventory = inventory || leftInventoryFromStore;
  const utility = useAppSelector(selectUtility);
  const isBusy = useAppSelector((state) => state.inventory.isBusy);
  const { ref } = useIntersection({ threshold: 0.5 });

  const leftLayout = utility?.layout?.left || [6, 7, 8];
  const rightLayout = utility?.layout?.right || [9, 1, 2];

  const getLabel = (utilitySlot: number | undefined, fallback: string) => {
    if (utilitySlot && utility?.labels) {
      const label = getUtilityData(utility.labels, utilitySlot);
      if (label) return normalizeUtilityLabel(label, fallback);
    }

    return fallback;
  };

  const renderIcon = (utilitySlot: number | undefined, fallbackKey: keyof typeof fallbackIcons, defaultSize = 56) => {
    let icon = utilitySlot ? getUtilityData(utility?.icons, utilitySlot) : undefined;

    if (icon === false) return undefined;
    if (!icon) icon = fallbackIcons[fallbackKey];
    if (typeof icon !== 'string') return undefined;

    const size = (utilitySlot && utility?.iconSizes && getUtilityData(utility.iconSizes, utilitySlot)) || defaultSize;

    return (
      <img
        src={resolveIconPath(icon)}
        alt="utility-icon"
        style={{ width: size, height: size, objectFit: 'contain' }}
        onError={(event) => {
          event.currentTarget.style.display = 'none';
        }}
      />
    );
  };

  const panelBaseClass = staticPosition
    ? 'bg-black/70 rounded-lg border border-neutral-500 w-[530px] p-3 overflow-hidden'
    : 'absolute top-1/2 left-[calc(100%-450px)] -translate-x-1/2 -translate-y-1/2 bg-black/70 rounded-lg border border-neutral-500 w-[530px] p-3 overflow-hidden';

  const sideSlotClass = 'flex flex-col gap-2 items-center';
  const sideLabelClass = 'text-white/50 font-medium text-sm text-center';

  return (
    <div
      className={panelBaseClass}
      style={{
        pointerEvents: isBusy ? 'none' : 'auto',
        transform: !staticPosition ? 'translate(-50%, -50%) perspective(1000px) rotateY(-12deg)' : undefined,
      }}
    >
      <div
        className="w-full flex justify-center"
        style={staticPosition ? { transformOrigin: 'top center' } : undefined}
      >
        <div className="grid grid-cols-[110px_260px_110px] items-center justify-center gap-3 w-fit">
          <div className="flex flex-col gap-3 items-center text-center">
            <div className={sideSlotClass}>
              <p className={sideLabelClass}>{getLabel(leftLayout[0], Locale.backpack || 'Backpack').toUpperCase()}</p>
              <InventorySlot
                key={`${leftInventory.type}-${leftInventory.id}-${(leftInventory.items[5] || { slot: 6 }).slot}`}
                item={leftInventory.items[5] || { slot: 6 }}
                ref={ref}
                inventoryType={leftInventory.type}
                inventoryGroups={leftInventory.groups}
                inventoryId={leftInventory.id}
                query=""
                hideNumber={true}
                backgroundImage={renderIcon(leftLayout[0], 'backpack')}
              />
            </div>

            <div className={sideSlotClass}>
              <p className={sideLabelClass}>
                {getLabel(leftLayout[1], Locale.body_armor || 'Body Armor').toUpperCase()}
              </p>
              <InventorySlot
                key={`${leftInventory.type}-${leftInventory.id}-${(leftInventory.items[6] || { slot: 7 }).slot}`}
                item={leftInventory.items[6] || { slot: 7 }}
                ref={ref}
                inventoryType={leftInventory.type}
                inventoryGroups={leftInventory.groups}
                inventoryId={leftInventory.id}
                query=""
                hideNumber={true}
                backgroundImage={renderIcon(leftLayout[1], 'bodyArmor')}
              />
            </div>

            <div className={sideSlotClass}>
              <p className={sideLabelClass}>{getLabel(leftLayout[2], Locale.phone || 'Phone').toUpperCase()}</p>
              <InventorySlot
                key={`${leftInventory.type}-${leftInventory.id}-${(leftInventory.items[7] || { slot: 8 }).slot}`}
                item={leftInventory.items[7] || { slot: 8 }}
                ref={ref}
                inventoryType={leftInventory.type}
                inventoryGroups={leftInventory.groups}
                inventoryId={leftInventory.id}
                query=""
                hideNumber={true}
                backgroundImage={renderIcon(leftLayout[2], 'phone')}
              />
            </div>
          </div>

          <div className="w-[260px] flex-shrink-0">
            <div className="relative flex h-[517px] items-center justify-center">
              <CharacterBody />
            </div>
          </div>

          <div className="flex flex-col gap-3 items-center text-center">
            <div className={sideSlotClass}>
              <p className={sideLabelClass}>
                {getLabel(rightLayout[0], Locale.parachute || 'Parachute').toUpperCase()}
              </p>
              <InventorySlot
                key={`${leftInventory.type}-${leftInventory.id}-${(leftInventory.items[8] || { slot: 9 }).slot}`}
                item={leftInventory.items[8] || { slot: 9 }}
                ref={ref}
                inventoryType={leftInventory.type}
                inventoryGroups={leftInventory.groups}
                inventoryId={leftInventory.id}
                query=""
                hideNumber={true}
                backgroundImage={renderIcon(rightLayout[0], 'parachute')}
              />
            </div>

            <div className={sideSlotClass}>
              <p className={sideLabelClass}>
                {getLabel(rightLayout[1], Locale.weapon_slot || 'Weapon Slot 1').toUpperCase()}
              </p>
              <InventorySlot
                key={`${leftInventory.type}-${leftInventory.id}-${(leftInventory.items[0] || { slot: 1 }).slot}`}
                item={leftInventory.items[0] || { slot: 1 }}
                ref={ref}
                inventoryType={leftInventory.type}
                inventoryGroups={leftInventory.groups}
                inventoryId={leftInventory.id}
                query=""
                hideNumber={true}
                backgroundImage={renderIcon(rightLayout[1], 'weapon1')}
              />
            </div>

            <div className={sideSlotClass}>
              <p className={sideLabelClass}>
                {getLabel(rightLayout[2], `${Locale.weapon_slot || 'Weapon Slot'} 2`).toUpperCase()}
              </p>
              <InventorySlot
                key={`${leftInventory.type}-${leftInventory.id}-${(leftInventory.items[1] || { slot: 2 }).slot}`}
                item={leftInventory.items[1] || { slot: 2 }}
                ref={ref}
                inventoryType={leftInventory.type}
                inventoryGroups={leftInventory.groups}
                inventoryId={leftInventory.id}
                query=""
                hideNumber={true}
                backgroundImage={renderIcon(rightLayout[2], 'weapon2')}
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Utilities;
