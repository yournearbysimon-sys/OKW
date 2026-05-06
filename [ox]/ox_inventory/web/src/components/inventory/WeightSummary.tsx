import React from 'react';

type WeightSummaryProps = {
  weight: number;
  maxWeight?: number;
  align?: 'left' | 'right';
};

const WeightSummary: React.FC<WeightSummaryProps> = ({ weight, maxWeight, align = 'right' }) => {
  if (!maxWeight) return null;

  const usedKg = Number(weight / 1000).toFixed(1);
  const maxKg = Number(maxWeight / 1000).toFixed(1);
  const justifyClass = align === 'left' ? 'items-start' : 'items-end';

  return (
    <div className={`flex ${justifyClass}`}>
      <div className="flex items-center gap-1.5 font-bold text-[15px] text-white">
        <span className="material-symbols-outlined text-[18px]" style={{ fontVariationSettings: "'FILL' 1" }}>
          weight
        </span>
        <span>
          {usedKg} / {maxKg} kg
        </span>
      </div>
    </div>
  );
};

export default WeightSummary;
