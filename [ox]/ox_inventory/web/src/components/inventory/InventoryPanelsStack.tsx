import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import { PlayerID, useAppSelector } from '../../store';
import { getTotalWeight } from '../../helpers';
import { Inventory } from '../../typings';
import {
  selectBackpackInventory,
  selectCraftingStorage,
  selectLeftInventory,
  selectRightInventory,
  selectTargetBackpackInventory,
  selectUtility,
} from '../../store/inventory';
import { Locale } from '../../store/locale';
import InventoryGrid from './InventoryGrid';
import CompactUtilityPanel from './CompactUtilityPanel';
import { fetchNui } from '../../utils/fetchNui';
import WeightSummary from './WeightSummary';

type PanelDragState = 'arming' | 'dragging';
const BACKPACK_PANEL_GRACE_MS = 180;

type PanelConfig = {
  id: string;
  inv: string;
  inventory: Inventory;
  kind?: 'grid' | 'utilities';
  gridClassName?: string;
  offset?: number;
  limit?: number;
  customTitle?: string;
  customSubtitle?: string;
  title: string;
  subtitle: string;
  icon: string;
  weightText?: string;
  weight?: number;
  maxWeight?: number;
  xpText?: string;
};

const HOLD_TO_REORDER_MS = 260;
const HOLD_CANCEL_DISTANCE = 10;
const getInventoryTitle = (inventory: Inventory, customTitle?: string) => {
  if (customTitle) return customTitle;
  if (inventory.type === 'player') return Locale.ui_pockets || 'POCKETS';
  if (inventory.type === 'otherplayer') return inventory.label || (Locale.ui_player || 'PLAYER');
  return inventory.label || (Locale.ui_inventory || 'INVENTORY');
};

const getInventorySubtitle = (inventory: Inventory, customSubtitle?: string) => {
  if (customSubtitle) return customSubtitle;
  if (inventory.type === 'player') return Locale.ui_items_on_character || 'Items on your character';
  if (inventory.type === 'otherplayer') {
    return `[${inventory.id}] ${inventory.label || (Locale.ui_player_inventory || 'Player Inventory')}`;
  }
  return `[${PlayerID[0]}] ${inventory.label || (Locale.ui_inventory || 'Inventory')}`;
};

const getInventoryIcon = (inventory: Inventory) => {
  if (inventory.type === 'crafting') return 'construction';
  if (inventory.type === 'shop') return 'storefront';
  if (inventory.type === 'player') return 'dns';
  return 'inventory_2';
};

const buildPanelConfig = (
  id: string,
  inv: string,
  inventory: Inventory,
  options?: Pick<PanelConfig, 'kind' | 'gridClassName' | 'offset' | 'limit' | 'customTitle' | 'customSubtitle'>
): PanelConfig => {
  const weight = inventory.maxWeight !== undefined ? Math.floor(getTotalWeight(inventory.items) * 1000) / 1000 : 0;
  return {
    id,
    inv,
    inventory,
    kind: options?.kind || 'grid',
    ...options,
    title: getInventoryTitle(inventory, options?.customTitle),
    subtitle: getInventorySubtitle(inventory, options?.customSubtitle),
    icon: getInventoryIcon(inventory),
    weightText: inventory.maxWeight
      ? `${Number(weight / 1000).toFixed(1)} / ${Number(inventory.maxWeight / 1000).toFixed(1)} kg`
      : undefined,
    weight,
    maxWeight: inventory.maxWeight,
    xpText:
      inventory.type === 'crafting' && inventory.crafting?.xp?.enabled
        ? `${inventory.crafting.xp.current} XP`
        : undefined,
  };
};

