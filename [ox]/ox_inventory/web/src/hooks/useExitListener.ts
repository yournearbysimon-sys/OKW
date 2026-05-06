import { useEffect, useRef } from 'react';
import { noop } from '../utils/misc';
import { fetchNui } from '../utils/fetchNui';
import { closeTooltip } from '../store/tooltip';
import { useAppDispatch } from '../store';
import { closeContextMenu } from '../store/contextMenu';
import { useInventorySettings } from '../components/settings/InventorySettingsContext';

type FrameVisibleSetter = (bool: boolean) => void;

export const useExitListener = (visibleSetter: FrameVisibleSetter) => {
  const setterRef = useRef<FrameVisibleSetter>(noop);
  const dispatch = useAppDispatch();
  const { settings, isCapturingShortcut } = useInventorySettings();

  useEffect(() => {
    setterRef.current = visibleSetter;
  }, [visibleSetter]);

  useEffect(() => {
    const keyHandler = (e: KeyboardEvent) => {
      if (isCapturingShortcut) return;
      if (e.code !== settings.closeKey) return;

      setterRef.current(false);
      dispatch(closeTooltip());
      dispatch(closeContextMenu());
      fetchNui('exit');
    };

    window.addEventListener('keyup', keyHandler);

    return () => window.removeEventListener('keyup', keyHandler);
  }, [dispatch, isCapturingShortcut, settings.closeKey]);
};
