type RarityStyle = { text: string; background: string };
type RarityConfig = Record<string, Record<string, string | number>>;

const defaultRarityKeys = ['common', 'uncommon', 'rare', 'epic', 'legendary', 'danger', 'gold'];

const getRarityCssVar = (rarity: string, property: 'text' | 'background'): string => {
  const suffix = property === 'background' ? 'bg' : property;
  return `var(--ui-rarity-${rarity}-${suffix})`;
};

const createRarityStyle = (rarity: string): RarityStyle => ({
  text: getRarityCssVar(rarity, 'text'),
  background: getRarityCssVar(rarity, 'background'),
});

const createDefaultRarity = (): Record<string, RarityStyle> =>
  defaultRarityKeys.reduce<Record<string, RarityStyle>>((acc, rarity) => {
    acc[rarity] = createRarityStyle(rarity);
    return acc;
  }, {});

export const Rarity: Record<string, RarityStyle> = createDefaultRarity();

export const hydrateRarity = (config?: RarityConfig): Record<string, string | number> => {
  for (const key of Object.keys(Rarity)) {
    delete Rarity[key];
  }

  Object.assign(Rarity, createDefaultRarity());

  if (!config) return {};

  const variables: Record<string, string | number> = {};

  for (const [rawName, entry] of Object.entries(config)) {
    const name = rawName.trim().toLowerCase();
    if (!name) continue;

    Rarity[name] = createRarityStyle(name);

    const text = entry.text;
    const background = entry.background;

    if (text !== undefined && text !== null) {
      variables[`ui-rarity-${name}-text`] = `${text}`.trim();
    }

    if (background !== undefined && background !== null) {
      variables[`ui-rarity-${name}-bg`] = `${background}`.trim();
    }
  }

  return variables;
};