const InventoryPanelsStack: React.FC<{
  searchQuery?: string;
  category?: string;
  mode?: 'all' | 'owner' | 'target';
}> = ({ searchQuery, category, mode = 'all' }) => {
  const [craftingViewMode, setCraftingViewMode] = useState<'crafting' | 'inventory'>('crafting');
  const leftInventory = useAppSelector(selectLeftInventory);
  const rightInventory = useAppSelector(selectRightInventory);
  const ownerBackpackInventory = useAppSelector(selectBackpackInventory);
  const targetBackpackInventory = useAppSelector(selectTargetBackpackInventory);
  const craftingStorage = useAppSelector(selectCraftingStorage);
  const utility = useAppSelector(selectUtility);
  const holdTimerRef = useRef<number | null>(null);
  const ownerBackpackClearTimerRef = useRef<number | null>(null);
  const targetBackpackClearTimerRef = useRef<number | null>(null);
  const pointerStateRef = useRef<{ panelId: string; startX: number; startY: number } | null>(null);
  const panelRefs = useRef<Record<string, HTMLDivElement | null>>({});
  const [stickyOwnerBackpackInventory, setStickyOwnerBackpackInventory] = useState<Inventory | undefined>(
    ownerBackpackInventory
  );
  const [stickyTargetBackpackInventory, setStickyTargetBackpackInventory] = useState<Inventory | undefined>(
    targetBackpackInventory
  );

  const backpackSlotId = useMemo(() => {
    if (!utility?.items || !utility?.backpackItems) return 6;

    for (const [slot, items] of Object.entries(utility.items)) {
      if (Array.isArray(items) && items.some((itemName) => utility.backpackItems?.[itemName])) {
        return Array.isArray(utility.items) ? Number(slot) + 1 : Number(slot);
      }
    }

    return 6;
  }, [utility]);

  const ownerBackpackSlot = leftInventory.items?.[backpackSlotId - 1];
  const targetBackpackSlot =
    rightInventory.type === 'otherplayer' ? rightInventory.items?.[backpackSlotId - 1] : undefined;
  const ownerHasEquippedBackpack = !!(ownerBackpackSlot?.name && utility?.backpackItems?.[ownerBackpackSlot.name]);
  const targetHasEquippedBackpack = !!(targetBackpackSlot?.name && utility?.backpackItems?.[targetBackpackSlot.name]);

  const clearOwnerBackpackClearTimer = useCallback(() => {
    if (ownerBackpackClearTimerRef.current !== null) {
      window.clearTimeout(ownerBackpackClearTimerRef.current);
      ownerBackpackClearTimerRef.current = null;
    }
  }, []);

  const clearTargetBackpackClearTimer = useCallback(() => {
    if (targetBackpackClearTimerRef.current !== null) {
      window.clearTimeout(targetBackpackClearTimerRef.current);
      targetBackpackClearTimerRef.current = null;
    }
  }, []);

  useEffect(() => {
    clearOwnerBackpackClearTimer();

    if (ownerBackpackInventory) {
      setStickyOwnerBackpackInventory(ownerBackpackInventory);
      return;
    }

    if (!ownerHasEquippedBackpack) {
      ownerBackpackClearTimerRef.current = window.setTimeout(() => {
        setStickyOwnerBackpackInventory(undefined);
        ownerBackpackClearTimerRef.current = null;
      }, BACKPACK_PANEL_GRACE_MS);
    }

    return clearOwnerBackpackClearTimer;
  }, [ownerBackpackInventory, ownerHasEquippedBackpack, clearOwnerBackpackClearTimer]);

  useEffect(() => {
    clearTargetBackpackClearTimer();

    if (targetBackpackInventory) {
      setStickyTargetBackpackInventory(targetBackpackInventory);
      return;
    }

    if (!targetHasEquippedBackpack || rightInventory.type !== 'otherplayer') {
      targetBackpackClearTimerRef.current = window.setTimeout(() => {
        setStickyTargetBackpackInventory(undefined);
        targetBackpackClearTimerRef.current = null;
      }, BACKPACK_PANEL_GRACE_MS);
    }

    return clearTargetBackpackClearTimer;
  }, [targetBackpackInventory, targetHasEquippedBackpack, rightInventory.type, clearTargetBackpackClearTimer]);

  useEffect(() => {
    return () => {
      clearOwnerBackpackClearTimer();
      clearTargetBackpackClearTimer();
    };
  }, [clearOwnerBackpackClearTimer, clearTargetBackpackClearTimer]);

  const displayOwnerBackpackInventory = ownerBackpackInventory || stickyOwnerBackpackInventory;
  const displayTargetBackpackInventory =
    rightInventory.type === 'otherplayer' ? targetBackpackInventory || stickyTargetBackpackInventory : undefined;

  const openCraftTree = useCallback(() => {
    if (rightInventory.type !== 'crafting') return;

    fetchNui('craftTree:open', {
      benchId: rightInventory.id,
      benchIndex: (rightInventory as any).index,
    }).catch(() => undefined);
  }, [rightInventory]);

  const stackedPanels = useMemo(() => {
    const showLeftBackpackPanel = !!displayOwnerBackpackInventory;
    const leftPanels: PanelConfig[] = [
      buildPanelConfig('left', 'left', leftInventory, {
        gridClassName: showLeftBackpackPanel ? 'h-[300px]' : 'h-[310px]',
      }),
    ];

    if (showLeftBackpackPanel) {
      leftPanels.push(
        buildPanelConfig('backpack', 'backpack', displayOwnerBackpackInventory!, {
          gridClassName: 'h-[300px]',
        })
      );
    }

    if (craftingStorage) {
      leftPanels.push(
        buildPanelConfig('crafting_storage', 'crafting_storage', craftingStorage, {
          gridClassName: 'h-[300px]',
        })
      );
    }

    const rightPanels: PanelConfig[] = [];

    if (rightInventory.type === 'otherplayer') {
      rightPanels.push(
        buildPanelConfig('right_main', 'right', rightInventory, {
          gridClassName: 'h-auto max-h-[300px]',
        })
      );

      if (displayTargetBackpackInventory) {
        rightPanels.push(
          buildPanelConfig('right_backpack', 'right_backpack', displayTargetBackpackInventory, {
            customTitle: `${rightInventory.label || (Locale.ui_player || 'Player')} - ${
              displayTargetBackpackInventory.label || (Locale.backpack || 'Backpack')
            }`,
            customSubtitle: `[${rightInventory.id}] ${
              displayTargetBackpackInventory.label || (Locale.backpack || 'Backpack')
            }`,
            gridClassName: 'h-auto max-h-[300px]',
          })
        );
      }

      rightPanels.push(
        buildPanelConfig('right_utility', 'right_utility', rightInventory, {
          kind: 'utilities',
          customTitle: Locale.ui_utility_slots || 'Utility Slots',
        })
      );
    } else if (rightInventory.type) {
      rightPanels.push(
        buildPanelConfig('right', 'right', rightInventory, {
          gridClassName: 'h-[310px]',
        })
      );
    }

    if (mode === 'owner') {
      return [...leftPanels];
    }

    if (mode === 'target') {
      return [...rightPanels];
    }

    if (rightInventory.type === 'crafting') {
      return craftingViewMode === 'crafting' ? [...rightPanels] : [...leftPanels];
    }

    if (rightInventory.type === 'shop') {
      return [...rightPanels];
    }

    return [...leftPanels, ...rightPanels];
  }, [
    leftInventory,
    rightInventory,
    displayOwnerBackpackInventory,
    displayTargetBackpackInventory,
    craftingStorage,
    craftingViewMode,
    mode,
  ]);

  const [panelOrder, setPanelOrder] = useState<string[]>(() => stackedPanels.map((panel) => panel.id));
  const [armedPanelId, setArmedPanelId] = useState<string | null>(null);
  const [draggingPanelId, setDraggingPanelId] = useState<string | null>(null);
  const [dragPointer, setDragPointer] = useState<{ x: number; y: number } | null>(null);
  const [dragPreview, setDragPreview] = useState<{ width: number; offsetX: number; offsetY: number } | null>(null);

  const clearHoldTimer = useCallback(() => {
    if (holdTimerRef.current) {
      window.clearTimeout(holdTimerRef.current);
      holdTimerRef.current = null;
    }
  }, []);

  const stopReordering = useCallback(() => {
    clearHoldTimer();
    pointerStateRef.current = null;
    setArmedPanelId(null);
    setDraggingPanelId(null);
    setDragPointer(null);
    setDragPreview(null);
  }, [clearHoldTimer]);

  useEffect(() => {
    const availableIds = stackedPanels.map((panel) => panel.id);

    setPanelOrder((currentOrder) => {
      const nextOrder = [...currentOrder];

      availableIds.forEach((panelId) => {
        if (!nextOrder.includes(panelId)) {
          nextOrder.push(panelId);
        }
      });

      if (
        nextOrder.length === currentOrder.length &&
        nextOrder.every((panelId, index) => panelId === currentOrder[index])
      ) {
        return currentOrder;
      }

      return nextOrder;
    });

    if (draggingPanelId && !availableIds.includes(draggingPanelId)) {
      stopReordering();
    }
  }, [stackedPanels, draggingPanelId, stopReordering]);

  const reorderPanels = useCallback((currentOrder: string[], activePanelId: string, clientY: number) => {
    const remainingPanels = currentOrder.filter((panelId) => panelId !== activePanelId);
    let targetIndex = remainingPanels.length;

    for (let index = 0; index < remainingPanels.length; index++) {
      const panelRect = panelRefs.current[remainingPanels[index]]?.getBoundingClientRect();

      if (!panelRect) continue;

      if (clientY < panelRect.top + panelRect.height / 2) {
        targetIndex = index;
        break;
      }
    }

    const nextOrder = [...remainingPanels];
    nextOrder.splice(targetIndex, 0, activePanelId);

    if (nextOrder.every((panelId, index) => panelId === currentOrder[index])) {
      return currentOrder;
    }

    return nextOrder;
  }, []);

  useEffect(() => {
    if (!armedPanelId && !draggingPanelId) return;

    const handlePointerMove = (event: PointerEvent) => {
      const pointerState = pointerStateRef.current;

      if (!pointerState) return;

      if (!draggingPanelId) {
        const movedDistance = Math.hypot(event.clientX - pointerState.startX, event.clientY - pointerState.startY);

        if (movedDistance > HOLD_CANCEL_DISTANCE) {
          stopReordering();
        }

        return;
      }

      setDragPointer({ x: event.clientX, y: event.clientY });
      setPanelOrder((currentOrder) => reorderPanels(currentOrder, draggingPanelId, event.clientY));
    };

    const handlePointerUp = () => stopReordering();

    window.addEventListener('pointermove', handlePointerMove);
    window.addEventListener('pointerup', handlePointerUp);
    window.addEventListener('pointercancel', handlePointerUp);

    return () => {
      window.removeEventListener('pointermove', handlePointerMove);
      window.removeEventListener('pointerup', handlePointerUp);
      window.removeEventListener('pointercancel', handlePointerUp);
    };
  }, [armedPanelId, draggingPanelId, reorderPanels, stopReordering]);

  useEffect(() => {
    return () => clearHoldTimer();
  }, [clearHoldTimer]);

  const handlePanelPointerDown = useCallback(
    (panelId: string) => (event: React.PointerEvent<HTMLDivElement>) => {
      if (event.button !== 0) return;

      event.preventDefault();
      clearHoldTimer();
      pointerStateRef.current = {
        panelId,
        startX: event.clientX,
        startY: event.clientY,
      };
      setArmedPanelId(panelId);

      holdTimerRef.current = window.setTimeout(() => {
        const panelElement = panelRefs.current[panelId];
        const rect = panelElement?.getBoundingClientRect();

        setArmedPanelId(null);
        setDraggingPanelId(panelId);
        setDragPointer({ x: event.clientX, y: event.clientY });
        setDragPreview({
          width: rect?.width ?? 530,
          offsetX: rect ? event.clientX - rect.left : 28,
          offsetY: rect ? Math.min(event.clientY - rect.top, 42) : 24,
        });
      }, HOLD_TO_REORDER_MS);
    },
    [clearHoldTimer]
  );

  const handlePanelPointerRelease = useCallback(() => {
    if (!draggingPanelId) {
      clearHoldTimer();
      pointerStateRef.current = null;
      setArmedPanelId(null);
    }
  }, [clearHoldTimer, draggingPanelId]);

  const panelsById = useMemo(() => {
    return stackedPanels.reduce((accumulator, panel) => {
      accumulator[panel.id] = panel;
      return accumulator;
    }, {} as Record<string, PanelConfig>);
  }, [stackedPanels]);

  const draggingPanel = draggingPanelId ? panelsById[draggingPanelId] : null;

  return (
    <div className="flex flex-col relative w-[530px]">
      {rightInventory.type === 'crafting' && (
        <div className="flex justify-end mb-2 z-20">
          <div className="flex items-center gap-1 rounded border border-[rgba(135,135,135,0.18)] bg-black/65 p-1">
            <button
              onClick={() => setCraftingViewMode('crafting')}
              className={`flex h-[28px] w-[28px] items-center justify-center rounded text-sm transition-colors ${
                craftingViewMode === 'crafting'
                  ? 'bg-[var(--color-primary)] text-[#131313]'
                  : 'text-white/70 hover:bg-white/5 hover:text-white'
              }`}
              title="Crafting"
            >
              <span className="material-symbols-outlined text-[18px]">chevron_left</span>
            </button>
            <button
              onClick={() => setCraftingViewMode('inventory')}
              className={`flex h-[28px] w-[28px] items-center justify-center rounded text-sm transition-colors ${
                craftingViewMode === 'inventory'
                  ? 'bg-[var(--color-primary)] text-[#131313]'
                  : 'text-white/70 hover:bg-white/5 hover:text-white'
              }`}
              title="Inventory"
            >
              <span className="material-symbols-outlined text-[18px]">chevron_right</span>
            </button>
            <button
              onClick={openCraftTree}
              className="flex h-[28px] w-[28px] items-center justify-center rounded text-sm text-white/70 transition-colors hover:bg-white/5 hover:text-white"
              title="Blueprint Tree"
            >
              <span className="material-symbols-outlined text-[18px]">account_tree</span>
            </button>
          </div>
        </div>
      )}
      <div className="flex flex-col gap-4">
        {panelOrder.map((panelId, index) => {
          const panel = panelsById[panelId];

          if (!panel) return null;

          const defaultClosed =
            panel.id === 'right' &&
            panel.inventory.type !== 'player' &&
            panel.inventory.type !== 'otherplayer' &&
            !panel.inventory.label;
          const panelDragState: PanelDragState | undefined =
            draggingPanelId === panelId ? 'dragging' : armedPanelId === panelId ? 'arming' : undefined;

          return (
            <div
              key={panel.id}
              ref={(node) => {
                panelRefs.current[panel.id] = node;
              }}
              className={`rounded-lg transition-all duration-200 ${
                panelDragState === 'dragging'
                  ? 'pointer-events-none opacity-20 scale-[0.985]'
                  : panelDragState === 'arming'
                  ? 'ring-1 ring-[rgba(var(--color-primary-rgb),0.28)]'
                  : ''
              }`}
            >
              {panel.kind === 'utilities' ? (
                <CompactUtilityPanel
                  inventory={panel.inventory}
                  title={panel.customTitle}
                  subtitle={panel.customSubtitle}
                  panelDragState={panelDragState}
                  onPanelHandlePointerDown={handlePanelPointerDown(panel.id)}
                  onPanelHandlePointerUp={handlePanelPointerRelease}
                  onPanelHandlePointerCancel={handlePanelPointerRelease}
                />
              ) : (
                <InventoryGrid
                  inventory={panel.inventory}
                  inv={panel.inv}
                  staticPosition
                  defaultClosed={defaultClosed}
                  gridClassName={panel.gridClassName}
                  offset={panel.offset}
                  limit={panel.limit}
                  customTitle={panel.customTitle}
                  customSubtitle={panel.customSubtitle}
                  searchQuery={searchQuery}
                  category={category}
                  panelDragState={panelDragState}
                  onPanelHandlePointerDown={handlePanelPointerDown(panel.id)}
                  onPanelHandlePointerUp={handlePanelPointerRelease}
                  onPanelHandlePointerCancel={handlePanelPointerRelease}
                />
              )}
            </div>
          );
        })}
      </div>
      {/* Spacer to prevent cut-off in the scrolling parent */}
      <div className="h-6 shrink-0" />

      {draggingPanel &&
        dragPointer &&
        dragPreview &&
        createPortal(
          <div
            className="pointer-events-none fixed z-[90]"
            style={{
              left: dragPointer.x - dragPreview.offsetX,
              top: dragPointer.y - dragPreview.offsetY,
              width: dragPreview.width,
            }}
          >
            <PanelDragPreview panel={draggingPanel} />
          </div>,
          document.body
        )}
    </div>
  );
};

