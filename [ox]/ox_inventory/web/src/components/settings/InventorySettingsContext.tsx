import React, { createContext, useContext, useEffect, useMemo, useState } from 'react';

export type ModifierBinding = 'Control' | 'Alt' | 'Shift';

export type InventorySettings = {
  quickMoveModifier: ModifierBinding;
  useItemModifier: ModifierBinding;
  splitStackModifier: ModifierBinding;
  closeKey: string;
  rememberSearch: boolean;
  rememberCategory: boolean;
  autoOpenPermissions: boolean;
  soundEffects: boolean;
};

export type InventoryUiMemory = {
  search: string;
  category: string;
};

type InventorySettingsContextValue = {
  settings: InventorySettings;
  updateSetting: <K extends keyof InventorySettings>(key: K, value: InventorySettings[K]) => void;
  resetSettings: () => void;
  uiMemory: InventoryUiMemory;
  updateUiMemory: (patch: Partial<InventoryUiMemory>) => void;
  resetUiMemory: () => void;
  isCapturingShortcut: boolean;
  setIsCapturingShortcut: React.Dispatch<React.SetStateAction<boolean>>;
};

const SETTINGS_STORAGE_KEY = 'ox_inventory_settings_v3';
const UI_MEMORY_STORAGE_KEY = 'ox_inventory_ui_memory_v1';

export const defaultInventorySettings: InventorySettings = {
  quickMoveModifier: 'Control',
  useItemModifier: 'Alt',
  splitStackModifier: 'Shift',
  closeKey: 'Escape',
  rememberSearch: true,
  rememberCategory: true,
  autoOpenPermissions: true,
  soundEffects: true,
};

const defaultUiMemory: InventoryUiMemory = {
  search: '',
  category: 'All',
};

const InventorySettingsContext = createContext<InventorySettingsContextValue | null>(null);

export const modifierBindingOptions: ModifierBinding[] = ['Control', 'Alt', 'Shift'];
const modifierSettingKeys = ['quickMoveModifier', 'useItemModifier', 'splitStackModifier'] as const;

type ModifierSettingKey = (typeof modifierSettingKeys)[number];

const canUseDomStorage = () => typeof window !== 'undefined' && typeof window.localStorage !== 'undefined';

const isModifierSettingKey = (key: keyof InventorySettings): key is ModifierSettingKey =>
  modifierSettingKeys.includes(key as ModifierSettingKey);

const ensureUniqueModifierBindings = (
  bindings: Pick<InventorySettings, ModifierSettingKey>
): Pick<InventorySettings, ModifierSettingKey> => {
  const nextBindings = { ...bindings };
  const usedBindings = new Set<ModifierBinding>();

  modifierSettingKeys.forEach((key) => {
    const currentBinding = nextBindings[key];

    if (!usedBindings.has(currentBinding)) {
      usedBindings.add(currentBinding);
      return;
    }

    const fallbackBinding =
      modifierBindingOptions.find((option) => !usedBindings.has(option)) || defaultInventorySettings[key];
    nextBindings[key] = fallbackBinding;
    usedBindings.add(fallbackBinding);
  });

  return nextBindings;
};

const swapModifierBinding = (
  currentSettings: InventorySettings,
  key: ModifierSettingKey,
  value: ModifierBinding
): InventorySettings => {
  if (currentSettings[key] === value) return currentSettings;

  const nextSettings = { ...currentSettings, [key]: value };
  const duplicateKey = modifierSettingKeys.find(
    (modifierKey) => modifierKey !== key && currentSettings[modifierKey] === value
  );

  if (duplicateKey) {
    nextSettings[duplicateKey] = currentSettings[key];
  }

  return nextSettings;
};

const sanitizeInventorySettings = (value: unknown): InventorySettings => {
  const raw = typeof value === 'object' && value ? (value as Partial<InventorySettings>) : {};
  const modifierBindings = ensureUniqueModifierBindings({
    quickMoveModifier: modifierBindingOptions.includes(raw.quickMoveModifier as ModifierBinding)
      ? (raw.quickMoveModifier as ModifierBinding)
      : defaultInventorySettings.quickMoveModifier,
    useItemModifier: modifierBindingOptions.includes(raw.useItemModifier as ModifierBinding)
      ? (raw.useItemModifier as ModifierBinding)
      : defaultInventorySettings.useItemModifier,
    splitStackModifier: modifierBindingOptions.includes(raw.splitStackModifier as ModifierBinding)
      ? (raw.splitStackModifier as ModifierBinding)
      : defaultInventorySettings.splitStackModifier,
  });

  return {
    ...modifierBindings,
    closeKey:
      typeof raw.closeKey === 'string' && raw.closeKey.trim().length > 0
        ? raw.closeKey
        : defaultInventorySettings.closeKey,
    rememberSearch: raw.rememberSearch ?? defaultInventorySettings.rememberSearch,
    rememberCategory: raw.rememberCategory ?? defaultInventorySettings.rememberCategory,
    autoOpenPermissions: raw.autoOpenPermissions ?? defaultInventorySettings.autoOpenPermissions,
    soundEffects: raw.soundEffects ?? defaultInventorySettings.soundEffects,
  };
};

