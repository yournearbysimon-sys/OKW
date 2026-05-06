import React, { useEffect, useMemo, useRef, useState, useCallback } from 'react';
import { AccountType, CraftSlot, DragSource, Inventory, SlotWithItem } from '../../typings';
import InventorySlot, { getColor } from './InventorySlot';
import {
  canCraftItem,
  getCraftItemCount,
  getItemCount,
  getItemUrl,
  handleItemImageError,
  getTotalWeight,
  useCurrentTime,
} from '../../helpers';
import useNuiEvent from '../../hooks/useNuiEvent';
import { fetchNui } from '../../utils/fetchNui';
import { PlayerID, useAppSelector } from '../../store';
import { useIntersection } from '../../hooks/useIntersection';
import { Locale } from '../../store/locale';
import { Items } from '../../store/items';
import { getItemCategoryName } from '../../helpers/categories';
import Fade from '../utils/transitions/Fade';
import CircularProgress from './CircularProgress';
import WeightSummary from './WeightSummary';
import { onCraft } from '../../dnd/onCraft';
import { useDrag, useDrop } from 'react-dnd';
import dragSound from '../../assets/sounds/drag.wav';
import { useMergeRefs } from '@floating-ui/react';
import { onBuy } from '../../dnd/onBuy';

const PAGE_SIZE = 30;
const INVENTORY_GRID_COLUMNS = 5;
const INVENTORY_GRID_MAX_VISIBLE_ROWS = 3;
const INVENTORY_SLOT_SIZE = 90;
const INVENTORY_GRID_GAP = 8;
const INVENTORY_GRID_VERTICAL_PADDING = 16;

const normalizeUtilitySlotIds = (slotIds?: Iterable<number>) => {
  return Array.from(new Set(Array.from(slotIds ?? []).map(Number).filter((slot) => Number.isInteger(slot) && slot > 0)));
};

const formatLocale = (key: string, fallback: string, replacements?: Record<string, string | number>) => {
  let value = Locale[key] || fallback;

  if (replacements) {
    Object.entries(replacements).forEach(([replacementKey, replacementValue]) => {
      value = value.replace(new RegExp(`\\{${replacementKey}\\}`, 'g'), String(replacementValue));
    });
  }

  return value;
};

