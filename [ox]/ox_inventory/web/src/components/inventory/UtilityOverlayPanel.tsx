import React from 'react';
import { useIntersection } from '../../hooks/useIntersection';
import { useAppSelector } from '../../store';
import { selectLeftInventory, selectUtility } from '../../store/inventory';
import InventorySlot from './InventorySlot';
import { CharacterBody } from './CharacterBody';

type UtilitySlotConfig = {
  itemIndex: number;
  utilitySlot?: number;
  fallbackIcon: string;
  defaultSize?: number;
};

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

const UtilityOverlayPanel: React.FC = () => {
  const inventory = useAppSelector(selectLeftInventory);
  const utility = useAppSelector(selectUtility);
  const isBusy = useAppSelector((state) => state.inventory.isBusy);
  const { ref } = useIntersection({ threshold: 0.5 });

  const leftLayout = utility?.layout?.left || [6, 7, 8];
  const rightLayout = utility?.layout?.right || [9, 1, 2];

  const topSlots: UtilitySlotConfig[] = [
    { itemIndex: 5, utilitySlot: leftLayout[0], fallbackIcon: 'web/images/backpack.svg', defaultSize: 38 },
    { itemIndex: 6, utilitySlot: leftLayout[1], fallbackIcon: 'web/images/armour.png', defaultSize: 36 },
    { itemIndex: 7, utilitySlot: leftLayout[2], fallbackIcon: 'web/images/phone.svg', defaultSize: 36 },
  ];

  const bottomSlots: UtilitySlotConfig[] = [
    { itemIndex: 8, utilitySlot: rightLayout[0], fallbackIcon: 'web/images/parachute.svg', defaultSize: 38 },
    { itemIndex: 0, utilitySlot: rightLayout[1], fallbackIcon: 'web/images/weapon2.svg', defaultSize: 34 },
    { itemIndex: 1, utilitySlot: rightLayout[2], fallbackIcon: 'web/images/rifle-CjmmE0yk.svg', defaultSize: 34 },
  ];

  const renderIcon = (slotConfig: UtilitySlotConfig) => {
    let icon = slotConfig.utilitySlot ? getUtilityData(utility?.icons, slotConfig.utilitySlot) : undefined;

    if (icon === false) return undefined;
    if (!icon) icon = slotConfig.fallbackIcon;
    if (typeof icon !== 'string') return undefined;

    const size =
      (slotConfig.utilitySlot && utility?.iconSizes && getUtilityData(utility.iconSizes, slotConfig.utilitySlot)) ||
      slotConfig.defaultSize ||
      36;

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

  const renderSlotRow = (slots: UtilitySlotConfig[]) => (
    <div className="grid grid-cols-3 justify-items-center gap-1.5">
      {slots.map((slotConfig, index) => (
        <div key={`utility-overlay-${slotConfig.itemIndex}-${index}`} className="origin-top scale-[0.64]">
          <InventorySlot
            item={inventory.items[slotConfig.itemIndex] || { slot: slotConfig.itemIndex + 1 }}
            ref={ref}
            inventoryType={inventory.type}
            inventoryGroups={inventory.groups}
            inventoryId={inventory.id}
            query=""
            hideNumber={true}
            backgroundImage={renderIcon(slotConfig)}
          />
        </div>
      ))}
    </div>
  );

  return (
    <div
      className="absolute left-[18px] top-1/2 z-20 w-[208px] -translate-y-1/2 rounded-lg border border-neutral-500 bg-black/70 px-2.5 py-3 overflow-hidden"
      style={{ pointerEvents: isBusy ? 'none' : 'auto' }}
    >
      {renderSlotRow(topSlots)}

      <div className="relative my-1.5 flex h-[170px] items-center justify-center overflow-hidden">
        <div className="origin-center scale-[0.38]">
          <CharacterBody />
        </div>
      </div>

      {renderSlotRow(bottomSlots)}
    </div>
  );
};

export default UtilityOverlayPanel;
