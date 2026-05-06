import { useEffect } from 'react';
import { setSplitModifierPressed } from '../../store/inventory';
import useKeyPress from '../../hooks/useKeyPress';
import { useAppDispatch } from '../../store';
import { useInventorySettings } from '../settings/InventorySettingsContext';

const KeyPress: React.FC = () => {
  const dispatch = useAppDispatch();
  const { settings } = useInventorySettings();
  const splitModifierPressed = useKeyPress(settings.splitStackModifier);

  useEffect(() => {
    dispatch(setSplitModifierPressed(splitModifierPressed));
  }, [splitModifierPressed, dispatch]);

  return <></>;
};

export default KeyPress;
