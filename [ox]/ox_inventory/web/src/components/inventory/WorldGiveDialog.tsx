import React, { useEffect, useState } from 'react';
import { useAppDispatch, useAppSelector } from '../../store';
import { closeWorldGiveDialog, selectItemAmount, selectWorldGiveDialog, setItemAmount } from '../../store/inventory';
import { Locale } from '../../store/locale';
import { fetchNui } from '../../utils/fetchNui';
import { getItemUrl, handleItemImageError } from '../../helpers';
import { Items } from '../../store/items';

const WorldGiveDialog: React.FC = () => {
  const dispatch = useAppDispatch();
  const dialog = useAppSelector(selectWorldGiveDialog);
  const itemAmount = useAppSelector(selectItemAmount);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!dialog) {
      setSubmitting(false);
      return;
    }

    const defaultAmount = itemAmount > 0 && itemAmount <= dialog.item.count ? itemAmount : 1;
    dispatch(setItemAmount(defaultAmount));
  }, [dialog, dispatch]);

  if (!dialog) return null;

  const label = dialog.item.metadata?.label || Items[dialog.item.name]?.label || dialog.item.name;
  const count = Math.max(1, Math.min(itemAmount || 1, dialog.item.count));
  const targetName = dialog.target.targetName || `[${dialog.target.targetId}]`;

  const closeDialog = () => {
    if (submitting) return;
    dispatch(closeWorldGiveDialog());
  };

  const inputHandler = (event: React.ChangeEvent<HTMLInputElement>) => {
    let value = event.target.valueAsNumber;
    if (isNaN(value) || value < 1) value = 1;
    if (value > dialog.item.count) value = dialog.item.count;
    dispatch(setItemAmount(Math.floor(value)));
  };

  const confirmTransfer = async () => {
    setSubmitting(true);

    try {
      await fetchNui('confirmGiveItemDrag', {
        targetId: dialog.target.targetId,
        slot: dialog.item.slot,
        count,
        inventoryId: dialog.inventoryId,
      });
    } catch (error) {
      console.error(error);
    } finally {
      setSubmitting(false);
      dispatch(closeWorldGiveDialog());
    }
  };

  return (
    <div className="fixed inset-0 z-[100001] flex items-center justify-center bg-black/40" onClick={closeDialog}>
      <div
        className="w-[360px] rounded-lg border border-neutral-500 bg-black/70 p-3 font-sans shadow-[0_16px_45px_rgba(0,0,0,0.38)]"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="mb-3 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div style={{ filter: 'drop-shadow(0 0 6px rgba(var(--color-primary-rgb), 0.35))' }}>
              <div
                style={{
                  width: 40,
                  height: 40,
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
                    width: 31,
                    height: 31,
                    backgroundColor: 'var(--color-primary)',
                    borderRadius: 4,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <span
                    className="material-symbols-outlined"
                    style={{
                      fontSize: 17,
                      color: 'var(--ui-accent-foreground)',
                      fontVariationSettings: "'FILL' 1",
                    }}
                  >
                    pan_tool_alt
                  </span>
                </div>
              </div>
            </div>

            <div className="flex flex-col leading-tight mt-0.5">
              <p className="text-[16px] font-bold tracking-wide uppercase text-white">{Locale.ui_give || 'Give'}</p>
              <p className="mt-[1px] text-[10px] text-[#A8A8A8]">Direct player transfer</p>
            </div>
          </div>

          <button
            className="material-symbols-outlined text-white/75 transition hover:text-white"
            style={{ fontSize: '20px' }}
            onClick={closeDialog}
            disabled={submitting}
          >
            close
          </button>
        </div>

        <div className="flex items-start gap-3">
          <div className="relative h-[72px] w-[72px] shrink-0 rounded-lg border border-[rgba(135,135,135,0.2)] bg-[linear-gradient(135deg,rgba(23,23,23,0.45)_0%,rgba(23,23,23,0.08)_100%)]">
            <img
              src={getItemUrl(dialog.item)}
              alt={label}
              className="absolute left-1/2 top-1/2 h-[44px] w-[44px] -translate-x-1/2 -translate-y-1/2 object-contain"
              onError={handleItemImageError}
            />
            <div className="absolute bottom-1.5 left-2 text-[11px] font-bold leading-none text-white/85">
              {dialog.item.count}
            </div>
          </div>

          <div className="min-w-0 flex-1">
            <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-[#8d8d8d]">
              {Locale.ui_give || 'Give'}
            </p>
            <p className="truncate text-[24px] font-bold leading-none text-white">{label}</p>
            <p className="mt-1 truncate text-[12px] font-semibold text-[var(--color-primary)]">{targetName}</p>
          </div>
        </div>

        <div className="mt-3 rounded-lg bg-[linear-gradient(180deg,rgba(255,255,255,0.03)_0%,rgba(255,255,255,0.01)_100%)] p-2">
          <div className="mb-1.5 flex items-center justify-between">
            <span className="text-[12px] font-semibold uppercase tracking-[0.18em] text-[#8d8d8d]">
              {Locale.quantity || 'Quantity'}
            </span>
            <span className="text-[12px] font-bold text-white">
              {count} / {dialog.item.count}
            </span>
          </div>

          <div className="rounded-lg border border-[rgba(135,135,135,0.18)] bg-[linear-gradient(135deg,rgba(23,23,23,0.45)_0%,rgba(23,23,23,0.08)_100%)] px-3 py-2 shadow-[inset_0_1px_0_rgba(255,255,255,0.03)]">
            <input
              type="number"
              min={1}
              max={dialog.item.count}
              value={count}
              onChange={inputHandler}
              className="w-full bg-transparent text-center text-[20px] font-medium leading-none text-white caret-transparent [appearance:textfield] selection:bg-[rgba(var(--color-primary-rgb),0.2)] focus:outline-none [&::-webkit-inner-spin-button]:appearance-none [&::-webkit-outer-spin-button]:appearance-none"
            />
          </div>

          <div className="mt-1.5 flex h-3 items-center px-1">
            <input
              type="range"
              min={1}
              max={dialog.item.count}
              value={count}
              onChange={inputHandler}
              className="world-give-slider"
            />
          </div>
        </div>

        <p className="mt-3 text-[11px] text-[#888888]">
          {Locale.ui_drop_item_give || 'Confirm the amount to transfer to the targeted player.'}
        </p>

        <div className="mt-4 grid grid-cols-2 gap-3">
          <button
            className="rounded-lg border border-[rgba(135,135,135,0.25)] bg-[linear-gradient(135deg,rgba(23,23,23,0.45)_0%,rgba(23,23,23,0.08)_100%)] px-4 py-2.5 text-[15px] font-semibold text-white transition hover:border-[rgba(170,170,170,0.4)] hover:bg-white/10"
            onClick={closeDialog}
            disabled={submitting}
          >
            {Locale.ui_cancel || 'Cancel'}
          </button>
          <button
            className="rounded-lg bg-[var(--color-primary)] px-4 py-2.5 text-[15px] font-semibold text-[#1b2d26] transition hover:brightness-105 disabled:opacity-60"
            onClick={confirmTransfer}
            disabled={submitting}
          >
            {submitting ? Locale.ui_confirming || 'Confirming...' : Locale.ui_confirm || 'Confirm'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default WorldGiveDialog;
