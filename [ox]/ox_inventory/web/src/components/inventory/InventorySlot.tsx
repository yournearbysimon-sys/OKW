import React, { ReactElement, useCallback, useRef } from 'react';
import { DragSource, Inventory, InventoryType, Slot, SlotWithItem } from '../../typings';
import { useDrag, useDragDropManager, useDrop } from 'react-dnd';
import { useAppDispatch, useAppSelector } from '../../store';
import { onDrop } from '../../dnd/onDrop';
import { Items } from '../../store/items';
import { canCraftItem, canPurchaseItem, getItemUrl, handleItemImageError, isSlotWithItem } from '../../helpers';
import { onUse } from '../../dnd/onUse';
import useNuiEvent from '../../hooks/useNuiEvent';
import { ItemsPayload } from '../../reducers/refreshSlots';
import { closeTooltip, openTooltip } from '../../store/tooltip';
import { openContextMenu } from '../../store/contextMenu';
import { useMergeRefs } from '@floating-ui/react';
import { Locale } from '../../store/locale';
import dragSound from '../../assets/sounds/drag.wav';
import { Rarity } from '../../store/rarity';
import { fetchNui } from '../../utils/fetchNui';
import { GiveDragTarget } from '../../typings';
import { openWorldGiveDialog } from '../../store/inventory';
import { getBarColor } from '../utils/WeightBar';
import { selectBackpackInventory } from '../../store/inventory';
import { ModifierBinding, useInventorySettings } from '../settings/InventorySettingsContext';

export const getColor = (rarity: string): { text: string; background: string } => {
  const defaultColor = Rarity.common || { text: '#7A7A7A55', background: 'transparent' };
  if (!rarity) return defaultColor;

  return Rarity[rarity.toLowerCase()] || defaultColor;
};

export const hasVisibleRarity = (rarity?: string): boolean => {
  return !!rarity && rarity.toLowerCase() !== 'common';
};

export const getShadowColor = (rarity: string, alpha: number = 0.35): string => {
  const hex = getColor(rarity).text;
  if (hex && hex.startsWith('#')) {
    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);
    if (!isNaN(r) && !isNaN(g) && !isNaN(b)) {
      return `rgba(${r}, ${g}, ${b}, ${alpha})`;
    }
  }
  return hex;
};

export const getRarityChrome = (
  rarity?: string,
  options?: {
    neutralBorderColor?: string;
    neutralBackground?: string;
    neutralBoxShadow?: string;
    shadowAlpha?: number;
  }
): React.CSSProperties => {
  if (!hasVisibleRarity(rarity)) {
    return {
      '--borderColor': options?.neutralBorderColor || 'var(--ui-panel-border-faint)',
      background: options?.neutralBackground,
      boxShadow: options?.neutralBoxShadow,
    } as React.CSSProperties;
  }

  const color = getColor(rarity as string);

  return {
    '--borderColor': color.text,
    background: color.background,
    boxShadow: `var(--ui-item-shell-inset), inset 0px -25px 35px -22px ${getShadowColor(
      rarity as string,
      options?.shadowAlpha ?? 0.18
    )}`,
  } as React.CSSProperties;
};

const isModifierHeld = (event: React.MouseEvent<HTMLDivElement>, modifier: ModifierBinding) => {
  if (modifier === 'Control') return event.ctrlKey;
  if (modifier === 'Alt') return event.altKey;
  return event.shiftKey;
};

interface SlotProps {
  inventoryId: Inventory['id'];
  inventoryType: Inventory['type'];
  inventoryGroups: Inventory['groups'];
  item: Slot;
  query: string;
  backgroundImage?: React.ReactNode;
  onClick?: (event: React.MouseEvent<HTMLDivElement>) => void;
  isSelected?: boolean;
  hideNumber?: boolean;
}