const loadInventorySettings = (): InventorySettings => {
  if (!canUseDomStorage()) return defaultInventorySettings;

  try {
    const storedValue = window.localStorage.getItem(SETTINGS_STORAGE_KEY);
    if (!storedValue) return defaultInventorySettings;
    return sanitizeInventorySettings(JSON.parse(storedValue));
  } catch (error) {
    console.error('Failed to load inventory settings', error);
    return defaultInventorySettings;
  }
};

const loadInventoryUiMemory = (): InventoryUiMemory => {
  if (!canUseDomStorage()) return defaultUiMemory;

  try {
    const storedValue = window.localStorage.getItem(UI_MEMORY_STORAGE_KEY);
    if (!storedValue) return defaultUiMemory;

    const parsed = JSON.parse(storedValue) as Partial<InventoryUiMemory>;
    return {
      search: typeof parsed.search === 'string' ? parsed.search : defaultUiMemory.search,
      category:
        typeof parsed.category === 'string' && parsed.category.length > 0 ? parsed.category : defaultUiMemory.category,
    };
  } catch (error) {
    console.error('Failed to load inventory ui memory', error);
    return defaultUiMemory;
  }
};

export const formatKeyboardCode = (code: string) => {
  if (!code) return 'Unbound';
  if (code.startsWith('Key')) return code.slice(3).toUpperCase();
  if (code.startsWith('Digit')) return code.slice(5);

  const labels: Record<string, string> = {
    Escape: 'Esc',
    Space: 'Space',
    Backquote: '`',
    Minus: '-',
    Equal: '=',
    BracketLeft: '[',
    BracketRight: ']',
    Backslash: '\\',
    Semicolon: ';',
    Quote: "'",
    Comma: ',',
    Period: '.',
    Slash: '/',
    ControlLeft: 'Ctrl',
    ControlRight: 'Ctrl',
    ShiftLeft: 'Shift',
    ShiftRight: 'Shift',
    AltLeft: 'Alt',
    AltRight: 'Alt',
    Tab: 'Tab',
    CapsLock: 'Caps',
    Enter: 'Enter',
    Backspace: 'Backspace',
    Delete: 'Delete',
    Insert: 'Insert',
    Home: 'Home',
    End: 'End',
    PageUp: 'PgUp',
    PageDown: 'PgDn',
    ArrowUp: 'Up',
    ArrowDown: 'Down',
    ArrowLeft: 'Left',
    ArrowRight: 'Right',
  };

  return labels[code] || code;
};

export const InventorySettingsProvider = ({ children }: { children: React.ReactNode }) => {
  const [settings, setSettings] = useState<InventorySettings>(() => loadInventorySettings());
  const [uiMemory, setUiMemory] = useState<InventoryUiMemory>(() => loadInventoryUiMemory());
  const [isCapturingShortcut, setIsCapturingShortcut] = useState(false);

  useEffect(() => {
    if (!canUseDomStorage()) return;
    window.localStorage.setItem(SETTINGS_STORAGE_KEY, JSON.stringify(settings));
  }, [settings]);

  useEffect(() => {
    if (!canUseDomStorage()) return;
    window.localStorage.setItem(UI_MEMORY_STORAGE_KEY, JSON.stringify(uiMemory));
  }, [uiMemory]);

  const contextValue = useMemo<InventorySettingsContextValue>(
    () => ({
      settings,
      updateSetting: (key, value) => {
        setSettings((currentSettings) =>
          sanitizeInventorySettings(
            isModifierSettingKey(key)
              ? swapModifierBinding(currentSettings, key, value as ModifierBinding)
              : { ...currentSettings, [key]: value }
          )
        );
      },
      resetSettings: () => setSettings(defaultInventorySettings),
      uiMemory,
      updateUiMemory: (patch) => {
        setUiMemory((currentMemory) => ({ ...currentMemory, ...patch }));
      },
      resetUiMemory: () => setUiMemory(defaultUiMemory),
      isCapturingShortcut,
      setIsCapturingShortcut,
    }),
    [settings, uiMemory, isCapturingShortcut]
  );

  return <InventorySettingsContext.Provider value={contextValue}>{children}</InventorySettingsContext.Provider>;
};

export const useInventorySettings = () => {
  const context = useContext(InventorySettingsContext);

  if (!context) {
    throw new Error('InventorySettingsContext is undefined');
  }

  return context;
};
