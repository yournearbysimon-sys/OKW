import React, { useEffect, useState } from 'react';
import {
  ModifierBinding,
  formatKeyboardCode,
  modifierBindingOptions,
  useInventorySettings,
} from './InventorySettingsContext';
import { Locale } from '../../store/locale';

type PanelProps = {
  onClose: () => void;
};

type SettingSectionProps = {
  title: string;
  description?: string;
  children: React.ReactNode;
};

type SettingRowProps = {
  title: string;
  description: string;
  children: React.ReactNode;
};

type ToggleProps = {
  checked: boolean;
  onToggle: () => void;
};

const SettingsSection: React.FC<SettingSectionProps> = ({ title, description, children }) => (
  <div className="rounded-lg border border-[rgba(135,135,135,0.18)] bg-[linear-gradient(135deg,rgba(23,23,23,0.36)_0%,rgba(23,23,23,0.12)_100%)] p-3">
    <div className="mb-3">
      <p className="text-[13px] font-bold uppercase tracking-[0.08em] text-white">{title}</p>
      {description && <p className="mt-1 text-[11px] leading-4 text-[rgba(255,255,255,0.72)]">{description}</p>}
    </div>
    <div className="flex flex-col gap-2.5">{children}</div>
  </div>
);

const SettingsRow: React.FC<SettingRowProps> = ({ title, description, children }) => (
  <div className="flex items-center justify-between gap-3 rounded-md border border-[rgba(135,135,135,0.16)] bg-black/20 px-3 py-2.5">
    <div className="min-w-0 flex-1">
      <p className="text-[13px] font-semibold text-white">{title}</p>
      <p className="mt-0.5 text-[11px] leading-4 text-[rgba(255,255,255,0.78)]">{description}</p>
    </div>
    <div className="shrink-0">{children}</div>
  </div>
);

const ToggleSwitch: React.FC<ToggleProps> = ({ checked, onToggle }) => (
  <button
    type="button"
    onClick={onToggle}
    className={`relative h-[22px] w-[40px] rounded-full transition-colors ${
      checked ? 'bg-[var(--color-primary-dark)]' : 'bg-white/10'
    }`}
  >
    <div
      className={`absolute top-[3px] h-4 w-4 rounded-full bg-white transition-all ${checked ? 'left-5' : 'left-1'}`}
    />
  </button>
);

const ModifierSelector = ({
  value,
  onChange,
}: {
  value: ModifierBinding;
  onChange: (modifier: ModifierBinding) => void;
}) => (
  <div className="flex items-center gap-1 rounded-md border border-[rgba(135,135,135,0.18)] bg-black/30 p-1">
    {modifierBindingOptions.map((option) => (
      <button
        key={option}
        type="button"
        onClick={() => onChange(option)}
        className={`min-w-[70px] rounded-md px-2.5 py-1.5 text-[11px] font-bold uppercase tracking-[0.08em] transition-colors ${
          value === option
            ? 'bg-[var(--color-primary)] text-[#1b2d26]'
            : 'text-[rgba(255,255,255,0.68)] hover:bg-white/5 hover:text-white'
        }`}
      >
        {option === 'Control' ? 'Ctrl' : option}
      </button>
    ))}
  </div>
);

