import { onUse } from '../../dnd/onUse';
import { onGive } from '../../dnd/onGive';
import { onDrop } from '../../dnd/onDrop';
import { Items } from '../../store/items';
import { fetchNui } from '../../utils/fetchNui';
import { Locale } from '../../store/locale';
import { isSlotWithItem, getItemUrl, handleItemImageError } from '../../helpers';
import { setClipboard } from '../../utils/setClipboard';
import { useAppDispatch, useAppSelector } from '../../store';
import React, { useEffect } from 'react';
import { Menu, MenuItem } from '../utils/menu/Menu';
import { InventoryType, SlotWithItem } from '../../typings';
import { openWeaponEditor, selectItemAmount, setItemAmount } from '../../store/inventory';
import { closeContextMenu } from '../../store/contextMenu';

interface DataProps {
  action: string;
  component?: string;
  slot?: number;
  serial?: string;
  id?: number;
}

interface Button {
  label: string;
  index: number;
  group?: string;
}

interface Group {
  groupName: string | null;
  buttons: ButtonWithIndex[];
}

interface ButtonWithIndex extends Button {
  index: number;
}

interface GroupedButtons extends Array<Group> {}

const InventoryContext: React.FC = () => {
  const contextMenu = useAppSelector((state) => state.contextMenu);
  const item = contextMenu.item;
  const inventoryId = contextMenu.inventoryId;
  const inventoryType = contextMenu.inventoryType;
  const [showSplit, setShowSplit] = React.useState<boolean | SlotWithItem>(false);
  const [showGive, setShowGive] = React.useState<boolean | SlotWithItem>(false);
  const dispatch = useAppDispatch();
  const weaponEditorSlots = item?.name ? Items[item.name]?.weaponEditorSlots : undefined;
  const canOpenWeaponEditor =
    !!item &&
    inventoryType === InventoryType.PLAYER &&
    !!Items[item.name]?.weapon &&
    !!weaponEditorSlots &&
    weaponEditorSlots.length > 0;

  const handleClick = (data: DataProps) => {
    if (!item) return;

    switch (data && data.action) {
      case 'use':
        onUse({ name: item.name, slot: item.slot, inventoryId, inventoryType });
        break;
      case 'give':
        setShowGive(showGive === false ? item : false);
        setShowSplit(false);
        break;
      case 'drop':
        isSlotWithItem(item) && onDrop({ item: item, inventory: 'player' });
        break;
      case 'remove':
        fetchNui('removeComponent', { component: data?.component, slot: data?.slot, inventoryId });
        break;
      case 'removeAmmo':
        fetchNui('removeAmmo', { slot: item.slot, inventoryId });
        break;
      case 'copy':
        setClipboard(data.serial || '');
        break;
      case 'split':
        setShowSplit(showSplit === false ? item : false);
        setShowGive(false);
        break;
      case 'custom':
        fetchNui('useButton', { id: (data?.id || 0) + 1, slot: item.slot, inventoryId });
        break;
    }
  };

  const groupButtons = (buttons: any): GroupedButtons => {
    return buttons.reduce((groups: Group[], button: Button, index: number) => {
      if (button.group) {
        const groupIndex = groups.findIndex((group) => group.groupName === button.group);
        if (groupIndex !== -1) {
          groups[groupIndex].buttons.push({ ...button, index });
        } else {
          groups.push({
            groupName: button.group,
            buttons: [{ ...button, index }],
          });
        }
      } else {
        groups.push({
          groupName: null,
          buttons: [{ ...button, index }],
        });
      }
      return groups;
    }, []);
  };

  return (
    <>
      <Menu>
        {item && (
          <div className="flex flex-col mb-1.5 focus:outline-none pointer-events-none">
            <div className="flex items-center gap-3 px-1.5 py-1">
              <div className="w-[50px] h-[50px] bg-[#2a2a2a] rounded-lg flex items-center justify-center shrink-0">
                <img
                  src={getItemUrl(item as SlotWithItem)}
                  alt="icon"
                  className="max-w-[80%] max-h-[80%] object-contain"
                  onError={handleItemImageError}
                />
              </div>
              <div className="flex flex-col">
                <span className="text-white font-bold leading-tight text-sm drop-shadow-md">
                  {item.metadata?.label || Items[item.name]?.label || item.name}
                </span>
                <span
                  className="text-neutral-400 text-[11px] font-medium leading-tight mt-0.5"
                  style={{ textTransform: 'capitalize' }}
                >
                  Item
                </span>
              </div>
            </div>
            <div className="h-[1px] w-full bg-neutral-700/50 mt-2.5 mb-1.5 rounded-full"></div>
          </div>
        )}
        <MenuItem onClick={() => handleClick({ action: 'use' })} label={Locale.ui_use || 'Use'} />
        <MenuItem
          onClick={() => {
            if (showSplit) {
              if (!item) return;
              onDrop({ inventory: InventoryType.PLAYER, item: item }, undefined, true);
              setShowSplit(false);
              dispatch(setItemAmount(0));
            } else {
              handleClick({ action: 'split' });
            }
          }}
          label={showSplit ? Locale.ui_confirm || 'Confirm' : Locale.ui_split || 'Split'}
          closeOnClick={showSplit ? true : false}
        />
        {showSplit && <QuantitySelector item={item as SlotWithItem} />}
        <MenuItem
          onClick={() => {
            if (showGive) {
              if (!item) return;
              onGive({ name: item.name, slot: item.slot, inventoryId, inventoryType });
              setShowGive(false);
              dispatch(setItemAmount(0));
            } else {
              handleClick({ action: 'give' });
            }
          }}
          label={showGive ? Locale.ui_confirm || 'Confirm' : Locale.ui_give || 'Give'}
          closeOnClick={showGive ? true : false}
        />
        {showGive && <QuantitySelector item={item as SlotWithItem} />}
        {item && item.metadata?.ammo > 0 && (
          <MenuItem onClick={() => handleClick({ action: 'removeAmmo' })} label={Locale.ui_remove_ammo} />
        )}
        {item && item.metadata?.serial && (
          <MenuItem
            onClick={() => handleClick({ action: 'copy', serial: item.metadata?.serial })}
            label={Locale.ui_copy || 'Copy'}
          />
        )}
        {canOpenWeaponEditor && (
          <MenuItem
            onClick={() => {
              if (!item || !weaponEditorSlots) return;

              dispatch(
                openWeaponEditor({
                  slot: item.slot,
                  itemName: item.name,
                  inventoryId,
                  inventoryType,
                  slots: weaponEditorSlots,
                })
              );
              dispatch(closeContextMenu());
            }}
            label={(Locale as any).ui_open_weapon || 'Open Weapon'}
          />
        )}
        {item && item.metadata?.components && item.metadata?.components.length > 0 && (
          <Menu label={Locale.ui_removeattachments}>
            {item &&
              item.metadata?.components.map((component: string, index: number) => (
                <MenuItem
                  key={index}
                  onClick={() => handleClick({ action: 'remove', component, slot: item.slot })}
                  label={Items[component]?.label || ''}
                />
              ))}
          </Menu>
        )}
        {((item && item.name && Items[item.name]?.buttons?.length) || 0) > 0 && (
          <>
            {item &&
              item.name &&
              groupButtons(Items[item.name]?.buttons).map((group: Group, index: number) => (
                <React.Fragment key={index}>
                  {group.groupName ? (
                    <Menu label={group.groupName}>
                      {group.buttons.map((button: Button) => (
                        <MenuItem
                          key={button.index}
                          onClick={() => handleClick({ action: 'custom', id: button.index })}
                          label={button.label}
                        />
                      ))}
                    </Menu>
                  ) : (
                    group.buttons.map((button: Button) => (
                      <MenuItem
                        key={button.index}
                        onClick={() => handleClick({ action: 'custom', id: button.index })}
                        label={button.label}
                      />
                    ))
                  )}
                </React.Fragment>
              ))}
          </>
        )}
      </Menu>
    </>
  );
};

