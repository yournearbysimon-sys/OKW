import { Items } from '../store/items';
import { ItemCategoryData, ItemData } from '../typings/item';

export type ResolvedCategory = {
  name: string;
  icon: string;
  order: number;
};

const defaultCategoryIcon = 'category';

export const resolveItemCategory = (category?: ItemCategoryData): ResolvedCategory | undefined => {
  if (!category) return undefined;

  if (typeof category === 'string') {
    const name = category.trim();

    if (!name) return undefined;

    return {
      name,
      icon: defaultCategoryIcon,
      order: 999,
    };
  }

  const name = category.name?.trim();

  if (!name) return undefined;

  return {
    name,
    icon: category.icon?.trim() || defaultCategoryIcon,
    order: category.order ?? 999,
  };
};

export const getItemCategoryName = (item?: ItemData | null): string | undefined => {
  return resolveItemCategory(item?.category)?.name;
};

export const getAvailableItemCategories = (): ResolvedCategory[] => {
  const categoryMap = new Map<string, ResolvedCategory>();

  Object.values(Items).forEach((item) => {
    const category = resolveItemCategory(item?.category);

    if (!category) return;

    const existing = categoryMap.get(category.name);

    if (!existing || category.order < existing.order) {
      categoryMap.set(category.name, category);
    }
  });

  return [
    { name: 'All', icon: 'apps', order: 0 },
    ...Array.from(categoryMap.values()).sort((a, b) => {
      if (a.order !== b.order) return a.order - b.order;

      return a.name.localeCompare(b.name);
    }),
  ];
};
