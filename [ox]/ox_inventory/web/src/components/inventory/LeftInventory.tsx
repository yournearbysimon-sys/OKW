import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import InventoryGrid from './InventoryGrid';
import { useAppSelector } from '../../store';
import { selectLeftInventory, selectBackpackInventory, selectCraftingStorage } from '../../store/inventory';

type PanelId = 'left' | 'backpack' | 'crafting_storage';

const HOLD_TO_REORDER_MS = 260;
const HOLD_CANCEL_DISTANCE = 10;

const LeftInventory: React.FC<{ searchQuery?: string; category?: string }> = ({ searchQuery, category }) => {
  const leftInventory = useAppSelector(selectLeftInventory);
  const backpackInventory = useAppSelector(selectBackpackInventory);
  const craftingStorage = useAppSelector(selectCraftingStorage);
  const holdTimerRef = useRef<number | null>(null);
  const pointerStateRef = useRef<{ panelId: PanelId; startX: number; startY: number } | null>(null);
  const panelRefs = useRef<Partial<Record<PanelId, HTMLDivElement | null>>>({});

  const panels = useMemo(() => {
    const basePanels: Array<{ id: PanelId; inventory: typeof leftInventory; gridClassName?: string }> = [
      {
        id: 'left',
        inventory: leftInventory,
        gridClassName: backpackInventory ? 'h-[350px]' : undefined,
      },
    ];

    if (backpackInventory) {
      basePanels.push({
        id: 'backpack',
        inventory: backpackInventory,
        gridClassName: 'h-[350px]',
      });
    }

    if (craftingStorage) {
      basePanels.push({
        id: 'crafting_storage',
        inventory: craftingStorage,
        gridClassName: 'h-[350px]',
      });
    }

    return basePanels;
  }, [leftInventory, backpackInventory, craftingStorage]);

  const [panelOrder, setPanelOrder] = useState<PanelId[]>(() => panels.map((panel) => panel.id));
  const [armedPanelId, setArmedPanelId] = useState<PanelId | null>(null);
  const [draggingPanelId, setDraggingPanelId] = useState<PanelId | null>(null);

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
  }, [clearHoldTimer]);

  useEffect(() => {
    const availableIds = panels.map((panel) => panel.id);

    setPanelOrder((currentOrder) => {
      const nextOrder = currentOrder.filter((panelId) => availableIds.includes(panelId));

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
  }, [panels, draggingPanelId, stopReordering]);

  const reorderPanels = useCallback((currentOrder: PanelId[], activePanelId: PanelId, clientY: number) => {
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
    (panelId: PanelId) => (event: React.PointerEvent<HTMLDivElement>) => {
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
        setArmedPanelId(null);
        setDraggingPanelId(panelId);
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
    return panels.reduce((accumulator, panel) => {
      accumulator[panel.id] = panel;
      return accumulator;
    }, {} as Record<PanelId, (typeof panels)[number]>);
  }, [panels]);

  return (
    <div className="flex flex-col gap-4">
      {panelOrder.map((panelId) => {
        const panel = panelsById[panelId];

        if (!panel) return null;

        const panelDragState =
          draggingPanelId === panelId ? 'dragging' : armedPanelId === panelId ? 'arming' : undefined;

        return (
          <div
            key={panelId}
            ref={(node) => {
              panelRefs.current[panelId] = node;
            }}
            className={`rounded-lg transition-all duration-200 ${
              panelDragState === 'dragging'
                ? 'z-10 scale-[0.985] opacity-85'
                : panelDragState === 'arming'
                ? 'ring-1 ring-[rgba(var(--color-primary-rgb),0.28)]'
                : ''
            }`}
          >
            <InventoryGrid
              inventory={panel.inventory}
              inv={panel.id}
              staticPosition
              gridClassName={panel.gridClassName}
              searchQuery={searchQuery}
              category={category}
              panelDragState={panelDragState}
              onPanelHandlePointerDown={handlePanelPointerDown(panelId)}
              onPanelHandlePointerUp={handlePanelPointerRelease}
              onPanelHandlePointerCancel={handlePanelPointerRelease}
            />
          </div>
        );
      })}
    </div>
  );
};

export default LeftInventory;
