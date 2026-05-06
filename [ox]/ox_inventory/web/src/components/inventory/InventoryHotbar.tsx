import React, { useState } from 'react';
import { getItemUrl, handleItemImageError, isSlotWithItem } from '../../helpers';
import useNuiEvent from '../../hooks/useNuiEvent';
import { Items } from '../../store/items';
import { getBarColor } from '../utils/WeightBar';
import { useAppSelector } from '../../store';
import { selectLeftInventory } from '../../store/inventory';
import { Slot, SlotWithItem } from '../../typings';
import SlideUp from '../utils/transitions/SlideUp';
import { getRarityChrome, getShadowColor } from './InventorySlot';

const getHotbarSlotStyle = (item: Slot | null): React.CSSProperties => {
  if (!item || !isSlotWithItem(item)) {
    return {
      '--borderColor': 'var(--ui-panel-border-faint)',
      background: 'var(--ui-item-shell-gradient-empty)',
    } as React.CSSProperties;
  }

  const rarity = Items[item.name]?.rarity || 'common';

  return getRarityChrome(rarity, {
    neutralBorderColor: 'var(--ui-panel-border-faint)',
    neutralBackground: 'var(--ui-item-shell-gradient-empty)',
    neutralBoxShadow: 'var(--ui-item-shell-inset)',
    shadowAlpha: 0.16,
  });
};

const InventoryHotbar: React.FC = () => {
  const [hotbarVisible, setHotbarVisible] = useState(false);
  const items = useAppSelector(selectLeftInventory).items.slice(9, 14);

  const [handle, setHandle] = useState<NodeJS.Timeout>();
  useNuiEvent('toggleHotbar', () => {
    if (hotbarVisible) {
      setHotbarVisible(false);
    } else {
      if (handle) clearTimeout(handle);
      setHotbarVisible(true);
      setHandle(setTimeout(() => setHotbarVisible(false), 3000));
    }
  });

  return (
    <>
      <SlideUp in={hotbarVisible}>
        <div className="absolute bottom-[3%] left-1/2 z-50">
          <div className="w-[530px] -translate-x-1/2">
            <div className="relative rounded-lg border border-neutral-500 bg-black/70 px-4 pb-4 pt-5">
              <div className="grid grid-cols-5 gap-2">
                {items.map((item, index) => {
                  const slotNumber = index + 1;
                  const slotStyle = getHotbarSlotStyle(item);
                  const rarity = item && isSlotWithItem(item) ? Items[item.name]?.rarity : undefined;
                  const count =
                    item && isSlotWithItem(item) && item.count > 1 ? item.count.toLocaleString('en-us') : null;

                  return (
                    <div
                      key={`hotbar-cell-${index}`}
                      className={`relative h-[90px] w-[90px] border border-transparent item-slot-border ${
                        item && isSlotWithItem(item) ? 'filled-slot' : 'empty-slot'
                      }`}
                      style={slotStyle}
                    >
                      <div className="absolute top-[-13px] left-1/2 z-20 -translate-x-1/2 pointer-events-none">
                        <div style={{ filter: 'var(--ui-accent-filter-soft)' }}>
                          <div
                            style={{
                              width: 26,
                              height: 26,
                              backgroundColor: 'var(--ui-accent-soft-chip)',
                              borderRadius: 6,
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                            }}
                          >
                            <div
                              style={{
                                width: 20,
                                height: 20,
                                backgroundColor: 'var(--color-primary)',
                                borderRadius: 4,
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                              }}
                            >
                              <span className="text-[10px] font-bold leading-none text-[var(--ui-accent-foreground)]">
                                {slotNumber}
                              </span>
                            </div>
                          </div>
                        </div>
                      </div>

                      {item && isSlotWithItem(item) && (
                        <>
                          <img
                            src={getItemUrl(item as SlotWithItem)}
                            className="pointer-events-none absolute left-1/2 top-1/2 z-0 h-[55px] w-[55px] -translate-x-1/2 -translate-y-1/2 object-contain"
                            alt={item.name}
                            onError={handleItemImageError}
                          />

                          {count && (
                            <p className="absolute bottom-1 left-1.5 z-10 text-[11px] font-bold leading-none text-white/85 drop-shadow-[0_1px_2px_rgba(0,0,0,0.8)]">
                              {count}
                            </p>
                          )}

                          {item.durability !== undefined && (
                            <div className="pointer-events-none absolute bottom-0 left-0 z-10 h-1 w-full bg-black/35">
                              <div
                                className="h-full"
                                style={{
                                  backgroundColor: getBarColor(item.durability, true),
                                  width: `${item.durability}%`,
                                  transition: 'background 0.3s ease, width 0.3s ease',
                                }}
                              />
                            </div>
                          )}

                          {rarity && rarity !== 'common' && (
                            <div
                              className="pointer-events-none absolute inset-x-0 bottom-0 h-[36px] opacity-75"
                              style={{
                                background: `linear-gradient(180deg, transparent 0%, ${getShadowColor(
                                  rarity,
                                  0.16
                                )} 100%)`,
                              }}
                            />
                          )}
                        </>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        </div>
      </SlideUp>
    </>
  );
};

export default InventoryHotbar;
