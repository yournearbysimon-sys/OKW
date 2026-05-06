import { Inventory, SlotWithItem } from '../../typings';
import React, { Fragment, useMemo } from 'react';
import { Items } from '../../store/items';
import { Locale } from '../../store/locale';
import { useAppSelector } from '../../store';
import ClockIcon from '../utils/icons/ClockIcon';
import { getItemUrl, handleItemImageError } from '../../helpers';

const SlotTooltip: React.ForwardRefRenderFunction<
  HTMLDivElement,
  { item: SlotWithItem; inventoryType: Inventory['type']; style: React.CSSProperties }
> = ({ item, inventoryType, style }, ref) => {
  const additionalMetadata = useAppSelector((state) => state.inventory.additionalMetadata);
  const itemData = useMemo(() => Items[item.name], [item]);
  const ingredients = useMemo(() => {
    if (!item.ingredients) return null;
    return Object.entries(item.ingredients).sort((a, b) => a[1] - b[1]);
  }, [item]);
  const description = item.metadata?.description || itemData?.description;
  const ammoName = itemData?.ammoName && Items[itemData?.ammoName]?.label;

  return (
    <>
      {!itemData ? (
        <div ref={ref} style={style} className="z-[99999]">
          <div className="metadata">
            <p className="value">{item.name}</p>
          </div>
        </div>
      ) : (
        <div
          style={{ ...style }}
          ref={ref}
          className="flex flex-col z-[99999] bg-[#1a1a1a] border border-neutral-800 rounded-xl p-3 shadow-2xl min-w-[200px] outline-none"
        >
          <div className="flex items-center gap-3">
            <div className="w-[50px] h-[50px] bg-[#2a2a2a] rounded-lg flex items-center justify-center shrink-0">
              <img
                src={getItemUrl(item)}
                alt="icon"
                className="max-w-[80%] max-h-[80%] object-contain"
                onError={handleItemImageError}
              />
            </div>
            <div className="flex flex-col">
              <span className="text-white font-bold leading-tight text-[15px] drop-shadow-md">
                {item.metadata?.label || itemData.label || item.name}
              </span>
              <span
                className="text-neutral-400 text-[12px] font-medium leading-tight mt-0.5"
                style={{ textTransform: 'capitalize' }}
              >
                Item
              </span>
            </div>
          </div>
          <div className="h-[1px] w-full bg-neutral-700/50 mt-3 mb-2 rounded-full"></div>

          <div className="flex flex-col gap-1.5 text-[12px] w-full">
            {inventoryType === 'crafting' ? (
              <div className="flex justify-between items-center w-full">
                <span className="text-neutral-400 font-medium flex items-center gap-1">
                  <ClockIcon /> {Locale.duration || 'Duration'}:
                </span>
                <span className="text-white font-bold">
                  {(item.duration !== undefined ? item.duration : 3000) / 1000}s
                </span>
              </div>
            ) : null}

            {description && (
              <div className="flex flex-col mt-1 mb-1">
                <span className="text-neutral-500 font-bold text-[10px] uppercase mb-0.5">
                  {Locale.description || 'Description'}
                </span>
                <span className="text-gray-300 font-medium leading-tight">{description}</span>
              </div>
            )}

            {inventoryType !== 'crafting' ? (
              <>
                <div className="flex justify-between items-center w-full">
                  <span className="text-neutral-400 font-medium">{Locale.quantity || 'Quantity'}:</span>
                  <span className="text-white font-bold">{(item.count ?? 1).toLocaleString('en-us')}</span>
                </div>
                {item.weight > 0 && (
                  <div className="flex justify-between items-center w-full">
                    <span className="text-neutral-400 font-medium">{Locale.ui_weight || 'Weight'}:</span>
                    <span className="text-white font-bold">
                      {(item.weight || 0) >= 1000
                        ? `${((item.weight || 0) / 1000).toLocaleString('en-us', { minimumFractionDigits: 1 })} kg`
                        : `${(item.weight || 0).toLocaleString('en-us', { minimumFractionDigits: 1 })} g`}
                    </span>
                  </div>
                )}
                {Items[item.name as string]?.rarity && (
                  <div className="flex justify-between items-center w-full">
                    <span className="text-neutral-400 font-medium">Rarity:</span>
                    <span className="text-white font-bold uppercase">{Items[item.name as string]?.rarity}</span>
                  </div>
                )}
                {item.durability !== undefined && (
                  <div className="flex justify-between items-center w-full mt-1">
                    <span className="text-neutral-400 font-medium">{Locale.ui_durability || 'Durability'}:</span>
                    <span className="text-white font-bold">{Math.trunc(item.durability)}</span>
                  </div>
                )}
                {item.metadata?.ammo !== undefined && (
                  <div className="flex justify-between items-center w-full">
                    <span className="text-neutral-400 font-medium">{Locale.ui_ammo || 'Ammo'}:</span>
                    <span className="text-white font-bold">{item.metadata.ammo}</span>
                  </div>
                )}
                {ammoName && (
                  <div className="flex justify-between items-center w-full">
                    <span className="text-neutral-400 font-medium">Ammo type:</span>
                    <span className="text-white font-bold">{ammoName}</span>
                  </div>
                )}
                {typeof item.metadata === 'object' &&
                  Object.entries(item.metadata).map(([key, val]) => {
                    if (typeof val === 'object' && val?.show && typeof val.show === 'object') {
                      return (
                        <div className="flex justify-between items-center w-full" key={key}>
                          <span className="text-neutral-400 font-medium">{val.show.label || key}:</span>
                          <span className="text-white font-bold">{val.show.value}</span>
                        </div>
                      );
                    }
                    return null;
                  })}
                {item.metadata?.serial && (
                  <div className="flex flex-col w-full mt-1">
                    <div className="h-[1px] w-full bg-neutral-700/50 mb-1.5 rounded-full"></div>
                    <div className="flex justify-between items-center w-full">
                      <span className="text-neutral-400 font-medium">{Locale.ui_serial || 'Serial number'}:</span>
                      <span className="text-white font-bold text-[11px]">{item.metadata.serial}</span>
                    </div>
                  </div>
                )}
                {additionalMetadata.map((data: { metadata: string; value: string }, index: number) => (
                  <Fragment key={`metadata-${index}`}>
                    {item.metadata && item.metadata[data.metadata] && (
                      <div className="flex justify-between items-center w-full">
                        <span className="text-neutral-400 font-medium">{data.value}:</span>
                        <span className="text-white font-bold">{item.metadata[data.metadata]}</span>
                      </div>
                    )}
                  </Fragment>
                ))}
              </>
            ) : (
              ingredients && (
                <div className="flex flex-col w-full">
                  <span className="text-neutral-500 font-bold text-[10px] uppercase mb-1">
                    {Locale.ingredients || 'Ingredients'}
                  </span>
                  {ingredients.map((ingredient) => {
                    const [ingItem, count] = [ingredient[0], ingredient[1]];
                    return (
                      <div className="flex items-center gap-2 mb-1" key={`ingredient-${ingItem}`}>
                        <img
                          src={ingItem ? getItemUrl(ingItem) : 'none'}
                          alt="item-image"
                          className="w-[20px] h-[20px] object-contain"
                          onError={handleItemImageError}
                        />
                        <span className="text-white font-medium text-[11px]">
                          {count >= 1
                            ? `${count}x ${Items[ingItem]?.label || ingItem}`
                            : count === 0
                            ? `${Items[ingItem]?.label || ingItem}`
                            : count < 1 && `${count * 100}% ${Items[ingItem]?.label || ingItem}`}
                        </span>
                      </div>
                    );
                  })}
                </div>
              )
            )}
          </div>
        </div>
      )}
    </>
  );
};

export default React.forwardRef(SlotTooltip);
