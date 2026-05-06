import React, { useMemo, useState } from 'react';
import { getTotalWeight } from '../../helpers';
import { useAppSelector } from '../../store';
import { selectUtility } from '../../store/inventory';
import { Locale } from '../../store/locale';
import { Inventory } from '../../typings';
import InventorySlot from './InventorySlot';
import WeightSummary from './WeightSummary';

type CompactUtilityPanelProps = {
  inventory: Inventory;
  title?: string;
  subtitle?: string;
  panelDragState?: 'arming' | 'dragging';
  onPanelHandlePointerDown?: React.PointerEventHandler<HTMLDivElement>;
  onPanelHandlePointerUp?: React.PointerEventHandler<HTMLDivElement>;
  onPanelHandlePointerCancel?: React.PointerEventHandler<HTMLDivElement>;
};

const getUtilityData = (data: any, slot: number) => {
  if (!data) return undefined;
  if (Array.isArray(data)) return data[slot - 1];
  return data[slot];
};

const getUtilityIcon = (utility: any, utilitySlot?: number, defaultSize = 65) => {
  if (!utilitySlot || !utility?.icons) return undefined;

  let icon = getUtilityData(utility.icons, utilitySlot);

  if (icon === false || !icon) {
    return undefined;
  }

  if (typeof icon === 'string') {
    if (icon.startsWith('web/images')) {
      if (typeof window !== 'undefined' && !('invokeNative' in window)) {
        icon = icon.replace('web/images/', 'images/');
      } else {
        icon = `nui://ox_inventory/${icon}`;
      }
    } else if (icon.startsWith('nui://') && typeof window !== 'undefined' && !('invokeNative' in window)) {
      icon = icon.replace('nui://ox_inventory/web/images/', 'images/').replace('nui://ox_inventory/', '');
    }

    const size = (utility.iconSizes && getUtilityData(utility.iconSizes, utilitySlot)) || defaultSize;

    return (
      <img
        src={icon}
        alt="utility-icon"
        style={{ width: size, height: size, objectFit: 'contain' }}
        onError={(event) => {
          event.currentTarget.style.display = 'none';
        }}
      />
    );
  }

  return undefined;
};

const CompactUtilityPanel: React.FC<CompactUtilityPanelProps> = ({
  inventory,
  title = Locale.ui_utility_slots || 'Utility Slots',
  subtitle,
  panelDragState,
  onPanelHandlePointerDown,
  onPanelHandlePointerUp,
  onPanelHandlePointerCancel,
}) => {
  const utility = useAppSelector(selectUtility);
  const isBusy = useAppSelector((state) => state.inventory.isBusy);
  const [collapsed, setCollapsed] = useState(false);
  const weight = useMemo(
    () => (inventory.maxWeight !== undefined ? Math.floor(getTotalWeight(inventory.items) * 1000) / 1000 : 0),
    [inventory.items, inventory.maxWeight]
  );

  const leftLayout = utility?.layout?.left || [6, 7, 8];
  const rightLayout = utility?.layout?.right || [9, 1, 2];
  const panelSubtitle = subtitle ?? `[${inventory.id}] ${inventory.label || (Locale.ui_player_inventory || 'Player Inventory')}`;

  const utilitySlots = [
    { item: inventory.items[5] || { slot: 6 }, icon: leftLayout[0] },
    { item: inventory.items[6] || { slot: 7 }, icon: leftLayout[1] },
    { item: inventory.items[7] || { slot: 8 }, icon: leftLayout[2] },
    { item: inventory.items[8] || { slot: 9 }, icon: rightLayout[0] },
    { item: inventory.items[0] || { slot: 1 }, icon: rightLayout[1] },
    { item: inventory.items[1] || { slot: 2 }, icon: rightLayout[2] },
  ];

  return (
    <div
      className="bg-black/70 rounded-lg border border-neutral-500 w-[530px] p-5"
      style={{ pointerEvents: isBusy ? 'none' : 'auto' }}
    >
      <div className="flex items-center justify-between mb-2">
        <div
          className={`flex items-center gap-3 ${
            onPanelHandlePointerDown ? 'cursor-grab select-none touch-none active:cursor-grabbing' : ''
          } ${panelDragState === 'dragging' ? 'cursor-grabbing opacity-85' : ''}`}
          style={{ touchAction: onPanelHandlePointerDown ? 'none' : undefined }}
          onPointerDown={onPanelHandlePointerDown}
          onPointerUp={onPanelHandlePointerUp}
          onPointerCancel={onPanelHandlePointerCancel}
        >
          <div style={{ filter: 'drop-shadow(0 0 6px rgba(var(--color-primary-rgb), 0.35))' }}>
            <div
              style={{
                width: 52,
                height: 52,
                backgroundColor: 'rgba(var(--color-primary-rgb), 0.25)',
                borderRadius: 6,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                flexShrink: 0,
              }}
            >
              <div
                style={{
                  width: 42,
                  height: 42,
                  backgroundColor: 'var(--color-primary)',
                  borderRadius: 4,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                <span
                  className="material-symbols-outlined"
                  style={{ fontSize: 24, color: 'var(--ui-accent-foreground)', fontVariationSettings: "'FILL' 1" }}
                >
                  inventory_2
                </span>
              </div>
            </div>
          </div>
          <div className="flex flex-col leading-tight mt-0.5">
            <p className="text-white font-bold text-xl tracking-wide uppercase">{title}</p>
            <p className="text-[#A8A8A8] text-[13px] mt-[1px]">{panelSubtitle}</p>
          </div>
        </div>

        <div className="flex flex-col items-end gap-1">
          <div className="flex items-center text-white">
            {inventory.maxWeight && <WeightSummary weight={weight} maxWeight={inventory.maxWeight} />}
            <span
              className={`material-symbols-outlined flex-shrink-0 cursor-pointer text-white ml-2 ${
                collapsed ? 'rotate-180' : 'rotate-0'
              } transition-all duration-300`}
              style={{ fontSize: '20px' }}
              onClick={() => setCollapsed((current) => !current)}
            >
              keyboard_arrow_up
            </span>
          </div>
        </div>
      </div>

      {!collapsed && (
        <div className="pt-4 flex justify-center">
          <div className="grid grid-cols-3 gap-x-6 gap-y-4">
            {utilitySlots.map((slotData, index) => (
              <InventorySlot
                key={`${inventory.type}-${inventory.id}-utility-${slotData.item.slot}-${index}`}
                item={slotData.item}
                inventoryType={inventory.type}
                inventoryGroups={inventory.groups}
                inventoryId={inventory.id}
                query=""
                hideNumber={true}
                backgroundImage={getUtilityIcon(utility, slotData.icon)}
              />
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default CompactUtilityPanel;
