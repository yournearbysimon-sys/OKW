import React from 'react';
import InventoryGrid from './InventoryGrid';
import Utilities from './Utilities';
import { useAppSelector } from '../../store';
import { selectRightInventory, selectBackpackInventory } from '../../store/inventory';
import { Locale } from '../../store/locale';

const RightInventory: React.FC<{ searchQuery?: string; category?: string }> = ({ searchQuery, category }) => {
  const rightInventory = useAppSelector(selectRightInventory);
  const backpackInventory = useAppSelector(selectBackpackInventory);

  if (rightInventory.type === 'otherplayer') {
    return (
      <div className="flex flex-col gap-2">
        {/* Main Inventory - Filter out first 10 items (Utility Slots) */}
        <div>
          <InventoryGrid
            inventory={rightInventory}
            inv={'right'}
            staticPosition
            offset={10}
            gridClassName="h-auto max-h-[300px]"
            searchQuery={searchQuery}
            category={category}
          />
        </div>

        {/* Backpack Inventory (if available) */}
        {backpackInventory && (
          <div>
            <InventoryGrid
              inventory={backpackInventory}
              inv={'right'}
              staticPosition
              gridClassName="h-auto max-h-[300px]"
              searchQuery={searchQuery}
              category={category}
            />
          </div>
        )}

        {/* Utility Slots (Visual Body Representation) */}
        <div>
          <InventoryGrid
            inventory={rightInventory}
            inv={'right'}
            staticPosition
            limit={10}
            customTitle={Locale.ui_utility_slots || 'Utility Slots'}
            gridClassName="h-auto max-h-[160px]"
            searchQuery={searchQuery}
            category={category}
          />
        </div>
      </div>
    );
  }

  return (
    <InventoryGrid
      inventory={rightInventory}
      inv={'right'}
      staticPosition
      searchQuery={searchQuery}
      category={category}
    />
  );
};

export default RightInventory;