const InventoryGrid: React.FC<{
  inventory: Inventory;
  inv: string;
  staticPosition?: boolean;
  gridClassName?: string;
  disableGridScroll?: boolean;
  defaultClosed?: boolean;
  offset?: number;
  limit?: number;
  customTitle?: string;
  customSubtitle?: string;
  searchQuery?: string;
  category?: string;
  panelDragState?: 'arming' | 'dragging';
  onPanelHandlePointerDown?: React.PointerEventHandler<HTMLDivElement>;
  onPanelHandlePointerUp?: React.PointerEventHandler<HTMLDivElement>;
  onPanelHandlePointerCancel?: React.PointerEventHandler<HTMLDivElement>;
}> = ({
  inventory,
  inv,
  staticPosition,
  gridClassName,
  disableGridScroll,
  defaultClosed,
  offset,
  limit,
  customTitle,
  customSubtitle,
  searchQuery,
  category,
  panelDragState,
  onPanelHandlePointerDown,
  onPanelHandlePointerUp,
  onPanelHandlePointerCancel,
}) => {
  const weight = useMemo(
    () => (inventory.maxWeight !== undefined ? Math.floor(getTotalWeight(inventory.items) * 1000) / 1000 : 0),
    [inventory.maxWeight, inventory.items]
  );

  const [page, setPage] = useState(0);
  const { ref, entry } = useIntersection({ threshold: 0.5 });
  const isBusy = useAppSelector((state) => state.inventory.isBusy);
  const [closed, setClosed] = useState<string[]>([]);
  const leftInventory = useAppSelector((state) => state.inventory.leftInventory);
  const rightInventory = useAppSelector((state) => state.inventory.rightInventory);
  const craftingStorage = useAppSelector((state) => state.inventory.craftingStorage);
  const utility = useAppSelector((state) => state.inventory.utility);
  const craftingData = inventory?.crafting;

  useEffect(() => {
    if (entry && entry.isIntersecting) {
      setPage((prev) => ++prev);
    }
  }, [entry]);

  useEffect(() => {
    const shouldCollapseForShop = inventory.type === 'player' && rightInventory?.type === 'shop';

    if (shouldCollapseForShop) {
      setClosed((prev) => (prev.includes(inv) ? prev : [...prev, inv]));
    }
  }, [rightInventory?.type, inventory.type, inv]);

  useEffect(() => {
    if (!defaultClosed) return;

    setClosed((prev) => (prev.includes(inv) ? prev : [...prev, inv]));
  }, [defaultClosed, inv, inventory.id]);

  const craftSearchValue = searchQuery ?? '';
  const [craftItem, setCraftItem] = useState<SlotWithItem | undefined>();
  const ingredients = useMemo(() => {
    if (!craftItem || !craftItem.ingredients) return null;
    return Object.entries(craftItem.ingredients).sort((a, b) => a[1] - b[1]);
  }, [craftItem]);
  const [countToCraft, setCountToCraft] = useState<number>(1);
  const [craftQueue, setCraftQueue] = useState<CraftSlot[]>(() => craftingData?.queue || []);

  const mapQueueEntries = useCallback(
    (entries: any[]): (CraftSlot & { recipeSlot?: number })[] => {
      if (!entries || !Array.isArray(entries)) return [];

      return entries.map((entry) => {
        const recipeSlot = entry.recipeSlot;
        const recipe = inventory.items && inventory.items[recipeSlot - 1];
        const base = (recipe as SlotWithItem) || ({} as SlotWithItem);

        const baseCraftCount =
          typeof base.count === 'number' ? base.count : Array.isArray(base.count) ? base.count[0] : 1;

        return {
          slot: base.slot ?? recipeSlot,
          recipeSlot,
          name: base.name ?? (entry.recipe as any) ?? '',
          count: base.count ?? 1,
          weight: base.weight ?? 0,
          durability: base.durability,
          price: base.price,
          currency: base.currency,
          ingredients: base.ingredients,
          duration: (entry.duration ? entry.duration * 1000 : base.duration) as any,
          metadata: base.metadata ?? entry.metadata,
          craftCount: Math.max(1, entry.craftCount ?? baseCraftCount),
          startedAt: entry.startedAt ? entry.startedAt * 1000 : undefined,
        } as CraftSlot & { recipeSlot?: number };
      });
    },
    [inventory.items]
  );

  useEffect(() => {
    if (craftingData?.queue === undefined) return;
    setCraftQueue(mapQueueEntries(craftingData.queue));
  }, [craftingData?.queue, mapQueueEntries]);

  useNuiEvent<any>('updateCraftingQueue', (queue) => {
    setCraftQueue(mapQueueEntries(queue));
  });

  useEffect(() => {
    setCountToCraft(1);
  }, [craftItem]);

  const reserved = useMemo(() => {
    const reservedMap: { [key: string]: number } = {};
    if (!craftQueue) return reservedMap;

    craftQueue.forEach((craft: any) => {
      const recipeItem = inventory.items.find((item) => item.slot === craft.recipeSlot) as SlotWithItem;

      if (!recipeItem || !recipeItem.ingredients) return;
      Object.entries(recipeItem.ingredients).forEach(([name, count]) => {
        reservedMap[name] = (reservedMap[name] || 0) + count * craft.craftCount;
      });
    });
    return reservedMap;
  }, [craftingData?.queue, inventory.items]);

  const now = useCurrentTime();

  const filteredCraftItems = useMemo(() => {
    return inventory.items.slice(0, (page + 1) * PAGE_SIZE).filter((item) => {
      const slotItem = item as SlotWithItem;

      if (!slotItem.ingredients) return false;

      const label = item.metadata?.label ?? Items[item.name as string]?.label ?? item.name ?? '';

      if (craftingData?.xp?.hideLocked && slotItem.xp?.required) {
        if ((craftingData.xp.current ?? 0) < slotItem.xp.required) return false;
      }

      return label.toLowerCase().includes(craftSearchValue.toLowerCase());
    });
  }, [inventory.items, page, craftSearchValue, craftingData]);

  const [shoppingCart, setShoppingCart] = useState<SlotWithItem[]>([]);
  const [animatedTotal, setAnimatedTotal] = useState(0);

  const actualTotal = shoppingCart.reduce((total, item) => total + (item.price ?? 0) * (item.count || 1), 0);

  useEffect(() => {
    let start: any = null;
    let animationFrameId: number;

    const duration = 500; // ms
    const difference = actualTotal - animatedTotal;

    const step = (timestamp: number) => {
      if (!start) start = timestamp;
      const progress = Math.min((timestamp - start) / duration, 1);
      const currentValue = animatedTotal + difference * progress;
      setAnimatedTotal(currentValue);
      if (progress < 1) {
        animationFrameId = requestAnimationFrame(step);
      }
    };

    animationFrameId = requestAnimationFrame(step);
    return () => cancelAnimationFrame(animationFrameId);
  }, [actualTotal]);

  const [{ isDragging }, drag] = useDrag<DragSource, void, { isDragging: boolean }>(
    () => ({
      type: 'SLOT',
      collect: (monitor) => ({
        isDragging: monitor.isDragging(),
      }),
    }),
    [inventory.type]
  );

  const [{ isOver }, drop] = useDrop<DragSource, void, { isOver: boolean }>(
    () => ({
      accept: 'SLOT',
      collect: (monitor) => ({
        isOver: monitor.isOver(),
      }),
      drop: (source) => {
        setClosed((prev) => (prev.includes(inv + '-cart') ? prev : [...prev, inv + '-cart']));
        const audio = new Audio(dragSound);
        audio.play();

        setShoppingCart((prev) => {
          const existingItemIndex = prev.findIndex((item) => item.name === source.item.name);

          if (existingItemIndex > -1) {
            const newCart = [...prev];
            newCart[existingItemIndex] = {
              ...newCart[existingItemIndex],
              count: (newCart[existingItemIndex].count || 0) + 1,
            };
            return newCart;
          }

          return [...prev, { ...source.item, count: 1 }];
        });
      },
      canDrop: (source) => source.inventory === 'shop',
    }),
    [inventory.type]
  );

  const connectRef = (element: HTMLDivElement) => drag(drop(element));
  const refs = useMergeRefs([connectRef, ref]);

  const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

  const handleBuy = async (account: AccountType) => {
    for (let i = 0; i < shoppingCart.length; i++) {
      const item = shoppingCart[i];
      onBuy(item, account);
      await delay(250);
    }
    setShoppingCart([]);
  };

  const playerUtilitySlotIds = useMemo(() => {
    if (utility?.slotIds?.length) {
      return new Set(normalizeUtilitySlotIds(utility.slotIds));
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
  }, [utility]);
  const usePocketLayout =
    (inv === 'left' && inventory.type === 'player') || (inv === 'right' && inventory.type === 'otherplayer');

  const filteredInventoryItems = useMemo(() => {
    const visibleItems = usePocketLayout
      ? [
          ...inventory.items.slice(9, 14), // keep hotkey row first
          ...inventory.items.filter((item) => item.slot < 10 && !playerUtilitySlotIds.has(item.slot)),
          ...inventory.items.slice(14), // rest of regular inventory
        ]
      : inventory.items;

    const start = usePocketLayout ? 0 : offset || 0;
    const searchValue = searchQuery ?? '';
    const hasActiveSearch = searchValue.trim().length > 0;
    const hasActiveCategory = !!category && category !== 'All';
    const filteredItems = visibleItems.filter((item) => {
      if ((hasActiveSearch || hasActiveCategory) && !item.name) {
        return false;
      }

      const label = item.metadata?.label ?? Items[item.name as string]?.label ?? item.name ?? '';

      let isCategoryMatch = true;
      if (hasActiveCategory && item.name) {
        isCategoryMatch = getItemCategoryName(Items[item.name as string]) === category;
      }

      if (!isCategoryMatch) return false;

      return label.toLowerCase().includes(searchValue.toLowerCase());
    });

    const end = limit ? start + limit : (page + 1) * PAGE_SIZE;

    return filteredItems.slice(start, end);
  }, [inventory.items, inventory.type, page, inv, offset, limit, searchQuery, category, playerUtilitySlotIds]);

  const inventoryTitle =
    customTitle ??
    (inventory.type === 'player'
      ? Locale.ui_pockets || 'POCKETS'
      : inventory.type === 'otherplayer'
      ? inventory.label || (Locale.ui_player || 'PLAYER')
      : inventory.label);

  const inventorySubtitle =
    customSubtitle ??
    (inventory.type === 'player'
      ? Locale.ui_items_on_character || 'Items on your character'
      : inventory.type === 'otherplayer'
      ? `[${inventory.id}] ${inventory.label || (Locale.ui_player_inventory || 'Player Inventory')}`
      : `[${PlayerID[0]}] ${inventory.label || (Locale.ui_inventory || 'Inventory')}`);
  const inventoryGridOverflowClass = disableGridScroll ? 'overflow-visible' : 'overflow-y-auto';
  const inventoryGridHeightClass = gridClassName || '';
  const inventoryGridRowCount = Math.max(1, Math.ceil(filteredInventoryItems.length / INVENTORY_GRID_COLUMNS));
  const inventoryGridVisibleRows = Math.min(inventoryGridRowCount, INVENTORY_GRID_MAX_VISIBLE_ROWS);
  const inventoryGridHeight =
    inventoryGridVisibleRows * INVENTORY_SLOT_SIZE +
    Math.max(0, inventoryGridVisibleRows - 1) * INVENTORY_GRID_GAP +
    INVENTORY_GRID_VERTICAL_PADDING;
  const inventoryGridStyle = {
    height: `${inventoryGridHeight}px`,
    maxHeight: `${inventoryGridHeight}px`,
  };

  return (
    <>
      {inventory.type !== 'crafting' && inventory.type !== 'shop' && (
        <div
          className={`bg-black/70 rounded-lg border border-neutral-500 w-[530px] p-5 ${
            !staticPosition ? `absolute top-1/2 ${inv === 'left' ? 'left-[360px]' : 'left-[calc(100%-360px)]'}` : ''
          }`}
          style={{
            pointerEvents: isBusy ? 'none' : 'auto',
            transform: !staticPosition
              ? `translate(-50%, -50%) perspective(1000px) rotateY(${inv === 'left' ? '12deg' : '-12deg'})`
              : undefined,
          }}
        >
          {/* Header Row */}
          <div className="flex items-center justify-between mb-2">
            {/* Left: Icon Badge + Title */}
            <div
              className={`flex items-center gap-3 ${
                onPanelHandlePointerDown ? 'cursor-grab select-none touch-none active:cursor-grabbing' : ''
              } ${panelDragState === 'dragging' ? 'cursor-grabbing opacity-85' : ''}`}
              style={{ touchAction: onPanelHandlePointerDown ? 'none' : undefined }}
              onPointerDown={onPanelHandlePointerDown}
              onPointerUp={onPanelHandlePointerUp}
              onPointerCancel={onPanelHandlePointerCancel}
            >
              {/* Glowing Badge */}
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
                      style={{
                        fontSize: 24,
                        color: 'var(--ui-accent-foreground)',
                        fontVariationSettings: "'FILL' 1",
                      }}
                    >
                      {inventory.type === 'player' ? 'dns' : 'inventory_2'}
                    </span>
                  </div>
                </div>
              </div>
              {/* Title + Subtitle */}
              <div className="flex flex-col leading-tight mt-0.5">
                <p className="text-white font-bold text-xl tracking-wide uppercase">{inventoryTitle}</p>
                <p className="text-[#A8A8A8] text-[13px] mt-[1px]">{inventorySubtitle}</p>
              </div>
            </div>

            {/* Right: Weight + Toggle */}
            <div className="flex flex-col items-end gap-1">
              <div className="flex items-center text-white">
                {inventory.maxWeight && <WeightSummary weight={weight} maxWeight={inventory.maxWeight} />}
                <span
                  className={`material-symbols-outlined flex-shrink-0 cursor-pointer text-white ml-2 ${
                    closed.includes(inv) ? 'rotate-180' : 'rotate-0'
                  } transition-all duration-300`}
                  style={{ fontSize: '20px' }}
                  onClick={() => {
                    setClosed((prev) => (prev.includes(inv) ? prev.filter((id) => id !== inv) : [...prev, inv]));
                  }}
                >
                  keyboard_arrow_up
                </span>
              </div>
            </div>
          </div>

          <div className="mb-3"></div>
          <AccordionSection open={!closed.includes(inv)}>
            <div
              className={`grid grid-cols-5 content-start pr-1 pt-3 pb-1 gap-2 ${inventoryGridOverflowClass} ${inventoryGridHeightClass}`}
              style={inventoryGridStyle}
            >
              {filteredInventoryItems.map((item, index) => (
                <InventorySlot
                  key={`${inventory.type}-${inventory.id}-${item.slot}`}
                  item={item}
                  ref={index === filteredInventoryItems.length - 1 ? ref : null}
                  inventoryType={inventory.type}
                  inventoryGroups={inventory.groups}
                  inventoryId={inventory.id}
                  query={searchQuery ?? ''}
                />
              ))}
            </div>
          </AccordionSection>
        </div>
      )}
      {inventory.type === 'crafting' && (
        <div
          className={`font-[Inter] w-[530px] bg-black/70 rounded-lg border border-neutral-500 p-5 flex flex-col ${
            !staticPosition ? `absolute top-1/2 ${inv === 'left' ? 'left-[360px]' : 'left-[calc(100%-360px)]'}` : ''
          }`}
          style={{
            order: -1,
            pointerEvents: isBusy ? 'none' : 'auto',
            transform: !staticPosition
              ? `translate(-50%, -50%) perspective(1000px) rotateY(${inv === 'left' ? '12deg' : '-12deg'})`
              : undefined,
          }}
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
                      style={{
                        fontSize: 24,
                        color: 'var(--ui-accent-foreground)',
                        fontVariationSettings: "'FILL' 1",
                      }}
                    >
                      construction
                    </span>
                  </div>
                </div>
              </div>
              <div className="flex flex-col leading-tight mt-0.5">
                <p className="text-white font-bold text-xl tracking-wide uppercase">
                  {inventory.label || Locale.recipes || 'Crafting'}
                </p>
                <p className="text-[#A8A8A8] text-[13px] mt-[1px]">
                  {Locale.recipes_and_crafting_queue || 'Recipes and crafting queue'}
                </p>
              </div>
            </div>
            <div className="flex flex-col items-end gap-2">
              <div className="flex items-center gap-2">
                {craftingData?.xp?.enabled && (
                  <div className="flex items-center gap-1.5 whitespace-nowrap font-bold text-[15px] leading-none text-white">
                    <i className="fa-solid fa-star text-[14px] text-yellow-500"></i>
                    <span>{craftingData.xp.current} XP</span>
                  </div>
                )}
                <span
                  className={`material-symbols-outlined flex-shrink-0 cursor-pointer text-white ${
                    closed.includes(inv) ? 'rotate-180' : 'rotate-0'
                  } transition-all duration-300`}
                  style={{ fontSize: '20px' }}
                  onClick={() => {
                    setClosed((prev) => (prev.includes(inv) ? prev.filter((id) => id !== inv) : [...prev, inv]));
                  }}
                >
                  keyboard_arrow_up
                </span>
              </div>
            </div>
          </div>

          <AccordionSection open={!closed.includes(inv)}>
            <div className="grid grid-cols-5 content-start gap-2 pr-1 pb-1 mt-4 max-h-[290px] overflow-y-auto">
              {filteredCraftItems.length === 0 ? (
                <p className="col-span-4 text-white text-2xl text-center py-5">
                  {(Locale.no_items_found || 'No items found').toUpperCase()}
                </p>
              ) : (
                filteredCraftItems.map((item, index) => {
                  const slotItem = item as SlotWithItem;
                  const isBlueprintLocked = slotItem.blueprint && !craftingData?.blueprints?.[slotItem.blueprint];
                  const isXpLocked = slotItem.xp?.required && (craftingData?.xp?.current || 0) < slotItem.xp.required;
                  const isLocked = isBlueprintLocked || isXpLocked;

                  return (
                    <InventorySlot
                      key={`${inventory.type}-${inventory.id}-${item.slot}`}
                      item={item}
                      inventoryType={inventory.type}
                      inventoryGroups={inventory.groups}
                      inventoryId={inventory.id}
                      query={craftSearchValue}
                      isSelected={craftItem === item}
                      onClick={() => !isLocked && setCraftItem(item as SlotWithItem)}
                      backgroundImage={
                        isLocked && (
                          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-white/50 text-4xl z-50">
                            {/* <i className="fas fa-lock"></i> */}
                          </div>
                        )
                      }
                    />
                  );
                })
              )}
            </div>

            <div className="border-b border-neutral-600 my-4"></div>

            <div className="flex items-center justify-between">
              <div className="flex flex-col leading-tight">
                <p className="text-white font-bold text-xl tracking-wide uppercase">
                  {craftItem
                    ? craftItem.metadata?.label || Items[craftItem.name]?.label || craftItem.name
                    : Locale.select_item_to_craft || 'Craft Details'}
                </p>
                <p className="text-[#A8A8A8] text-[13px] mt-[1px]">
                  {craftItem
                    ? Locale.item_required || 'Items required'
                    : Locale.select_item_to_craft || 'Select an item to craft'}
                </p>
              </div>
              {craftItem && (
                <div className="flex items-center gap-4 text-right">
                  <div className="flex flex-col">
                    <p className="text-neutral-400 text-[11px] uppercase">{Locale.quantity || 'Quantity'}</p>
                    <p className="text-white text-lg font-semibold">{craftItem.count}</p>
                  </div>
                  <div className="flex flex-col">
                    <p className="text-neutral-400 text-[11px] uppercase">{Locale.crafting_time || 'Crafting Time'}</p>
                    <p className="text-white text-lg font-semibold">{(craftItem.duration ?? 3000) / 1000}s</p>
                  </div>
                </div>
              )}
            </div>

            <div className="border-b border-neutral-600 mt-5 mb-4"></div>

            <div className={`relative ${!craftItem ? 'h-[220px]' : ''}`}>
              <Fade in={!craftItem}>
                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 flex items-center justify-center flex-col text-white w-full gap-2">
                  <i className="fa-regular fa-square-plus text-3xl text-white/70"></i>
                  <p className="text-lg font-light uppercase tracking-wide text-center">
                    {(Locale.select_item_to_craft || 'Select an item to craft').toUpperCase()}
                  </p>
                </div>
              </Fade>

              <Fade in={!!craftItem}>
                {craftItem && (
                  <>
                    <p className="text-neutral-400 font-[Inter]">
                      {(Locale.item_required || 'Items required').toUpperCase()}
                    </p>
                    <div className="mt-3 flex items-center gap-4 flex-wrap">
                      {ingredients && ingredients.length > 0 ? (
                        ingredients.map(([item, count]) => {
                          const available = getItemCount(item, craftingStorage) - (reserved[item] || 0);
                          const hasEnough = available >= count;

                          return (
                            <div
                              key={`ingredient-${item}`}
                              className="relative w-[90px] h-[90px] border border-transparent item-slot-border filled-slot pointer-events-none"
                              style={
                                {
                                  '--borderColor': hasEnough ? 'var(--color-primary-dark)' : 'rgba(135,135,135,0.45)',
                                  background: hasEnough
                                    ? 'linear-gradient(135deg, rgba(34, 44, 20, 0.58) 0%, rgba(20, 20, 20, 0.34) 100%)'
                                    : undefined,
                                } as React.CSSProperties
                              }
                            >
                              <img
                                src={item ? getItemUrl(item) : 'none'}
                                alt="item-image"
                                className="w-[55px] h-[55px] object-contain absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2"
                                onError={handleItemImageError}
                              />
                              <p className="absolute bottom-1 left-1.5 text-[11px] font-bold text-white/85 leading-none drop-shadow-[0_1px_2px_rgba(0,0,0,0.8)]">
                                {available}/{count}
                              </p>
                            </div>
                          );
                        })
                      ) : (
                        <p className="text-white text-xl">
                          {(Locale.no_items_required || 'No items required').toUpperCase()}
                        </p>
                      )}
                    </div>

                    <div className="flex items-center gap-2 mt-4 text-sm">
                      {!!craftItem.blueprint && (
                        <div className="flex items-center gap-1.5 px-2 py-1 bg-blue-900/30 border border-blue-800 rounded text-blue-200">
                          <i className="fa-solid fa-scroll"></i>
                          <span>{Locale.blueprint_required || 'Blueprint Required'}</span>
                        </div>
                      )}
                      {!!craftItem.xp?.required && (
                        <div className="flex items-center gap-1.5 px-2 py-1 bg-yellow-900/30 border border-yellow-800 rounded text-yellow-200">
                          <i className="fa-solid fa-star"></i>
                          <span>
                            {formatLocale('requires_xp', 'Requires {xp} XP', { xp: craftItem.xp.required })}
                          </span>
                        </div>
                      )}
                    </div>
                    <div className="mt-3 flex items-end gap-2.5">
                      <div className="font-[Inter] flex flex-col gap-1.5">
                        <p className="text-neutral-400 text-[11px]">{(Locale.quantity || 'Quantity').toUpperCase()}</p>
                        <div className="text-white flex items-center justify-center gap-2 bg-[linear-gradient(135deg,rgba(23,23,23,0.45)_0%,rgba(23,23,23,0.08)_100%)] w-[114px] h-[46px] rounded-md border border-[rgba(135,135,135,0.2)]">
                          <i
                            className="fa-solid fa-minus text-[11px] cursor-pointer hover:text-white/50 duration-200"
                            onClick={() => setCountToCraft((prev) => Math.max(prev - 1, 1))}
                          />
                          <input
                            type="text"
                            className="bg-transparent focus:outline-none w-[30px] text-center text-[16px] font-semibold"
                            value={countToCraft}
                            onChange={(e) => {
                              const max = getCraftItemCount(craftItem, reserved, craftingStorage);
                              const val = Number(e.target.value);
                              setCountToCraft(() => {
                                if (isNaN(val)) return 1;
                                if (max === 'infinity') return val;
                                return Math.min(val, max as number);
                              });
                            }}
                          />
                          <i
                            className="fa-solid fa-plus text-[11px] cursor-pointer hover:text-white/50 duration-200"
                            onClick={() => {
                              const max = getCraftItemCount(craftItem, reserved, craftingStorage);
                              const maxCount = max === 'infinity' ? Number.MAX_SAFE_INTEGER : max;
                              setCountToCraft((prev) => Math.min(prev + 1, maxCount));
                            }}
                          />
                        </div>
                      </div>

                      <button
                        className="bg-[var(--color-primary)] text-[#1b2d26] flex-1 h-[46px] text-[12px] font-bold tracking-[0.08em] uppercase rounded-md border border-transparent hover:brightness-105 duration-200"
                        style={{
                          pointerEvents: canCraftItem(craftItem, inventory.type, reserved, craftingStorage)
                            ? 'auto'
                            : 'none',
                          opacity: canCraftItem(craftItem, inventory.type, reserved, craftingStorage) ? 1 : 0.5,
                        }}
                        onClick={() => {
                          void fetchNui('craftItem', {
                            fromSlot: craftItem.slot,
                            count: countToCraft,
                            storageId: craftingStorage?.id,
                          }).catch(() => undefined);
                        }}
                      >
                        {(Locale.add_to_queue || 'Add to queue').toUpperCase()}
                      </button>
                    </div>
                  </>
                )}
              </Fade>
            </div>

            <div className="border-b border-neutral-600 my-4"></div>
            <div className="flex items-center justify-between">
              <div className="flex flex-col leading-tight">
                <p className="text-white font-bold text-xl tracking-wide uppercase">{Locale.queue || 'Queue'}</p>
                <p className="text-[#A8A8A8] text-[13px] mt-[1px]">
                  {Locale.items_waiting_to_craft || 'Items waiting to craft'}
                </p>
              </div>
            </div>

            <div className="border-b border-neutral-600 mt-5 mb-4"></div>
            {craftQueue.length === 0 ? (
              <p className="text-neutral-400 text-sm my-1 opacity-75">{Locale.queue_empty || 'The queue is empty.'}</p>
            ) : (
              <div className="mt-3 grid grid-cols-5 gap-2 overflow-y-auto max-h-[200px] w-full content-start pr-1 pb-3">
                {craftQueue.map((craft, index) => {
                  const isActive = index === 0 && !!craft.startedAt;
                  const duration = craft.duration ?? 3000;
                  const started = craft.startedAt ?? now;
                  const progress = isActive ? Math.min((now - started) / duration, 1) : 0;

                  const label = craft.metadata?.label ?? Items[craft.name]?.label ?? craft.name;

                  return (
                    <div
                      key={`crafting-query-${index}`}
                      className="relative w-[90px] h-[90px] border border-transparent item-slot-border filled-slot"
                    >
                      <img
                        src={getItemUrl({ name: craft.name, metadata: craft.metadata } as SlotWithItem)}
                        className="absolute w-[55px] h-[55px] object-contain top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none z-0"
                        alt={craft.name}
                        onError={handleItemImageError}
                      />

                      <p className="absolute text-white top-1 left-2 font-semibold z-10 text-[13px] font-[Inter] w-2/3 truncate">
                        {label}
                      </p>
                      <p className="absolute text-white top-1.5 right-2 z-10 text-xs font-[Inter]">
                        x{craft.craftCount}
                      </p>

                      {isActive && (
                        <div className="absolute bottom-2 left-2 z-10">
                          <CircularProgress progress={progress} />
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
          </AccordionSection>
        </div>
      )}
      {inventory.type === 'shop' && (
        <div
          className={`font-[Inter] w-[530px] bg-black/70 rounded-lg border border-neutral-500 p-5 flex flex-col ${
            !staticPosition ? `absolute top-1/2 ${inv === 'left' ? 'left-[360px]' : 'left-[calc(100%-360px)]'}` : ''
          }`}
          style={{
            order: -1,
            pointerEvents: isBusy ? 'none' : 'auto',
            transform: !staticPosition
              ? `translate(-50%, -50%) perspective(1000px) rotateY(${inv === 'left' ? '12deg' : '-12deg'})`
              : undefined,
          }}
        >
          {/* Store Header Row */}
          <div className="flex items-center justify-between mb-2">
            <div className="flex items-center gap-3">
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
                      style={{
                        fontSize: 24,
                        color: 'var(--ui-accent-foreground)',
                        fontVariationSettings: "'FILL' 1",
                      }}
                    >
                      storefront
                    </span>
                  </div>
                </div>
              </div>
              <div className="flex flex-col leading-tight mt-0.5">
                <p className="text-white font-bold text-xl tracking-wide uppercase">{inventory.label || 'SHOP'}</p>
                <p className="text-[#A8A8A8] text-[13px] mt-[1px]">
                  {Locale.ui_available_items || 'Available items'}
                </p>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-5 content-start pr-1 pb-1 gap-2 mt-4 max-h-[290px] overflow-y-auto">
            {filteredInventoryItems.map((item, index) => {
              const slotWithItem = item as any;
              return (
                <InventorySlot
                  key={`${inventory.type}-${inventory.id}-${item.slot}`}
                  item={item}
                  ref={index === filteredInventoryItems.length - 1 ? ref : null}
                  inventoryType={inventory.type}
                  inventoryGroups={inventory.groups}
                  inventoryId={inventory.id}
                  query={searchQuery || ''}
                  onClick={() => {
                    if (!slotWithItem.name) return;
                    setShoppingCart((prev) => {
                      const existingIndex = prev.findIndex((c) => c.name === slotWithItem.name);
                      if (existingIndex > -1) {
                        const newCart = [...prev];
                        newCart[existingIndex] = {
                          ...newCart[existingIndex],
                          count: (newCart[existingIndex].count || 0) + 1,
                        };
                        return newCart;
                      }
                      return [...prev, { ...slotWithItem, count: 1 }];
                    });
                  }}
                />
              );
            })}
          </div>

          <div className="border-b border-neutral-600 my-4" />

          {/* Cart Header Row */}
          <div className="flex items-center justify-between">
            <div className="flex flex-col leading-tight">
              <p className="text-white font-bold text-xl tracking-wide uppercase">
                {Locale.shopping_cart || 'Shopping Cart'}
              </p>
              <p className="text-[#A8A8A8] text-[13px] mt-[1px]">{Locale.drag_items || 'Drag items here to buy'}</p>
            </div>
          </div>

          <div className="border-b border-neutral-600 mt-5 mb-4"></div>

          <div className="flex flex-col gap-2 max-h-[250px] overflow-y-auto pr-1.5" ref={refs}>
            {shoppingCart.length < 1 && (
              <div className="flex items-center justify-center flex-col h-[100px] text-l text-neutral-400">
                <i className="fa-regular fa-square-plus text-3xl mb-1"></i>
                <p className="font-light uppercase">{Locale.drag_items || 'Drag shop items here'}</p>
              </div>
            )}

            {shoppingCart.length > 0 &&
              shoppingCart.map((item, index) => (
                <div
                  key={`shopping-item-${index}`}
                  className="flex items-center gap-3 rounded-md border border-[rgba(135,135,135,0.18)] bg-[linear-gradient(135deg,rgba(23,23,23,0.45)_0%,rgba(23,23,23,0.08)_100%)] px-2.5 py-2"
                >
                  <img
                    src={item ? getItemUrl(item) : 'none'}
                    alt="item-image"
                    className="w-[36px] h-[36px] object-contain flex-shrink-0"
                    onError={handleItemImageError}
                  />
                  <p className="text-white font-semibold text-[13px] truncate flex-1 min-w-0">
                    {item.metadata?.label ? item.metadata.label : Items[item.name]?.label || item.name}
                  </p>
                  <div className="flex items-center gap-1">
                    <button
                      className="flex h-[22px] w-[22px] items-center justify-center rounded-md border border-[rgba(135,135,135,0.18)] bg-black/25 text-white text-[11px] duration-200 hover:border-[rgba(var(--color-primary-rgb),0.35)] hover:text-[var(--color-primary)]"
                      onClick={() =>
                        setShoppingCart((prev) =>
                          prev.map((shopItem, i) =>
                            i === index ? { ...shopItem, count: Math.max((shopItem.count || 1) - 1, 1) } : shopItem
                          )
                        )
                      }
                      disabled={!Items[item.name]?.stack}
                    >
                      -
                    </button>
                    <span className="text-white text-[12px] font-bold w-[20px] text-center">{item.count || 1}</span>
                    <button
                      className="flex h-[22px] w-[22px] items-center justify-center rounded-md border border-[rgba(135,135,135,0.18)] bg-black/25 text-white text-[11px] duration-200 hover:border-[rgba(var(--color-primary-rgb),0.35)] hover:text-[var(--color-primary)]"
                      disabled={!Items[item.name]?.stack}
                      onClick={() =>
                        setShoppingCart((prev) =>
                          prev.map((shopItem, i) =>
                            i === index ? { ...shopItem, count: (shopItem.count || 1) + 1 } : shopItem
                          )
                        )
                      }
                    >
                      +
                    </button>
                  </div>
                  <p className="text-[#A8A8A8] text-[12px] font-semibold w-[40px] text-right flex-shrink-0">
                    ${(item.count || 1) * (item.price || 0)}
                  </p>
                  <i
                    className="hgi hgi-stroke hgi-delete-02 text-[#555] text-[15px] cursor-pointer duration-200 hover:text-white flex-shrink-0"
                    onClick={() => setShoppingCart((prev) => prev.filter((_, i) => i !== index))}
                  ></i>
                </div>
              ))}
          </div>

          <div className="border-b border-neutral-600 my-4"></div>

          <div className="text-white flex items-center justify-between">
            <p className="text-[15px] font-semibold uppercase tracking-[0.08em] text-white/80">
              {(Locale.total_cost || 'Total Cost').toUpperCase()}
            </p>
            <p className="text-[20px] font-bold text-[var(--color-primary)]">
              ${(animatedTotal || 0).toLocaleString('en-us', { maximumFractionDigits: 0 })}
            </p>
          </div>

          <div className="flex items-center justify-end gap-2 mt-3">
            {(!inventory.accounts || inventory.accounts.length === 0 || inventory.accounts.includes('bank')) && (
              <button
                className="flex h-[36px] items-center gap-1.5 rounded-md border border-[rgba(135,135,135,0.18)] bg-[linear-gradient(135deg,rgba(23,23,23,0.45)_0%,rgba(23,23,23,0.08)_100%)] px-3 text-[12px] font-semibold text-white/80 transition-all hover:border-[rgba(var(--color-primary-rgb),0.35)] hover:bg-[rgba(var(--color-primary-rgb),0.08)] hover:text-white"
                onClick={() => handleBuy('bank')}
              >
                <i className="hgi hgi-stroke hgi-credit-card text-[14px]"></i>
                <p>{Locale.pay_bank || 'Pay Bank'}</p>
              </button>
            )}
            {(!inventory.accounts || inventory.accounts.length === 0 || inventory.accounts.includes('money')) && (
              <button
                className="flex h-[36px] items-center gap-1.5 rounded-md border border-[rgba(135,135,135,0.18)] bg-[linear-gradient(135deg,rgba(23,23,23,0.45)_0%,rgba(23,23,23,0.08)_100%)] px-3 text-[12px] font-semibold text-white/80 transition-all hover:border-[rgba(var(--color-primary-rgb),0.35)] hover:bg-[rgba(var(--color-primary-rgb),0.08)] hover:text-white"
                onClick={() => handleBuy('money')}
              >
                <i className="hgi hgi-stroke hgi-coins-02 text-[14px]"></i>
                <p>{Locale.pay_money || 'Pay Cash'}</p>
              </button>
            )}
            {inventory.accounts?.includes('black_money') && (
              <button
                className="flex h-[36px] items-center gap-1.5 rounded-md border border-[rgba(135,135,135,0.18)] bg-[linear-gradient(135deg,rgba(23,23,23,0.45)_0%,rgba(23,23,23,0.08)_100%)] px-3 text-[12px] font-semibold text-white/80 transition-all hover:border-[rgba(var(--color-primary-rgb),0.35)] hover:bg-[rgba(var(--color-primary-rgb),0.08)] hover:text-white"
                onClick={() => handleBuy('black_money')}
              >
                <i className="hgi hgi-stroke hgi-bitcoin-bag text-[14px]"></i>
                <p>{Locale.pay_black_money || 'Pay Dirty Cash'}</p>
              </button>
            )}
          </div>
        </div>
      )}
    </>
  );
};

export default InventoryGrid;

const AccordionSection: React.FC<{ open: boolean; children: any }> = ({ open, children }) => {
  const contentRef = useRef<HTMLDivElement>(null);
  const [maxHeight, setMaxHeight] = useState(() => (open ? 'auto' : '0px'));

  useEffect(() => {
    const el = contentRef.current;
    if (!el) return;

    const updateHeight = () => {
      if (open) {
        setMaxHeight(`${el.scrollHeight}px`);
        setTimeout(() => setMaxHeight('auto'), 300);
      } else {
        setMaxHeight('0px');
      }
    };

    const timeout = setTimeout(updateHeight, 50);
    return () => clearTimeout(timeout);
  }, [open, children]);

  useEffect(() => {
    const el = contentRef.current;
    if (!el) return;

    const resizeObserver = new ResizeObserver(() => {
      if (open) {
        setMaxHeight('auto');
      }
    });

    resizeObserver.observe(el);
    return () => resizeObserver.disconnect();
  }, [open]);

  return (
    <div
      style={{
        maxHeight,
        opacity: open ? 1 : 0,
        overflow: 'hidden',
        transition: 'all 0.3s',
      }}
    >
      <div ref={contentRef}>{children}</div>
    </div>
  );
};
