import React, { useEffect, useMemo, useState } from 'react';
import { useDrop } from 'react-dnd';
import { useAppDispatch, useAppSelector } from '../../store';
import { closeWeaponEditor, selectIsBusy, selectLeftInventory, selectWeaponEditor } from '../../store/inventory';
import { getItemUrl, handleItemImageError, isSlotWithItem } from '../../helpers';
import { Items } from '../../store/items';
import { Locale } from '../../store/locale';
import { fetchNui } from '../../utils/fetchNui';
import { DragSource, SlotWithItem, WeaponEditorSlotConfig } from '../../typings';
import { getBarColor } from '../utils/WeightBar';
import { getRarityChrome } from './InventorySlot';

type WeaponSocketValue = {
  name: string;
  image?: string;
  count?: number;
};

type WeaponSocketProps = {
  config: WeaponEditorSlotConfig;
  weaponSlot: number;
  value?: WeaponSocketValue;
  disabled?: boolean;
  onDropItem: (source: DragSource) => void;
  onClear?: () => void;
};

type WeaponInfoCardProps = {
  label: string;
  value: React.ReactNode;
};

const getSlotStyle = (itemName?: string): React.CSSProperties => {
  if (!itemName) {
    return {
      '--borderColor': 'var(--ui-panel-border-faint)',
    } as React.CSSProperties;
  }

  return getRarityChrome(Items[itemName]?.rarity, {
    neutralBorderColor: 'var(--ui-panel-border-faint)',
    shadowAlpha: 0.16,
  });
};

const WeaponInfoCard: React.FC<WeaponInfoCardProps> = ({ label, value }) => {
  return (
    <div className="min-w-0 py-1">
      <p className="text-[11px] font-semibold uppercase leading-none tracking-[0.12em] text-[#A8A8A8]">{label}</p>
      <p className="mt-2 truncate text-[15px] font-bold leading-none text-white">{value}</p>
    </div>
  );
};

const WeaponSocket: React.FC<WeaponSocketProps> = ({ config, weaponSlot, value, disabled, onDropItem, onClear }) => {
  const [{ isOver, canDrop }, dropRef] = useDrop<DragSource, void, { isOver: boolean; canDrop: boolean }>(
    () => ({
      accept: 'SLOT',
      collect: (monitor) => ({
        isOver: monitor.isOver(),
        canDrop: monitor.canDrop(),
      }),
      canDrop: (source) => {
        if (disabled || source.inventory !== 'player' || source.item.slot === weaponSlot) return false;

        if (config.kind === 'ammo') {
          return source.item.name === config.ammoName;
        }

        return !!config.compatible?.includes(source.item.name);
      },
      drop: (source) => {
        onDropItem(source);
      },
    }),
    [config, disabled, onDropItem, weaponSlot]
  );

  const isFilled = !!value;
  const slotStyle = getSlotStyle(value?.name);

  if (isOver && canDrop) {
    slotStyle.boxShadow =
      'inset 0 0 0 1px rgba(var(--color-primary-rgb), 0.8), 0 0 18px rgba(var(--color-primary-rgb), 0.18)';
    slotStyle.backgroundColor = 'rgba(var(--color-primary-rgb), 0.08)';
  }

  return (
    <div className="flex min-w-0 flex-col items-center gap-1.5">
      <p className="text-center text-[10px] font-semibold uppercase leading-none tracking-[0.18em] text-[#A8A8A8]">
        {config.label}
      </p>
      <button
        ref={dropRef}
        type="button"
        onClick={() => {
          if (isFilled && onClear && !disabled) onClear();
        }}
        className={`relative aspect-square w-full max-w-[90px] border border-transparent item-slot-border ${
          isFilled ? 'filled-slot' : 'empty-slot'
        } ${disabled ? 'cursor-not-allowed opacity-60' : 'cursor-pointer'}`}
        style={slotStyle}
      >
        {isFilled ? (
          <>
            <img
              src={value.image || getItemUrl(value.name)}
              alt={value.name}
              className="absolute w-[55px] h-[55px] object-contain top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none"
              onError={handleItemImageError}
            />
            {typeof value.count === 'number' && value.count > 0 && (
              <div className="absolute bottom-1 right-1.5 text-[11px] font-bold text-white/85 leading-none pointer-events-none drop-shadow-[0_1px_2px_rgba(0,0,0,0.8)]">
                {value.count}
              </div>
            )}
          </>
        ) : (
          <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
            <span
              className="material-symbols-outlined text-[34px]"
              style={{
                color: 'var(--ui-text-primary-35)',
                fontVariationSettings: "'FILL' 0, 'wght' 300, 'GRAD' 0, 'opsz' 48",
              }}
            >
              {config.icon}
            </span>
          </div>
        )}
      </button>
    </div>
  );
};