const InventorySlot: React.ForwardRefRenderFunction<HTMLDivElement, SlotProps> = (
  {
    item,
    inventoryId,
    inventoryType,
    inventoryGroups,
    query,
    backgroundImage,
    onClick,
    isSelected,
    hideNumber,
  },
  ref
) => {
  const manager = useDragDropManager();
  const dispatch = useAppDispatch();
  const timerRef = useRef<number | null>(null);
  const isHoveredRef = useRef<boolean>(false);
  const { settings } = useInventorySettings();

  const matchesQuery = (item: Slot | null, query: string = '') => {
    if (!item || typeof item.name !== 'string') return true; // Return true if slot is empty
    return (item.metadata?.label ? item.metadata.label : Items[item.name]?.label || item.name)
      .toLowerCase()
      .includes(query.toLowerCase());
  };

  const craftingStorage = useAppSelector((state) => state.inventory.craftingStorage);
  const ownerBackpackInventory = useAppSelector(selectBackpackInventory);
  const isOwnerBackpack = inventoryType === 'backpack' && ownerBackpackInventory?.id === inventoryId;
  const isWorldGiveSource = inventoryType === InventoryType.PLAYER || isOwnerBackpack;

  const canDrag = useCallback(() => {
    return (
      inventoryType !== 'crafting' &&
      canPurchaseItem(item, { type: inventoryType, groups: inventoryGroups }) &&
      canCraftItem(item, inventoryType, {}, craftingStorage) &&
      matchesQuery(item, query)
    );
  }, [item, inventoryType, inventoryGroups, query, craftingStorage]);

  const [{ isDragging }, drag] = useDrag<DragSource, void, { isDragging: boolean }>(
    () => ({
      type: 'SLOT',
      collect: (monitor) => ({
        isDragging: monitor.isDragging(),
      }),
      item: () => {
        if (!isSlotWithItem(item, inventoryType !== InventoryType.SHOP) || !matchesQuery(item, query)) return null;

        const dragItem: DragSource = {
          inventory: inventoryType,
          inventoryId,
          item,
          image: item?.name && getItemUrl(item),
        };

        if (isWorldGiveSource) {
          void fetchNui('startGiveItemDrag', { slot: item.slot, inventoryId }).catch((error) => console.error(error));
        }

        return dragItem;
      },
      end: (draggedItem, monitor) => {
        const canOpenGiveDialog =
          draggedItem &&
          (draggedItem.inventory === InventoryType.PLAYER ||
            (draggedItem.inventory === 'backpack' && draggedItem.inventoryId === ownerBackpackInventory?.id));

        if (!canOpenGiveDialog) {
          return;
        }

        const didDrop = monitor.didDrop();

        void (async () => {
          try {
            const target = await fetchNui<GiveDragTarget | false>('finishGiveItemDrag', {
              didDrop,
            });

            if (didDrop || !target || !draggedItem.inventoryId) return;

            const itemCount = Math.max(1, draggedItem.item.count || 1);

            if (itemCount === 1) {
              await fetchNui('confirmGiveItemDrag', {
                targetId: target.targetId,
                slot: draggedItem.item.slot,
                count: 1,
                inventoryId: draggedItem.inventoryId,
              });

              return;
            }

            dispatch(
              openWorldGiveDialog({
                item: draggedItem.item,
                inventoryId: draggedItem.inventoryId,
                inventoryType: draggedItem.inventory,
                target,
              })
            );
          } catch (error) {
            console.error(error);
          }
        })();
      },
      canDrag,
    }),
    [inventoryId, inventoryType, item, canDrag, query, isWorldGiveSource, dispatch, ownerBackpackInventory?.id]
  );

  const [{ isOver }, drop] = useDrop<DragSource, void, { isOver: boolean }>(
    () => ({
      accept: 'SLOT',
      collect: (monitor) => ({
        isOver: monitor.isOver(),
      }),
      drop: (source) => {
        if (settings.soundEffects) {
          const audio = new Audio(dragSound);
          void audio.play().catch(() => undefined);
        }
        dispatch(closeTooltip());
        switch (source.inventory) {
          default:
            onDrop(source, { inventory: inventoryType, inventoryId, item: { slot: item.slot } });
            break;
        }
      },
      canDrop: (source) =>
        (source.item.slot !== item.slot || source.inventory !== inventoryType || source.inventoryId !== inventoryId) &&
        source.inventory !== InventoryType.SHOP &&
        source.inventory !== InventoryType.CRAFTING &&
        inventoryType !== InventoryType.SHOP &&
        inventoryType !== InventoryType.CRAFTING,
    }),
    [inventoryId, inventoryType, item, settings.soundEffects]
  );

  useNuiEvent('refreshSlots', (data: { items?: ItemsPayload | ItemsPayload[] }) => {
    if (!isDragging && !data.items) return;
    if (!Array.isArray(data.items)) return;

    const itemSlot = data.items.find(
      (dataItem) => dataItem.item.slot === item.slot && dataItem.inventory === inventoryId
    );

    if (!itemSlot) return;

    manager.dispatch({ type: 'dnd-core/END_DRAG' });
  });

  const connectRef = (element: HTMLDivElement) => drag(drop(element));

  const handleContext = (event: React.MouseEvent<HTMLDivElement>) => {
    event.preventDefault();
    if ((inventoryType !== 'player' && !isOwnerBackpack) || !isSlotWithItem(item)) return;

    dispatch(openContextMenu({ item, coords: { x: event.clientX, y: event.clientY }, inventoryId, inventoryType }));
  };

  const handleClick = (event: React.MouseEvent<HTMLDivElement>) => {
    dispatch(closeTooltip());
    if (timerRef.current) clearTimeout(timerRef.current);

    if (onClick) {
      onClick(event);
      return;
    }

    if (
      isModifierHeld(event, settings.quickMoveModifier) &&
      isSlotWithItem(item) &&
      inventoryType !== 'shop' &&
      inventoryType !== 'crafting'
    ) {
      onDrop({ item: item, inventory: inventoryType, inventoryId });
    } else if (isModifierHeld(event, settings.useItemModifier) && isSlotWithItem(item) && inventoryType === 'player') {
      onUse(item);
    }
  };

  const refs = useMergeRefs([connectRef, ref]);
  const itemRarity = isSlotWithItem(item) ? Items[item.name as string]?.rarity : undefined;
  const commonBackground = Rarity['common']?.background;
  const rarityChrome = getRarityChrome(itemRarity, {
    neutralBorderColor: 'var(--ui-panel-border-faint)',
    neutralBackground: commonBackground,
    shadowAlpha: 0.07,
  });
  const rarityBorderColor = (rarityChrome as React.CSSProperties & { '--borderColor'?: string })['--borderColor'];

  return (
    <div
      ref={refs}
      onContextMenu={handleContext}
      onClick={handleClick}
      className={`relative w-[90px] h-[90px] border border-transparent item-slot-border ${
        isSlotWithItem(item) ? 'filled-slot' : 'empty-slot'
      }`}
      style={
        {
          '--borderColor': isSelected
            ? inventoryType === 'crafting'
              ? 'var(--ui-text-primary-25)'
              : 'var(--color-slot-border-hover)'
            : matchesQuery(item, query)
            ? rarityBorderColor || 'var(--ui-panel-border-faint)'
            : undefined,
          background: matchesQuery(item, query) && isSlotWithItem(item) ? rarityChrome.background : undefined,
          boxShadow: matchesQuery(item, query) && isSlotWithItem(item) ? rarityChrome.boxShadow : undefined,
          filter:
            !canPurchaseItem(item, { type: inventoryType, groups: inventoryGroups }) ||
            !canCraftItem(item, inventoryType, {}, craftingStorage)
              ? 'brightness(80%) grayscale(100%)'
              : undefined,
        } as React.CSSProperties
      }
    >
      {!isSlotWithItem(item) && backgroundImage && (
        <div className="absolute top-1/2 left-1/2 z-[1] -translate-x-1/2 -translate-y-1/2 pointer-events-none">
          {backgroundImage}
        </div>
      )}
      {inventoryType === 'player' && item.slot >= 10 && item.slot <= 14 && !hideNumber && (
        <div className="absolute top-[-8px] left-1/2 z-20 flex h-[21px] min-w-[21px] -translate-x-1/2 items-center justify-center rounded-[4px] border border-[#7a7a7a] bg-[#303030] px-1 pointer-events-none">
          <span className="text-[10px] font-bold leading-none text-[#bbbbbb]">{item.slot - 9}</span>
        </div>
      )}
      {isSlotWithItem(item) && matchesQuery(item, query) && (
        <div
          className="p-1.5 text-[#a8a8a8] text-xs relative w-full h-full cursor-pointer"
          onMouseEnter={() => {
            isHoveredRef.current = true;
            timerRef.current = window.setTimeout(() => {
              if (isHoveredRef.current) {
                dispatch(openTooltip({ item, inventoryType }));
              }
            }, 500);
          }}
          onMouseLeave={() => {
            isHoveredRef.current = false;
            if (timerRef.current) {
              clearTimeout(timerRef.current);
              timerRef.current = null;
            }
            dispatch(closeTooltip());
          }}
        >
          <img
            src={`${item?.name ? getItemUrl(item as SlotWithItem) : 'none'}`}
            className="absolute w-[55px] h-[55px] object-contain top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none z-0"
            alt={item.name}
            onError={handleItemImageError}
          />

          {isSlotWithItem(item) && (item as SlotWithItem).count !== undefined && (
            <div className="absolute bottom-1 left-1.5 text-[11px] font-bold text-white/80 leading-none z-10 pointer-events-none drop-shadow-[0_1px_2px_rgba(0,0,0,0.8)]">
              {(item as SlotWithItem).count}
            </div>
          )}

          {inventoryType === 'shop' && item?.price !== undefined && (
            <div className="absolute z-10 bottom-1.5 right-1.5">
              {item?.currency !== 'money' && item.currency !== 'black_money' && item.price > 0 && item.currency ? (
                <div className="flex items-center gap-1">
                  <img
                    src={item.currency ? getItemUrl(item.currency) : 'none'}
                    alt="item-image"
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
              ) : (
                <>
                  {item.price > 0 && (
                    <div className="flex items-center gap-1">
                      <p>
                        {Locale.$ || '$'}
                        {item.price.toLocaleString('en-us')}
                      </p>
                    </div>
                  )}
                </>
              )}
            </div>
          )}

          {item.durability !== undefined && (
            <div className="absolute bottom-0 left-0 z-10 h-1 w-full pointer-events-none bg-black/35">
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
        </div>
      )}
      {inventoryType === 'crafting' && !canCraftItem(item, inventoryType, {}, craftingStorage) && (
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-white/50 text-4xl z-30" />
      )}
    </div>
  );
};

export default React.memo(React.forwardRef(InventorySlot));