const PanelDragPreview: React.FC<{ panel: PanelConfig }> = ({ panel }) => {
  return (
    <div className="rounded-lg border border-neutral-500 bg-black/70 p-5">
      <div className="mb-2 flex items-center justify-between">
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
                  {panel.icon}
                </span>
              </div>
            </div>
          </div>
          <div className="mt-0.5 flex flex-col leading-tight">
            <p className="text-xl font-bold uppercase tracking-wide text-white">{panel.title}</p>
            <p className="mt-[1px] text-[13px] text-[#A8A8A8]">{panel.subtitle}</p>
          </div>
        </div>
        {panel.inventory.type !== 'shop' && (
          <div className="flex flex-col items-end gap-1">
            {panel.inventory.type === 'crafting' ? (
              <div className="flex items-center gap-2">
                {panel.xpText && (
                  <div className="flex items-center gap-1.5 whitespace-nowrap font-bold text-[15px] leading-none text-white">
                    <i className="fa-solid fa-star text-[14px] text-yellow-500"></i>
                    <span>{panel.xpText}</span>
                  </div>
                )}
                <span className="material-symbols-outlined flex-shrink-0 text-white" style={{ fontSize: '20px' }}>
                  keyboard_arrow_up
                </span>
              </div>
            ) : (
              <>
                {panel.weightText && (
                  <div className="flex items-center text-white">
                    <WeightSummary weight={panel.weight || 0} maxWeight={panel.maxWeight} />
                    <span
                      className="material-symbols-outlined ml-2 flex-shrink-0 text-white"
                      style={{ fontSize: '20px' }}
                    >
                      keyboard_arrow_up
                    </span>
                  </div>
                )}
              </>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default InventoryPanelsStack;