const WeaponEditorPanel: React.FC = () => {
  const dispatch = useAppDispatch();
  const leftInventory = useAppSelector(selectLeftInventory);
  const weaponEditor = useAppSelector(selectWeaponEditor);
  const isBusy = useAppSelector(selectIsBusy);
  const [pendingKey, setPendingKey] = useState<string | null>(null);

  const weapon = useMemo(() => {
    if (!weaponEditor) return null;

    const slot = leftInventory.items[weaponEditor.slot - 1];
    if (!slot || !isSlotWithItem(slot)) return null;
    if (slot.name !== weaponEditor.itemName) return null;

    return slot as SlotWithItem;
  }, [leftInventory.items, weaponEditor]);

  useEffect(() => {
    if (weaponEditor && !weapon) {
      dispatch(closeWeaponEditor());
    }
  }, [dispatch, weapon, weaponEditor]);

  const getInstalledComponent = (slotConfig: WeaponEditorSlotConfig) => {
    if (!weapon || slotConfig.kind !== 'component') return undefined;

    const components: string[] = Array.isArray(weapon.metadata?.components)
      ? (weapon.metadata?.components as string[])
      : [];

    return components.find((componentName) => Items[componentName]?.componentType === slotConfig.componentType);
  };

  const handleDropItem = async (slotConfig: WeaponEditorSlotConfig, source: DragSource) => {
    if (!weapon || isBusy) return;

    setPendingKey(slotConfig.key);

    try {
      if (slotConfig.kind === 'ammo') {
        await fetchNui<boolean>('weaponEditorAction', {
          action: 'loadAmmo',
          weaponSlot: weapon.slot,
          ammoSlot: source.item.slot,
        });
        return;
      }

      await fetchNui<boolean>('weaponEditorAction', {
        action: 'attachComponent',
        weaponSlot: weapon.slot,
        componentSlot: source.item.slot,
      });
    } finally {
      setPendingKey(null);
    }
  };

  const handleClearSlot = async (slotConfig: WeaponEditorSlotConfig) => {
    if (!weapon || isBusy) return;

    setPendingKey(slotConfig.key);

    try {
      if (slotConfig.kind === 'ammo') {
        await fetchNui<boolean>('removeAmmo', weapon.slot);
        return;
      }

      const installedComponent = getInstalledComponent(slotConfig);
      if (!installedComponent) return;

      await fetchNui<boolean>('weaponEditorAction', {
        action: 'removeComponent',
        weaponSlot: weapon.slot,
        componentName: installedComponent,
      });
    } finally {
      setPendingKey(null);
    }
  };

  if (!weaponEditor || !weapon) return null;

  const weaponRarity = Items[weapon.name]?.rarity;
  const weaponDurability =
    typeof weapon.durability === 'number' ? weapon.durability : Number(weapon.metadata?.durability || 0);
  const weaponSlotStyle = getSlotStyle(weapon.name);

  const sockets = weaponEditor.slots.map((slotConfig) => {
    if (slotConfig.kind === 'ammo') {
      return {
        config: slotConfig,
        value:
          (weapon.metadata?.ammo || 0) > 0
            ? {
                name: slotConfig.ammoName || 'ammo',
                image: slotConfig.ammoName ? getItemUrl(slotConfig.ammoName) : undefined,
                count: Number(weapon.metadata?.ammo || 0),
              }
            : undefined,
      };
    }

    const installedComponent = getInstalledComponent(slotConfig);

    return {
      config: slotConfig,
      value: installedComponent
        ? {
            name: installedComponent,
            image: getItemUrl(installedComponent),
          }
        : undefined,
    };
  });

  return (
    <div className="bg-black/70 rounded-lg border border-neutral-500 w-[530px] p-5">
      <div className="mb-4 flex items-center justify-between">
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
                  style={{ fontSize: 22, color: 'var(--ui-accent-foreground)', fontVariationSettings: "'FILL' 1" }}
                >
                  precision_manufacturing
                </span>
              </div>
            </div>
          </div>

          <div className="min-w-0">
            <p className="text-white font-bold text-xl tracking-wide uppercase">OPEN WEAPON</p>
            <p className="mt-[1px] truncate text-[13px] text-[#A8A8A8]">
              {weapon.metadata?.label || Items[weapon.name]?.label || weapon.name}
            </p>
          </div>
        </div>

        <button
          type="button"
          onClick={() => dispatch(closeWeaponEditor())}
          className="flex h-[34px] w-[34px] items-center justify-center rounded-md border border-white/10 bg-white/5 text-white/80 transition-colors hover:bg-white/10 hover:text-white"
        >
          <span className="material-symbols-outlined text-[18px]">close</span>
        </button>
      </div>

      <div className="flex items-start gap-4">
        <div
          className="relative w-[115px] h-[115px] border border-transparent item-slot-border filled-slot shrink-0"
          style={weaponSlotStyle}
        >
          <img
            src={getItemUrl(weapon)}
            alt={weapon.name}
            className="absolute w-[72px] h-[72px] object-contain top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none"
            onError={handleItemImageError}
          />
          <div className="absolute bottom-0 left-0 z-10 h-1 w-full pointer-events-none bg-black/35">
            <div
              className="h-full"
              style={{
                backgroundColor: getBarColor(weaponDurability, true),
                width: `${Math.max(0, Math.min(100, weaponDurability))}%`,
                transition: 'background 0.3s ease, width 0.3s ease',
              }}
            />
          </div>
        </div>

        <div className="min-w-0 flex-1">
          <div className="grid grid-cols-2 gap-2">
            <WeaponInfoCard label={Locale.ui_durability || 'Durability'} value={Math.floor(weaponDurability)} />
            <WeaponInfoCard label={Locale.ui_ammo || 'Ammo'} value={Number(weapon.metadata?.ammo || 0)} />
            <WeaponInfoCard label={Locale.ui_serial || 'Serial'} value={weapon.metadata?.serial || 'N/A'} />
            <WeaponInfoCard label="Rarity" value={(weaponRarity || 'common').toUpperCase()} />
          </div>
        </div>
      </div>

      <div className="mt-5 h-px w-full bg-white/8" />

      <div className="mt-4 grid grid-cols-5 gap-x-2 gap-y-3">
        {sockets.map(({ config, value }) => (
          <WeaponSocket
            key={config.key}
            config={config}
            weaponSlot={weapon.slot}
            value={value}
            disabled={isBusy || pendingKey === config.key}
            onDropItem={(source) => void handleDropItem(config, source)}
            onClear={value ? () => void handleClearSlot(config) : undefined}
          />
        ))}
      </div>
    </div>
  );
};

export default WeaponEditorPanel;
