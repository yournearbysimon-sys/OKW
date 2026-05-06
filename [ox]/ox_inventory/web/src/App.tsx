import InventoryComponent from './components/inventory';
import useNuiEvent from './hooks/useNuiEvent';
import { Items } from './store/items';
import { Locale } from './store/locale';
import { setImagePath } from './store/imagepath';
import { setupInventory, updateCraftingQueue } from './store/inventory';
import { hydrateRarity } from './store/rarity';

import { Inventory } from './typings';
import { PlayerID, useAppDispatch } from './store';
import { debugData } from './utils/debugData';
import DragPreview from './components/utils/DragPreview';
import { fetchNui } from './utils/fetchNui';
import { useDragDropManager } from 'react-dnd';
import KeyPress from './components/utils/KeyPress';
import { ItemNotificationsDisplay } from './components/utils/ItemNotifications';
import { useScale } from './hooks/useScale';

debugData(
  [
    {
      action: 'init',
      data: {
        serverId: 1,
        locale: {
          ui_item_count: 'Amount',
          ui_cancel: 'Cancel',
          ui_confirm: 'Confirm',
          ui_use: 'Use',
          ui_give: 'Give',
          ui_drop: 'Drop',
          ui_weight: 'Weight',
          ui_durability: 'Durability',
          ui_stack: 'Stack',
          ui_useful_controls: 'Useful Controls',
        },
        items: {
          water: { name: 'water', label: 'Water', count: 0, usable: true, close: true, stack: true, weight: 100 },
          burger: { name: 'burger', label: 'Burger', count: 0, usable: true, close: true, stack: true, weight: 100 },
        },
        leftInventory: {
          id: 'player-1',
          type: 'player',
          slots: 50,
          items: [
            { name: 'water', count: 5, slot: 1, weight: 100, metadata: {} },
            { name: 'burger', count: 2, slot: 2, weight: 200, metadata: {} },
          ],
          maxWeight: 100000,
          label: 'Player',
        },
        imagepath: 'images',
      },
    },
    {
      action: 'setupInventory',
      data: {
        leftInventory: {
          id: 'player-1',
          type: 'player',
          slots: 50,
          items: [
            { name: 'water', count: 5, slot: 1, weight: 100, metadata: {} },
            { name: 'burger', count: 2, slot: 2, weight: 200, metadata: {} },
          ],
          maxWeight: 100000,
          label: 'Player',
        },
        rightInventory: {
          id: 'secondary-1',
          type: 'container',
          slots: 10,
          items: [],
          maxWeight: 10000,
          label: 'Container',
        },
      },
    },
  ],
  1000
);

const hexToRgb = (hex: string) => {
  const normalized = hex.trim();
  const short = /^#?([a-f\d])([a-f\d])([a-f\d])$/i.exec(normalized);

  if (short) {
    return `${parseInt(short[1] + short[1], 16)}, ${parseInt(short[2] + short[2], 16)}, ${parseInt(
      short[3] + short[3],
      16
    )}`;
  }

  const long = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})(?:[a-f\d]{2})?$/i.exec(normalized);
  return long ? `${parseInt(long[1], 16)}, ${parseInt(long[2], 16)}, ${parseInt(long[3], 16)}` : null;
};

const applyUiVariables = (ui: Record<string, string | number>) => {
  for (const [key, rawValue] of Object.entries(ui)) {
    if (rawValue === undefined || rawValue === null) continue;

    const value = `${rawValue}`.trim();
    if (!value) continue;

    document.documentElement.style.setProperty(`--${key}`, value);

    if (!key.endsWith('-rgb')) {
      const rgb = hexToRgb(value);
      if (rgb) document.documentElement.style.setProperty(`--${key}-rgb`, rgb);
    }
  }
};

const applyRarityVariables = (rarity?: Record<string, Record<string, string | number>>) => {
  const rarityVariables = hydrateRarity(rarity);

  if (Object.keys(rarityVariables).length > 0) {
    applyUiVariables(rarityVariables);
  }
};

const App: React.FC = () => {
  const scale = useScale();
  const dispatch = useAppDispatch();
  const manager = useDragDropManager();

  useNuiEvent<{
    serverId: number;
    locale: { [key: string]: string };
    items: typeof Items;
    leftInventory: Inventory;
    utility?: import('./typings').UtilityConfig;
    imagepath: string;
    rarity?: Record<string, Record<string, string | number>>;
    ui?: Record<string, string | number>;
  }>('init', ({ serverId, locale, items, leftInventory, imagepath, utility, rarity, ui }) => {
    for (const name in locale) Locale[name] = locale[name];
    for (const name in items) Items[name] = items[name];

    if (ui) applyUiVariables(ui);
    applyRarityVariables(rarity);

    PlayerID[0] = serverId;

    setImagePath(imagepath);
    dispatch(setupInventory({ leftInventory, utility }));
  });

  useNuiEvent('updateCraftingQueue', (data: any[]) => {
    dispatch(updateCraftingQueue(data));
  });

  fetchNui('uiLoaded', {});

  useNuiEvent('closeInventory', () => {
    manager.dispatch({ type: 'dnd-core/END_DRAG' });
  });

  return (
    <>
      <div
        style={{
          width: 1920,
          height: 1080,
          transform: `scale(${scale})`,
          transformOrigin: 'center center',
          position: 'absolute',
          top: '50%',
          left: '50%',
          marginLeft: '-960px',
          marginTop: '-540px',
          zIndex: 2,
        }}
      >
        <InventoryComponent />
        <KeyPress />
        <ItemNotificationsDisplay />
      </div>
      <DragPreview />
    </>
  );
};

addEventListener('dragstart', function (event) {
  event.preventDefault();
});

export default App;
