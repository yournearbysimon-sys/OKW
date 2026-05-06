import React, { useContext } from 'react';
import { TransitionGroup } from 'react-transition-group';
import useNuiEvent from '../../hooks/useNuiEvent';
import useQueue from '../../hooks/useQueue';
import { Locale } from '../../store/locale';
import { Items } from '../../store/items';
import { getItemUrl, handleItemImageError } from '../../helpers';
import { SlotWithItem } from '../../typings';
import Fade from './transitions/Fade';
import { getRarityChrome } from '../inventory/InventorySlot';

interface ItemNotificationProps {
  item: SlotWithItem;
  action: string;
  count: number;
}

interface ItemNotificationData {
  id: number;
  item: ItemNotificationProps;
  ref: React.RefObject<HTMLDivElement>;
}

export const ItemNotificationsContext = React.createContext<{
  add: (item: ItemNotificationProps) => void;
  notifications: ItemNotificationData[];
} | null>(null);

export const useItemNotifications = () => {
  const itemNotificationsContext = useContext(ItemNotificationsContext);
  if (!itemNotificationsContext) throw new Error(`ItemNotificationsContext undefined`);
  return itemNotificationsContext;
};

const getNotificationSlotStyle = (rarity: string): React.CSSProperties => {
  return getRarityChrome(rarity, {
    neutralBorderColor: 'var(--ui-panel-border-faint)',
    neutralBackground: 'var(--ui-item-shell-gradient-empty)',
    neutralBoxShadow: 'var(--ui-item-shell-inset)',
    shadowAlpha: 0.16,
  });
};

const ItemNotification = React.forwardRef(
  (props: { item: ItemNotificationProps; style?: React.CSSProperties }, ref: React.ForwardedRef<HTMLDivElement>) => {
    const slotItem = props.item.item;
    const actionLabel = Locale[props.item.action] || props.item.action;
    const isRemoved = props.item.action === 'ui_removed';
    const isAdded = props.item.action === 'ui_added';
    const rarity = Items[slotItem.name]?.rarity || 'common';
    const weightLabel =
      slotItem.weight > 0
        ? slotItem.weight >= 1000
          ? `${(slotItem.weight / 1000).toLocaleString('en-us', { minimumFractionDigits: 1 })}kg`
          : `${slotItem.weight.toLocaleString('en-us', { minimumFractionDigits: 0 })}g`
        : '--';

    return (
      <div
        className="relative w-[114px] max-w-[24vw] overflow-hidden rounded-[6px] bg-black/70 px-2 pb-2 pt-5 font-[Inter]"
        ref={ref}
      >
        <div className="flex flex-col items-center text-center">
          <div
            className="relative mb-1.5 h-[74px] w-[74px] border border-transparent item-slot-border filled-slot"
            style={getNotificationSlotStyle(rarity)}
          >
            <div className="pointer-events-none absolute left-1/2 top-[-10px] z-20 -translate-x-1/2">
              <div style={{ filter: 'var(--ui-accent-filter-soft)' }}>
                <div
                  style={{
                    width: 22,
                    height: 22,
                    backgroundColor: 'var(--ui-accent-soft-chip)',
                    borderRadius: 5,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <div
                    style={{
                      width: 18,
                      height: 18,
                      backgroundColor: 'var(--color-primary)',
                      borderRadius: 4,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                    }}
                  >
                    <span className="text-[9px] font-bold leading-none text-[var(--ui-accent-foreground)]">
                      {props.item.count}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <img
              src={`${slotItem?.name ? getItemUrl(slotItem as SlotWithItem) : 'none'}`}
              className="pointer-events-none absolute left-1/2 top-1/2 h-[56px] w-[56px] -translate-x-1/2 -translate-y-1/2 object-contain"
              alt={slotItem.name}
              onError={handleItemImageError}
            />
          </div>

          <div className="w-full px-0.5">
            <p className="mt-0.5 text-[10px] font-semibold leading-none text-white/55">
              {actionLabel} {props.item.count}x
            </p>
            <div className="mt-2 flex items-center justify-between text-[9px] font-bold uppercase tracking-[0.12em] text-white/30">
              <span>{isRemoved ? 'OUT' : isAdded ? 'IN' : 'ITEM'}</span>
              <span>{weightLabel}</span>
            </div>
          </div>
        </div>
      </div>
    );
  }
);

export const ItemNotificationsProvider = ({ children }: { children: React.ReactNode }) => {
  const queue = useQueue<ItemNotificationData>();

  const add = (item: ItemNotificationProps) => {
    const ref = React.createRef<HTMLDivElement>();
    const notification = { id: Date.now(), item, ref: ref };

    queue.add(notification);

    const timeout = setTimeout(() => {
      queue.remove();
      clearTimeout(timeout);
    }, 2500);
  };

  useNuiEvent<[item: SlotWithItem, text: string, count?: number]>('itemNotify', ([item, text, count]) => {
    add({
      item,
      action: text,
      count: Math.max(1, count || 1),
    });
  });

  return (
    <ItemNotificationsContext.Provider value={{ add, notifications: queue.values }}>
      {children}
    </ItemNotificationsContext.Provider>
  );
};

export const ItemNotificationsDisplay: React.FC = () => {
  const { notifications } = useItemNotifications();
  const orderedNotifications = [...notifications].reverse();

  return (
    <TransitionGroup className="pointer-events-none fixed bottom-[0.55%] left-1/2 z-[100000] flex -translate-x-1/2 flex-row items-end gap-1.5">
      {orderedNotifications.map((notification) => (
        <Fade key={`item-notification-${notification.id}`}>
          <ItemNotification item={notification.item} ref={notification.ref} />
        </Fade>
      ))}
    </TransitionGroup>
  );
};