export default InventoryContext;

const QuantitySelector: React.FC<{
  item: SlotWithItem;
}> = ({ item }) => {
  const itemAmount = useAppSelector(selectItemAmount);
  const dispatch = useAppDispatch();

  useEffect(() => {
    dispatch(setItemAmount(1));
  }, []);

  const inputHandler = (event: React.ChangeEvent<HTMLInputElement>) => {
    let val = event.target.valueAsNumber;
    if (isNaN(val) || val < 1) val = 1;
    if (val > item.count) val = item.count;
    dispatch(setItemAmount(Math.floor(val)));
  };

  return (
    <div className="flex flex-col gap-1.5 px-0.5 mb-2 w-full">
      <div className="flex justify-between items-center mb-0.5">
        <span className="text-xs font-semibold text-gray-400">{Locale.quantity || 'Amount'}</span>
      </div>
      <div className="w-full bg-[#1a1a1a] border border-white/10 rounded-md text-white font-bold flex items-center px-1 py-1 shadow-sm">
        <input
          type="number"
          min={1}
          max={item.count}
          value={itemAmount}
          onChange={inputHandler}
          className="w-full bg-transparent text-white focus:outline-none placeholder-white/70 text-sm font-semibold selection:bg-[var(--color-primary)] text-center"
          onClick={(e) => e.stopPropagation()}
        />
      </div>
      <div className="mt-2 mb-1.5 flex h-4 items-center px-1">
        <input
          type="range"
          min={1}
          max={item.count}
          value={itemAmount}
          onChange={inputHandler}
          className="world-give-slider"
          onClick={(e) => e.stopPropagation()}
        />
      </div>
    </div>
  );
};
