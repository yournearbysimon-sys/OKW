import { useState, useLayoutEffect } from 'react';

export const useScale = () => {
  const [scale, setScale] = useState(1);

  useLayoutEffect(() => {
    const handleResize = () => {
      const { innerWidth, innerHeight } = window;
      const widthScale = innerWidth / 1920;
      const heightScale = innerHeight / 1080;
      // Use the smaller scale to ensure the UI fits within the screen while maintaining aspect ratio
      setScale(Math.min(widthScale, heightScale));
    };

    handleResize();

    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  return scale;
};
