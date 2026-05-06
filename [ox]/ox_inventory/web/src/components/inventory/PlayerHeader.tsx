import React, { useState, useRef, useEffect } from 'react';
import useNuiEvent from '../../hooks/useNuiEvent';
import { Locale } from '../../store/locale';

const PlayerHeader: React.FC = () => {
  const [playerData, setPlayerData] = useState({
    name: 'Player Name',
    job: 'Job/Gang Name',
    gang: 'none',
    cash: 100,
    bank: 2000,
    citizenId: '—',
    phone: '—',
    house: '—',
    vehicle: '—',
    image: '',
  });

  const [collapsed, setCollapsed] = useState(true);
  const contentRef = useRef<HTMLDivElement>(null);
  const [maxHeight, setMaxHeight] = useState('auto');

  useEffect(() => {
    const el = contentRef.current;
    if (!el) return;
    if (!collapsed) {
      setMaxHeight(`${el.scrollHeight}px`);
      const t = setTimeout(() => setMaxHeight('auto'), 300);
      return () => clearTimeout(t);
    } else {
      setMaxHeight('0px');
    }
  }, [collapsed]);

  useNuiEvent('setPlayerData', (data: any) => {
    if (!data) return;
    setPlayerData((prev) => ({
      ...prev,
      name: data.name ?? prev.name,
      cash: data.cash ?? prev.cash,
      bank: data.bank ?? prev.bank,
      job: data.job?.label ?? data.job?.name ?? data.job ?? prev.job,
      gang: data.gang?.label ?? data.gang?.name ?? data.gang ?? prev.gang,
      citizenId: data.citizenId ?? data.citizen_id ?? data.id ?? prev.citizenId,
      phone: data.phone ?? prev.phone,
      house: data.house ?? data.houseLocation ?? prev.house,
      vehicle: data.vehicle ?? data.personalVehicle ?? prev.vehicle,
      image: data.image ?? prev.image,
    }));
  });

  const formatMoney = (value: any) => {
    if (typeof value === 'number') return `${value.toLocaleString('en-US')}$`;
    if (typeof value === 'string' && value.trim().length > 0) return value;
    return '0$';
  };

  const jobDisplay =
    playerData.gang && playerData.gang !== 'none' ? `${playerData.job} / ${playerData.gang}` : playerData.job;

  const infoItems = [
    { label: Locale.ui_name || 'Name', value: playerData.name, icon: 'person' },
    { label: Locale.ui_job_gang || 'Job/Gang', value: jobDisplay, icon: 'work' },
    { label: Locale.ui_cash || 'Cash', value: formatMoney(playerData.cash), icon: 'attach_money' },
    { label: Locale.ui_bank || 'Bank', value: formatMoney(playerData.bank), icon: 'account_balance' },
  ];

  return (
    <div className="flex flex-col items-center mb-3 mt-2 relative w-full font-sans">
      <div className="bg-black/70 rounded-lg border border-neutral-500 w-[530px] p-4">
        {/* INVENTORY HEADER */}
        <div className="flex items-center gap-3 mb-2">
          {/* Glowing Badge */}
          <div style={{ filter: 'drop-shadow(0 0 6px rgba(var(--color-primary-rgb), 0.35))' }}>
            <div
              style={{
                width: 46,
                height: 46,
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
                  width: 37,
                  height: 37,
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
                    fontSize: 21,
                    color: 'var(--ui-accent-foreground)',
                    fontVariationSettings: "'FILL' 1",
                  }}
                >
                  manage_accounts
                </span>
              </div>
            </div>
          </div>

          {/* Title + Subtitle */}
          <div className="flex flex-col leading-none flex-1">
            <p className="text-white font-bold text-xl tracking-wide uppercase">{Locale.ui_inventory || 'INVENTORY'}</p>
            <p className="text-[#A8A8A8] text-[13px]">{Locale.ui_player_info || 'Player Info'}</p>
          </div>

          {/* Collapse Toggle Arrow */}
          <span
            className={`material-symbols-outlined flex-shrink-0 cursor-pointer text-white transition-all duration-300 ${
              collapsed ? 'rotate-180' : 'rotate-0'
            }`}
            style={{ fontSize: '20px' }}
            onClick={() => setCollapsed((prev) => !prev)}
          >
            keyboard_arrow_up
          </span>
        </div>

        {/* Collapsible Info Grid */}
        <div
          style={{
            maxHeight,
            overflow: 'hidden',
            opacity: collapsed ? 0 : 1,
            transition: 'max-height 0.3s ease, opacity 0.3s ease',
          }}
        >
          <div ref={contentRef}>
            <div className="grid grid-cols-2 gap-x-6 gap-y-1">
              {infoItems.map((item, index) => (
                <div key={`${item.label}-${index}`} className="flex items-center gap-2.5">
                  {/* Icon Badge */}
                  <div style={{ filter: 'drop-shadow(0 0 4px var(--ui-shadow-light))' }} className="flex-shrink-0">
                    <div
                      style={{
                        width: 38,
                        height: 38,
                        backgroundColor: 'var(--ui-surface-light-weak)',
                        borderRadius: 5,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                      }}
                    >
                      <div
                        style={{
                          width: 29,
                          height: 29,
                          backgroundColor: 'var(--ui-surface-light-medium)',
                          borderRadius: 4,
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                        }}
                      >
                        <span
                          className="material-symbols-outlined text-white/70 opacity-90"
                          style={{ fontSize: 16, fontVariationSettings: "'FILL' 1" }}
                        >
                          {item.icon}
                        </span>
                      </div>
                    </div>
                  </div>
                  {/* Info Details */}
                  <div className="flex flex-col leading-none mt-0.5">
                    <span className="text-[10px] font-semibold uppercase tracking-wide text-white/50">
                      {item.label}
                    </span>
                    <span className="text-white text-[13px] font-medium">{item.value}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PlayerHeader;