const InventorySettingsPanel: React.FC<PanelProps> = ({ onClose }) => {
  const { settings, updateSetting, resetSettings, resetUiMemory, isCapturingShortcut, setIsCapturingShortcut } =
    useInventorySettings();
  const [capturingKey, setCapturingKey] = useState<keyof Pick<typeof settings, 'closeKey'> | null>(null);
  const t = (key: string, fallback: string) => Locale[key] || fallback;

  useEffect(() => {
    setIsCapturingShortcut(capturingKey !== null);

    return () => {
      setIsCapturingShortcut(false);
    };
  }, [capturingKey, setIsCapturingShortcut]);

  useEffect(() => {
    if (!capturingKey) return;

    const onKeyDown = (event: KeyboardEvent) => {
      event.preventDefault();
      event.stopPropagation();
      updateSetting(capturingKey, event.code);
      setCapturingKey(null);
    };

    window.addEventListener('keydown', onKeyDown, true);

    return () => {
      window.removeEventListener('keydown', onKeyDown, true);
    };
  }, [capturingKey, updateSetting]);

  return (
    <div className="relative z-10 w-[760px] max-w-[92vw]">
      <div className="relative flex h-[560px] max-h-[80vh] flex-col overflow-hidden rounded-lg border border-neutral-500 bg-black/70 p-5 font-[Inter]">
        <div className="mb-2 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div style={{ filter: 'drop-shadow(0 0 6px rgba(var(--color-primary-rgb), 0.35))' }}>
              <div
                style={{
                  width: 44,
                  height: 44,
                  backgroundColor: 'rgba(var(--color-primary-rgb), 0.25)',
                  borderRadius: 5,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  flexShrink: 0,
                }}
              >
                <div
                  style={{
                    width: 36,
                    height: 36,
                    backgroundColor: 'var(--color-primary)',
                    borderRadius: 4,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <span
                    className="material-symbols-outlined"
                    style={{ fontSize: 21, color: 'var(--ui-accent-foreground)', fontVariationSettings: "'FILL' 1" }}
                  >
                    settings
                  </span>
                </div>
              </div>
            </div>

            <div className="mt-0.5 min-w-0 flex-1">
              <p className="text-[19px] font-bold uppercase tracking-[0.05em] text-white">
                {t('inventory_settings_title', 'Inventory Settings')}
              </p>
              <p className="mt-[1px] text-[12px] text-[rgba(255,255,255,0.68)]">
                {isCapturingShortcut
                  ? t('inventory_settings_binding_hint', 'Press any key now to bind it.')
                  : t('inventory_settings_subtitle', 'All settings are saved locally and applied instantly.')}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => {
                resetSettings();
                resetUiMemory();
              }}
              className="h-[36px] rounded-md border border-[rgba(135,135,135,0.18)] bg-[rgba(255,255,255,0.03)] px-4 text-[11px] font-bold uppercase tracking-[0.08em] text-white transition hover:bg-white/5"
            >
              {t('inventory_settings_reset', 'Reset')}
            </button>
            <button
              type="button"
              onClick={onClose}
              className="flex h-[36px] items-center gap-2 rounded-md bg-[var(--color-primary)] px-4 text-[11px] font-bold uppercase tracking-[0.08em] text-[#1b2d26] transition hover:brightness-105"
            >
              <span className="material-symbols-outlined text-[16px]">arrow_back</span>
              {t('inventory_settings_back', 'Back')}
            </button>
          </div>
        </div>

        <div className="mb-3 h-px w-full bg-[rgba(135,135,135,0.14)]" />

        <div className="min-h-0 flex-1 overflow-y-auto pr-1">
          <div className="flex flex-col gap-4">
            <SettingsSection
              title={t('inventory_settings_shortcuts_title', 'Shortcuts')}
              description={t(
                'inventory_settings_shortcuts_desc',
                'Adjust the main inventory shortcuts and click modifiers.'
              )}
            >
              <SettingsRow
                title={t('inventory_settings_quick_move_title', 'Quick Move')}
                description={t(
                  'inventory_settings_quick_move_desc',
                  'Move an item instantly on click without dragging it.'
                )}
              >
                <ModifierSelector
                  value={settings.quickMoveModifier}
                  onChange={(value) => updateSetting('quickMoveModifier', value)}
                />
              </SettingsRow>
              <SettingsRow
                title={t('inventory_settings_use_item_title', 'Use Item')}
                description={t(
                  'inventory_settings_use_item_desc',
                  'Use a player item instantly with the selected modifier.'
                )}
              >
                <ModifierSelector
                  value={settings.useItemModifier}
                  onChange={(value) => updateSetting('useItemModifier', value)}
                />
              </SettingsRow>
              <SettingsRow
                title={t('inventory_settings_split_stack_title', 'Split Stack')}
                description={t(
                  'inventory_settings_split_stack_desc',
                  'Split a stack while moving it by holding the selected modifier.'
                )}
              >
                <ModifierSelector
                  value={settings.splitStackModifier}
                  onChange={(value) => updateSetting('splitStackModifier', value)}
                />
              </SettingsRow>
              <SettingsRow
                title={t('inventory_settings_close_inventory_title', 'Close Inventory')}
                description={t(
                  'inventory_settings_close_inventory_desc',
                  'Key used to close the inventory and this settings page.'
                )}
              >
                <div className="flex items-center gap-2">
                  <div className="min-w-[86px] rounded-md border border-[rgba(135,135,135,0.18)] bg-black/25 px-3 py-2 text-center text-[12px] font-bold uppercase tracking-[0.08em] text-white">
                    {capturingKey === 'closeKey'
                      ? t('inventory_settings_press_short', 'Press...')
                      : formatKeyboardCode(settings.closeKey)}
                  </div>
                  <button
                    type="button"
                    onClick={() => setCapturingKey(capturingKey === 'closeKey' ? null : 'closeKey')}
                    className={`rounded-md px-3 py-2 text-[11px] font-bold uppercase tracking-[0.08em] transition-colors ${
                      capturingKey === 'closeKey'
                        ? 'bg-[var(--color-primary)] text-[#1b2d26]'
                        : 'border border-[rgba(135,135,135,0.18)] bg-black/25 text-white/75 hover:border-[rgba(var(--color-primary-rgb),0.28)] hover:text-[var(--color-primary)]'
                    }`}
                  >
                    {capturingKey === 'closeKey'
                      ? t('inventory_settings_cancel', 'Cancel')
                      : t('inventory_settings_change', 'Change')}
                  </button>
                </div>
              </SettingsRow>
            </SettingsSection>

            <SettingsSection
              title={t('inventory_settings_behavior_title', 'Behavior')}
              description={t(
                'inventory_settings_behavior_desc',
                'Small behavior preferences that affect the inventory flow.'
              )}
            >
              <SettingsRow
                title={t('inventory_settings_remember_search_title', 'Remember Search')}
                description={t(
                  'inventory_settings_remember_search_desc',
                  'Keep the last search text when reopening the inventory.'
                )}
              >
                <ToggleSwitch
                  checked={settings.rememberSearch}
                  onToggle={() => updateSetting('rememberSearch', !settings.rememberSearch)}
                />
              </SettingsRow>
              <SettingsRow
                title={t('inventory_settings_remember_category_title', 'Remember Category')}
                description={t(
                  'inventory_settings_remember_category_desc',
                  'Keep the selected category filter between openings.'
                )}
              >
                <ToggleSwitch
                  checked={settings.rememberCategory}
                  onToggle={() => updateSetting('rememberCategory', !settings.rememberCategory)}
                />
              </SettingsRow>
              <SettingsRow
                title={t('inventory_settings_auto_open_permissions_title', 'Auto Open Permissions')}
                description={t(
                  'inventory_settings_auto_open_permissions_desc',
                  'Open stash and bench permissions automatically when available.'
                )}
              >
                <ToggleSwitch
                  checked={settings.autoOpenPermissions}
                  onToggle={() => updateSetting('autoOpenPermissions', !settings.autoOpenPermissions)}
                />
              </SettingsRow>
              <SettingsRow
                title={t('inventory_settings_drag_sounds_title', 'Drag Sounds')}
                description={t(
                  'inventory_settings_drag_sounds_desc',
                  'Play the inventory drag sound while moving items between slots.'
                )}
              >
                <ToggleSwitch
                  checked={settings.soundEffects}
                  onToggle={() => updateSetting('soundEffects', !settings.soundEffects)}
                />
              </SettingsRow>
            </SettingsSection>
          </div>
        </div>
      </div>
    </div>
  );
};

export default InventorySettingsPanel;
