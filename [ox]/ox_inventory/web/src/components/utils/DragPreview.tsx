import React, { useMemo, useRef, useState } from 'react';
import { useDragLayer, XYCoord } from 'react-dnd';
import { useScale } from '../../hooks/useScale';
import { DragSource, GiveDragTargetState } from '../../typings';
import { getRarityChrome } from '../inventory/InventorySlot';
import { Items } from '../../store/items';
import { Locale } from '../../store/locale';
import { getItemUrl, handleItemImageError } from '../../helpers';
import useNuiEvent from '../../hooks/useNuiEvent';
import { getBarColor } from './WeightBar';

interface DragLayerProps {
  data: DragSource;
  currentOffset: XYCoord | null;
  isDragging: boolean;
}

const subtract = (a: XYCoord, b: XYCoord): XYCoord => ({
  x: a.x - b.x,
  y: a.y - b.y,
});

const calculateParentOffset = (monitor: any): XYCoord => {
  const client = monitor.getInitialClientOffset();
  const source = monitor.getInitialSourceClientOffset();
  if (!client || !source) return { x: 0, y: 0 };
  return subtract(client, source);
};

export const calculatePointerPosition = (monitor: any, childRef: React.RefObject<Element>): XYCoord | null => {
  const offset = monitor.getClientOffset();
  if (!offset) return null;

  if (!childRef.current || !childRef.current.getBoundingClientRect) {
    return subtract(offset, calculateParentOffset(monitor));
  }

  const bb = childRef.current.getBoundingClientRect();
  const middle = { x: bb.width / 2, y: bb.height / 2 };
  return subtract(offset, middle);
};

const DragPreview: React.FC = () => {
  const element = useRef<HTMLDivElement>(null);
  const scale = useScale();
  const [giveTarget, setGiveTarget] = useState<GiveDragTargetState>({ active: false, valid: false });

  const { data, isDragging, currentOffset } = useDragLayer<DragLayerProps>((monitor) => ({
    data: monitor.getItem(),
    currentOffset: calculatePointerPosition(monitor, element),
    isDragging: monitor.isDragging(),
  }));

  useNuiEvent<GiveDragTargetState>('giveDragTarget', setGiveTarget);

  const item = data?.item;
  const itemMeta = item ? Items[item.name] : undefined;
  const isWorldGiveDrag = data?.inventory === 'player' || data?.inventory === 'backpack';

  const rarity = itemMeta?.rarity || 'common';
  const dragSlotStyle = useMemo(
    () =>
      getRarityChrome(rarity, {
        neutralBorderColor: 'var(--ui-panel-border-faint)',
        shadowAlpha: 0.16,
      }),
    [rarity]
  );

  const priceDisplay = (() => {
    if (!item || item.price === undefined || item.price <= 0) return null;

    if (item.currency && item.currency !== 'money' && item.currency !== 'black_money') {
      return (
        <div className="flex items-center gap-1">
          <img
            src={getItemUrl(item.currency)}
            alt="currency"
            style={{
              imageRendering: '-webkit-optimize-contrast',
              height: 'auto',
              width: '2vh',
              backfaceVisibility: 'hidden',
              transform: 'translateZ(0)',
            }}
            onError={handleItemImageError}
          />
          <p>{item.price.toLocaleString('en-us')}</p>
        </div>
      );
    }
    return (
      <div className="flex items-center gap-1">
        <p>
          {Locale.$ || '$'}
          {item.price.toLocaleString('en-us')}
        </p>
      </div>
    );
  })();

  if (!isDragging || !currentOffset || !item) return null;

  return (
    <div
      className="fixed top-0 left-0 z-[99999] w-[90px] h-[90px] border border-transparent item-slot-border filled-slot pointer-events-none"
      ref={element}
      style={{
        transform: `translate(${currentOffset.x}px, ${currentOffset.y}px) scale(${scale})`,
        ...dragSlotStyle,
      }}
    >
      <div className="p-1.5 text-[#a8a8a8] text-xs relative w-full h-full">
        <img
          src={data.image}
          alt={itemMeta?.label || item.name}
          className="absolute w-[55px] h-[55px] object-contain top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none z-0"
          onError={handleItemImageError}
        />

        {item.count > 1 && (
          <div className="absolute bottom-1 left-1.5 text-[11px] font-bold text-white/80 leading-none z-10 pointer-events-none drop-shadow-[0_1px_2px_rgba(0,0,0,0.8)]">
            {item.count}
          </div>
        )}

        {data.inventory === 'shop' && priceDisplay && (
          <div className="absolute z-10 bottom-1.5 right-1.5">{priceDisplay}</div>
        )}

        {item.durability !== undefined && (
          <div className="absolute h-1 w-full bottom-0 left-0 bg-black/35">
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
        {isWorldGiveDrag && giveTarget.valid && (
          <div className="absolute left-1/2 top-full z-20 mt-2 w-[120px] -translate-x-1/2 rounded-lg border border-neutral-500 bg-black/70 px-2.5 py-2 shadow-[0_14px_30px_rgba(0,0,0,0.34)]">
            <div className="flex items-center gap-2">
              <div style={{ filter: 'var(--ui-accent-filter-soft)' }}>
                <div
                  style={{
                    width: 28,
                    height: 28,
                    backgroundColor: 'var(--ui-accent-soft-chip)',
                    borderRadius: 6,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    flexShrink: 0,
                  }}
                >
                  <div
                    style={{
                      width: 22,
                      height: 22,
                      backgroundColor: 'var(--color-primary)',
                      borderRadius: 4,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                    }}
                  >
                    <span
                      className="material-symbols-outlined"
                      style={{
                        fontSize: 12,
                        color: 'var(--ui-accent-foreground-soft)',
                        fontVariationSettings: "'FILL' 1",
                      }}
                    >
                      pan_tool_alt
                    </span>
                  </div>
                </div>
              </div>

              <div className="min-w-0 flex-1 text-left leading-tight">
                <p className="text-[9px] font-bold uppercase tracking-[0.16em] text-white">
                  {Locale.ui_give || 'Give'}
                </p>
                <p className="mt-0.5 truncate text-[10px] font-semibold text-[var(--color-primary)]">
                  {`${Locale.ui_give || 'Give'}: ${giveTarget.targetName || `[${giveTarget.targetId}]`}`}
                </p>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default DragPreview;
