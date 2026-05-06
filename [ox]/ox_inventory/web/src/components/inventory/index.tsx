import React, { useEffect, useState } from 'react';
import useNuiEvent from '../../hooks/useNuiEvent';
import InventoryHotbar from './InventoryHotbar';
import PlayerHeader from './PlayerHeader';
import { useAppDispatch, useAppSelector } from '../../store';
import {
  closeWeaponEditor,
  closeWorldGiveDialog,
  refreshSlots,
  selectRightInventory,
  selectWeaponEditor,
  setAdditionalMetadata,
  setupInventory,
} from '../../store/inventory';
import { useExitListener } from '../../hooks/useExitListener';
import type { Inventory as InventoryProps } from '../../typings';
import Tooltip from '../utils/Tooltip';
import { closeTooltip } from '../../store/tooltip';
import InventoryContext from './InventoryContext';
import { closeContextMenu } from '../../store/contextMenu';
import Fade from '../utils/transitions/Fade';
import SlideIn from '../utils/transitions/SlideIn';
import Utilities from './Utilities';
import WorldGiveDialog from './WorldGiveDialog';
import BenchPermissions from '../BenchPermissions/BenchPermissions';
import StashPermissions from '../StashPermissions/StashPermissions';
import { getAvailableItemCategories } from '../../helpers/categories';
import InventoryPanelsStack from './InventoryPanelsStack';
import WeaponEditorPanel from './WeaponEditorPanel';
import InventorySettingsPanel from '../settings/InventorySettingsPanel';
import { useInventorySettings } from '../settings/InventorySettingsContext';

