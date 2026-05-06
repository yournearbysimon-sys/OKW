const CircularProgress: React.FC<{ progress: number }> = ({ progress }) => {
  const radius = 10;
  const stroke = 2.5;
  const normalized = radius - stroke * 0.5;
  const circumference = 2 * Math.PI * normalized;
  const strokeDashoffset = circumference - progress * circumference;

  return (
    <svg width={radius * 2} height={radius * 2} className="rotate-[-90deg]">
      <circle
        cx={radius}
        cy={radius}
        r={normalized}
        fill="transparent"
        stroke="var(--ui-surface-hover-dark)"
        strokeWidth={stroke}
      />
      <circle
        cx={radius}
        cy={radius}
        r={normalized}
        fill="transparent"
        stroke="var(--color-primary)"
        strokeWidth={stroke}
        strokeDasharray={circumference}
        strokeDashoffset={strokeDashoffset}
        style={{ transition: 'stroke-dashoffset 0.1s linear' }}
      />
    </svg>
  );
};

export default CircularProgress;