const Inventory: React.FC = () => {
  const { settings, uiMemory, updateUiMemory } = useInventorySettings();
  const [inventoryVisible, setInventoryVisible] = useState(false);
  const [inventorySearch, setInventorySearch] = useState(() => (settings.rememberSearch ? uiMemory.search : ''));
  const [category, setCategory] = useState<string>(() => (settings.rememberCategory ? uiMemory.category : 'All'));
  const [categoryOptions, setCategoryOptions] = useState(() => getAvailableItemCategories());
  const [craftingLeftTab, setCraftingLeftTab] = useState<'utility' | 'permissions'>('utility');
  const [stashLeftTab, setStashLeftTab] = useState<'utility' | 'permissions'>('utility');
  const [settingsVisible, setSettingsVisible] = useState(false);
  const dispatch = useAppDispatch();
  const rightInventory = useAppSelector(selectRightInventory);
  const weaponEditor = useAppSelector(selectWeaponEditor);
  const isInspectView = rightInventory.type === 'otherplayer';
  const isCraftingView = rightInventory.type === 'crafting';
  const isManagedStashView =
    rightInventory.type === 'stash' &&
    typeof rightInventory.id === 'string' &&
    rightInventory.id.startsWith('placed_stash:');
  const canManageBench = !!(
    rightInventory.crafting?.permissions?.canManage ||
    rightInventory.crafting?.permissions?.isOwner ||
    rightInventory.permissions?.canManage ||
    rightInventory.permissions?.isOwner
  );
  const canManageStash =
    isManagedStashView && !!(rightInventory.permissions?.canManage || rightInventory.permissions?.isOwner);
  const safeCategoryOptions = Array.isArray(categoryOptions) ? categoryOptions : [];
  const activeCategory = safeCategoryOptions.some((option) => option.name === category) ? category : 'All';

  useEffect(() => {
    if (!isCraftingView) {
      setCraftingLeftTab('utility');
      return;
    }

    setCraftingLeftTab(settings.autoOpenPermissions && canManageBench ? 'permissions' : 'utility');
  }, [isCraftingView, canManageBench, rightInventory.id, settings.autoOpenPermissions]);

  useEffect(() => {
    if (!isManagedStashView) {
      setStashLeftTab('utility');
      return;
    }

    setStashLeftTab(settings.autoOpenPermissions && canManageStash ? 'permissions' : 'utility');
  }, [isManagedStashView, canManageStash, rightInventory.id, settings.autoOpenPermissions]);

  useNuiEvent<boolean>('setInventoryVisible', setInventoryVisible);
  useNuiEvent<false>('closeInventory', () => {
    setInventoryVisible(false);
    setSettingsVisible(false);
    dispatch(closeContextMenu());
    dispatch(closeTooltip());
    dispatch(closeWorldGiveDialog());
    dispatch(closeWeaponEditor());
  });
  useExitListener(setInventoryVisible);

  useNuiEvent<{
    leftInventory?: InventoryProps;
    rightInventory?: InventoryProps;
  }>('setupInventory', (data) => {
    dispatch(setupInventory(data));
    setCategoryOptions(getAvailableItemCategories());
    !inventoryVisible && setInventoryVisible(true);
  });

  useNuiEvent('refreshSlots', (data) => dispatch(refreshSlots(data)));

  useNuiEvent('displayMetadata', (data: Array<{ metadata: string; value: string }>) => {
    dispatch(setAdditionalMetadata(data));
  });

  useEffect(() => {
    if (inventoryVisible) {
      setCategoryOptions(getAvailableItemCategories());
    }
  }, [inventoryVisible, rightInventory.id]);

  useEffect(() => {
    if (settings.rememberSearch && uiMemory.search !== inventorySearch) {
      updateUiMemory({ search: inventorySearch });
    }
  }, [inventorySearch, settings.rememberSearch, uiMemory.search, updateUiMemory]);

  useEffect(() => {
    if (settings.rememberCategory && uiMemory.category !== category) {
      updateUiMemory({ category });
    }
  }, [category, settings.rememberCategory, uiMemory.category, updateUiMemory]);

  useEffect(() => {
    if (!safeCategoryOptions.some((option) => option.name === category)) {
      setCategory('All');
    }
  }, [safeCategoryOptions, category]);

  useEffect(() => {
    if (!inventoryVisible) {
      dispatch(closeWeaponEditor());
      setSettingsVisible(false);

      if (!settings.rememberSearch) {
        setInventorySearch('');
      }

      if (!settings.rememberCategory) {
        setCategory('All');
      }
    }
  }, [dispatch, inventoryVisible, settings.rememberCategory, settings.rememberSearch]);

  const openSettingsPanel = () => {
    dispatch(closeContextMenu());
    dispatch(closeTooltip());
    dispatch(closeWorldGiveDialog());
    dispatch(closeWeaponEditor());
    setSettingsVisible(true);
  };

  const closeSettingsPanel = () => setSettingsVisible(false);

  const leftPanelTransform = 'translate(-50%, -50%) perspective(1400px) rotateY(12deg)';
  const rightPanelTransform = 'translate(-50%, -50%) perspective(1400px) rotateY(-12deg)';

  return (
    <>
      <Fade in={inventoryVisible}>
        <div style={{ position: 'absolute', inset: 0, zIndex: 1 }}>
          <div
            style={{
              position: 'fixed',
              inset: 0,
              background: 'var(--ui-backdrop-gradient)',
              pointerEvents: 'none',
              zIndex: 0,
            }}
          />

          {settingsVisible ? (
            <div className="absolute inset-0 flex items-center justify-center">
              <div className="absolute inset-0 bg-black/45" />
              <InventorySettingsPanel onClose={closeSettingsPanel} />
            </div>
          ) : (
            <>
              <SlideIn in={inventoryVisible} direction="left" timeout={155}>
                <div className="absolute top-1/2 left-[350px]" style={{ overscrollBehavior: 'contain' }}>
                  <div
                    className={`flex flex-col gap-4 overflow-y-auto no-scrollbar pl-1 pr-2 pb-4 ${
                      isInspectView ? 'max-h-[870px]' : 'max-h-[76vh]'
                    }`}
                    style={{ transform: leftPanelTransform, transformOrigin: 'left center' }}
                  >
                    {isInspectView ? (
                      <InventoryPanelsStack searchQuery={inventorySearch} category={activeCategory} mode="target" />
                    ) : (
                      <>
                        <PlayerHeader />
                        <SlideIn in={inventoryVisible} direction="bottom" timeout={185}>
                          <div className="relative w-[530px]">
                            {(isCraftingView || canManageStash) && (
                              <div className="absolute right-3 top-3 z-20 flex items-center gap-1 rounded-md border border-[rgba(135,135,135,0.18)] bg-black/65 p-1">
                                <button
                                  onClick={() => {
                                    if (isCraftingView) {
                                      setCraftingLeftTab('utility');
                                      return;
                                    }

                                    setStashLeftTab('utility');
                                  }}
                                  className={`flex h-[28px] w-[28px] items-center justify-center rounded text-sm transition-colors ${
                                    (isCraftingView ? craftingLeftTab : stashLeftTab) === 'utility'
                                      ? 'bg-[var(--color-primary)] text-[#131313]'
                                      : 'text-white/70 hover:bg-white/5 hover:text-white'
                                  }`}
                                  title="Loadout"
                                >
                                  <span className="material-symbols-outlined text-[18px]">chevron_left</span>
                                </button>
                                <button
                                  onClick={() => {
                                    if (isCraftingView && !canManageBench) return;
                                    if (!isCraftingView && !canManageStash) return;
                                    dispatch(closeWeaponEditor());

                                    if (isCraftingView) {
                                      setCraftingLeftTab('permissions');
                                      return;
                                    }

                                    setStashLeftTab('permissions');
                                  }}
                                  disabled={isCraftingView ? !canManageBench : !canManageStash}
                                  className={`flex h-[28px] w-[28px] items-center justify-center rounded text-sm transition-colors ${
                                    (isCraftingView ? craftingLeftTab : stashLeftTab) === 'permissions'
                                      ? 'bg-[var(--color-primary)] text-[#131313]'
                                      : 'text-white/70 hover:bg-white/5 hover:text-white'
                                  } ${
                                    (isCraftingView ? !canManageBench : !canManageStash)
                                      ? 'cursor-not-allowed opacity-35 hover:bg-transparent hover:text-white/70'
                                      : ''
                                  }`}
                                  title="Permissions"
                                >
                                  <span className="material-symbols-outlined text-[18px]">chevron_right</span>
                                </button>
                              </div>
                            )}

                            {isCraftingView && craftingLeftTab === 'permissions' ? (
                              <BenchPermissions
                                embedded
                                active
                                benchId={String(rightInventory.crafting?.id || rightInventory.id || '')}
                                initialTab="members"
                                onClose={() => setCraftingLeftTab('utility')}
                              />
                            ) : weaponEditor ? (
                              <WeaponEditorPanel />
                            ) : canManageStash && stashLeftTab === 'permissions' ? (
                              <StashPermissions
                                embedded
                                active
                                stashId={String(rightInventory.id || '')}
                                initialTab="members"
                                onClose={() => setStashLeftTab('utility')}
                              />
                            ) : (
                              <Utilities staticPosition />
                            )}
                          </div>
                        </SlideIn>
                      </>
                    )}

                    {!isInspectView && (
                      <div className="mt-1 flex w-[530px] items-center gap-2 rounded-lg border border-neutral-500 bg-black/70 p-3">
                        <button
                          onClick={openSettingsPanel}
                          className="flex h-[34px] w-[34px] shrink-0 items-center justify-center rounded text-white/55 transition-all duration-200 hover:border-[rgba(135,135,135,0.4)] hover:text-white"
                          style={{
                            background:
                              'linear-gradient(135deg, rgba(23, 23, 23, 0.45) 0%, rgba(23, 23, 23, 0.05) 100%)',
                            border: '1px solid var(--ui-panel-border-strong)',
                          }}
                          title="Settings"
                        >
                          <span className="material-symbols-outlined" style={{ fontSize: '18px' }}>
                            settings
                          </span>
                        </button>

                        <div className="relative flex w-[188px] shrink-0 items-center">
                          <span className="pointer-events-none absolute left-2.5 material-symbols-outlined text-lg text-white/50">
                            search
                          </span>
                          <input
                            type="text"
                            value={inventorySearch}
                            onChange={(e) => setInventorySearch(e.target.value)}
                            className="h-[34px] w-full rounded py-1.5 pl-9 pr-3 text-sm text-white placeholder-white/40 transition-all focus:outline-none hover:border-[rgba(135,135,135,0.4)] focus:border-[rgba(135,135,135,0.6)]"
                            style={{
                              background:
                                'linear-gradient(135deg, rgba(23, 23, 23, 0.45) 0%, rgba(23, 23, 23, 0.05) 100%)',
                              border: '1px solid var(--ui-panel-border-strong)',
                            }}
                            placeholder="Search..."
                          />
                        </div>

                        <div
                          className="flex min-w-0 flex-1 items-center gap-1 overflow-x-auto [&::-webkit-scrollbar]:hidden"
                          style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' }}
                        >
                          {safeCategoryOptions.map((cat) => (
                            <button
                              key={cat.name}
                              onClick={() => setCategory(cat.name)}
                              className={`flex h-[30px] w-[30px] shrink-0 items-center justify-center rounded transition-all duration-200 ${
                                activeCategory === cat.name
                                  ? 'bg-[var(--color-primary)] text-[#131313]'
                                  : 'bg-transparent text-white/50 hover:bg-white/10 hover:text-white'
                              }`}
                              title={cat.name}
                            >
                              <span className="material-symbols-outlined" style={{ fontSize: '18px' }}>
                                {cat.icon}
                              </span>
                            </button>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              </SlideIn>

              <SlideIn in={inventoryVisible} direction="right" timeout={155}>
                <div className="absolute top-1/2 left-[calc(100%-350px)]" style={{ overscrollBehavior: 'contain' }}>
                  <div
                    className="flex max-h-[870px] flex-col gap-4 overflow-y-auto no-scrollbar pr-2 pb-4"
                    style={{ transform: rightPanelTransform, transformOrigin: 'right center' }}
                  >
                    <InventoryPanelsStack
                      searchQuery={inventorySearch}
                      category={activeCategory}
                      mode={isInspectView ? 'owner' : 'all'}
                    />
                  </div>
                </div>
              </SlideIn>

              <Tooltip />
              <InventoryContext />
              <WorldGiveDialog />
            </>
          )}
        </div>
      </Fade>
      <InventoryHotbar />
    </>
  );
};

export default Inventory;
