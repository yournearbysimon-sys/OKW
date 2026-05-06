import React, { useEffect, useMemo, useState } from 'react';
import { createPortal } from 'react-dom';
import skeletonSvgRaw from '../../assets/Skeleton.svg?raw';
import bodyBgSvgRaw from '../../assets/body-bg-2.svg?raw';
import useNuiEvent from '../../hooks/useNuiEvent';
import { Locale } from '../../store/locale';
import { fetchNui } from '../../utils/fetchNui';
import { BODY_INJURY_PATHS, BODY_REGION_ORDER, BODY_VIEWBOX, BodyRegionKey, getBodyRegionMeta } from './BodyMappings';

const BODY_BG_SCALE_X = 599 / 596;
const BODY_BG_SCALE_Y = 1130 / 1137;
const BODY_CENTER_X = BODY_VIEWBOX.x + BODY_VIEWBOX.width / 2;
const BODY_CENTER_Y = BODY_VIEWBOX.y + BODY_VIEWBOX.height / 2;
const BODY_OVERALL_SCALE = 0.97;
const BODY_BACKGROUND_SCALE_X = 0.89;
const BODY_BACKGROUND_SCALE_Y = 0.92;
const BODY_FOREGROUND_SCALE = 0.97;

const MAIN_DEFAULT_LIGHT = 'var(--ui-body-default-light)';
const MAIN_DEFAULT_DARK = 'var(--ui-body-default-dark)';
const MAIN_DEFAULT_STROKE = 'var(--ui-body-default-stroke)';
const MAIN_HOVER_LIGHT = 'var(--ui-body-hover-light)';
const MAIN_HOVER_DARK = 'var(--ui-body-hover-dark)';
const MAIN_HOVER_STROKE = 'var(--ui-body-hover-stroke)';
const MAIN_INJURED_LIGHT = 'var(--ui-body-injured-light)';
const MAIN_INJURED_DARK = 'var(--ui-body-injured-dark)';
const MAIN_INJURED_STROKE = 'var(--ui-body-injured-stroke)';

const PREVIEW_HEALTHY_LIGHT = 'var(--ui-body-preview-healthy-light)';
const PREVIEW_HEALTHY_DARK = 'var(--ui-body-preview-healthy-dark)';
const PREVIEW_HEALTHY_STROKE = 'var(--ui-body-preview-healthy-stroke)';
const PREVIEW_INJURED_LIGHT = 'var(--ui-body-preview-injured-light)';
const PREVIEW_INJURED_DARK = 'var(--ui-body-preview-injured-dark)';
const PREVIEW_INJURED_STROKE = 'var(--ui-body-preview-injured-stroke)';
const PREVIEW_HIDDEN = 'transparent';

const stripSvgWrapper = (svgMarkup: string) =>
  svgMarkup
    .replace(/^<svg[^>]*>/, '')
    .replace(/<defs>[\s\S]*<\/defs>/g, '')
    .replace(/<\/svg>\s*$/, '');

const isBodyRegionKey = (value: string): value is BodyRegionKey =>
  Object.prototype.hasOwnProperty.call(BODY_INJURY_PATHS, value);

const buildSkeletonMarkup = (
  highlightedPathIndexes: Set<number>,
  palette: { light: string; dark: string; stroke: string },
  defaultPalette: { light: string; dark: string; stroke: string }
) => {
  let pathIndex = 0;

  return stripSvgWrapper(skeletonSvgRaw).replace(/<path\b[^>]*\/>/g, (pathTag) => {
    pathIndex += 1;

    const colors = highlightedPathIndexes.has(pathIndex) ? palette : defaultPalette;

    return pathTag
      .replaceAll('fill="#F5F5F5"', `fill="${colors.light}"`)
      .replaceAll('fill="#616161"', `fill="${colors.dark}"`)
      .replaceAll('stroke="black"', `stroke="${colors.stroke}"`);
  });
};

const BodyRegionTooltip: React.FC<{
  region: BodyRegionKey;
  injured: boolean;
  bodyPreviewMarkup: string;
  previewViewBox: { x: number; y: number; width: number; height: number };
}> = ({ region, injured, bodyPreviewMarkup, previewViewBox }) => {
  const regionMeta = getBodyRegionMeta(region);
  const t = (key: string, fallback: string) => Locale[key] || fallback;

  return (
    <div className="pointer-events-none flex min-w-[244px] max-w-[280px] flex-col rounded-xl border border-neutral-800 bg-[#1a1a1a] p-3 shadow-2xl outline-none">
      <div className="flex items-center gap-3">
        <div className="flex h-[56px] w-[56px] shrink-0 items-center justify-center rounded-lg bg-[#242424]">
          <svg
            width="42"
            height="42"
            viewBox={`${previewViewBox.x} ${previewViewBox.y} ${previewViewBox.width} ${previewViewBox.height}`}
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
          >
            <g
              transform={`translate(${BODY_CENTER_X} ${BODY_CENTER_Y}) scale(${BODY_OVERALL_SCALE}) translate(${-BODY_CENTER_X} ${-BODY_CENTER_Y})`}
            >
              <g
                transform={`translate(${BODY_CENTER_X} ${BODY_CENTER_Y}) scale(${BODY_FOREGROUND_SCALE}) translate(${-BODY_CENTER_X} ${-BODY_CENTER_Y})`}
                style={{ opacity: 0.96 }}
                dangerouslySetInnerHTML={{ __html: bodyPreviewMarkup }}
              />
            </g>
          </svg>
        </div>

        <div className="flex min-w-0 flex-col">
          <span className="truncate text-[15px] font-bold leading-tight text-white">{regionMeta.label}</span>
          <span className="mt-0.5 text-[12px] font-medium leading-tight text-neutral-400">{regionMeta.subtitle}</span>
        </div>
      </div>

      <div className="mb-2 mt-3 h-[1px] w-full rounded-full bg-neutral-700/50"></div>

      <div className="mb-3 text-[12px] font-medium leading-snug text-[#d2d2d2]">{regionMeta.description}</div>

      <div className="flex flex-col gap-1.5 text-[12px]">
        <div className="flex items-center justify-between gap-3">
          <span className="font-medium text-neutral-400">{t('body_status_label', 'Status:')}</span>
          <span className={`font-bold uppercase ${injured ? 'text-[#ff8a8a]' : 'text-[var(--color-primary)]'}`}>
            {injured ? t('body_status_injured', 'Injured') : t('body_status_stable', 'Stable')}
          </span>
        </div>

        <div className="flex items-start justify-between gap-3">
          <span className="font-medium text-neutral-400">{t('body_coverage_label', 'Coverage:')}</span>
          <span className="max-w-[145px] text-right font-bold text-white">{regionMeta.coverage}</span>
        </div>

        <div className="flex items-start justify-between gap-3">
          <span className="font-medium text-neutral-400">{t('body_focus_label', 'Focus:')}</span>
          <span className="max-w-[145px] text-right font-bold text-white">{regionMeta.focus}</span>
        </div>
      </div>
    </div>
  );
};

export const CharacterBody: React.FC = () => {
  const [injuries, setInjuries] = useState<string[]>([]);
  const [hoveredRegion, setHoveredRegion] = useState<BodyRegionKey | null>(null);
  const [tooltipPosition, setTooltipPosition] = useState<{ x: number; y: number } | null>(null);

  useNuiEvent<string[]>('setInjuries', (data) => {
    setInjuries(data ?? []);
  });

  useEffect(() => {
    fetchNui<string[]>('getInjuries')
      .then((data) => {
        if (data) setInjuries(data);
      })
      .catch(() => {});
  }, []);

  const injurySet = useMemo(() => {
    const nextSet = new Set<BodyRegionKey>();

    injuries.forEach((injury) => {
      if (isBodyRegionKey(injury)) {
        nextSet.add(injury);
      }
    });

    return nextSet;
  }, [injuries]);

  const injuredPathIndexes = useMemo(() => {
    const indexes = new Set<number>();

    injurySet.forEach((injury) => {
      BODY_INJURY_PATHS[injury].forEach((pathIndex) => indexes.add(pathIndex));
    });

    return indexes;
  }, [injurySet]);

  const hoveredPathIndexes = useMemo(() => {
    const indexes = new Set<number>();

    if (!hoveredRegion) return indexes;

    BODY_INJURY_PATHS[hoveredRegion].forEach((pathIndex) => {
      if (!injuredPathIndexes.has(pathIndex)) {
        indexes.add(pathIndex);
      }
    });

    return indexes;
  }, [hoveredRegion, injuredPathIndexes]);

  const bodySvgMarkup = useMemo(() => {
    let pathIndex = 0;

    return stripSvgWrapper(skeletonSvgRaw).replace(/<path\b[^>]*\/>/g, (pathTag) => {
      pathIndex += 1;

      if (injuredPathIndexes.has(pathIndex)) {
        return pathTag
          .replaceAll('fill="#F5F5F5"', `fill="${MAIN_INJURED_LIGHT}"`)
          .replaceAll('fill="#616161"', `fill="${MAIN_INJURED_DARK}"`)
          .replaceAll('stroke="black"', `stroke="${MAIN_INJURED_STROKE}"`);
      }

      if (hoveredPathIndexes.has(pathIndex)) {
        return pathTag
          .replaceAll('fill="#F5F5F5"', `fill="${MAIN_HOVER_LIGHT}"`)
          .replaceAll('fill="#616161"', `fill="${MAIN_HOVER_DARK}"`)
          .replaceAll('stroke="black"', `stroke="${MAIN_HOVER_STROKE}"`);
      }

      return pathTag
        .replaceAll('fill="#F5F5F5"', `fill="${MAIN_DEFAULT_LIGHT}"`)
        .replaceAll('fill="#616161"', `fill="${MAIN_DEFAULT_DARK}"`)
        .replaceAll('stroke="black"', `stroke="${MAIN_DEFAULT_STROKE}"`);
    });
  }, [hoveredPathIndexes, injuredPathIndexes]);

  const bodyBackgroundMarkup = useMemo(
    () =>
      stripSvgWrapper(bodyBgSvgRaw)
        .replace(/fill="(?!none)[^"]+"/g, 'fill="currentColor"')
        .replace(/stroke="(?!none)[^"]+"/g, 'stroke="currentColor"'),
    []
  );

  const bodyPreviewMarkup = useMemo(() => {
    if (!hoveredRegion) return '';

    const previewIndexes = new Set<number>(BODY_INJURY_PATHS[hoveredRegion]);
    const previewPalette = injurySet.has(hoveredRegion)
      ? { light: PREVIEW_INJURED_LIGHT, dark: PREVIEW_INJURED_DARK, stroke: PREVIEW_INJURED_STROKE }
      : { light: PREVIEW_HEALTHY_LIGHT, dark: PREVIEW_HEALTHY_DARK, stroke: PREVIEW_HEALTHY_STROKE };

    return buildSkeletonMarkup(previewIndexes, previewPalette, {
      light: PREVIEW_HIDDEN,
      dark: PREVIEW_HIDDEN,
      stroke: PREVIEW_HIDDEN,
    });
  }, [hoveredRegion, injurySet]);

  const previewViewBox = useMemo(() => {
    if (!hoveredRegion) return BODY_VIEWBOX;

    const { hitbox } = getBodyRegionMeta(hoveredRegion);
    const scaleX = BODY_VIEWBOX.width / 260;
    const scaleY = BODY_VIEWBOX.height / 517;
    const basePaddingX = hoveredRegion === 'TORSO' ? 28 : hoveredRegion === 'HEAD' ? 24 : 18;
    const basePaddingY = hoveredRegion === 'TORSO' ? 36 : hoveredRegion === 'HEAD' ? 24 : 22;

    const x = Math.max(BODY_VIEWBOX.x, BODY_VIEWBOX.x + hitbox.x * scaleX - basePaddingX);
    const y = Math.max(BODY_VIEWBOX.y, BODY_VIEWBOX.y + hitbox.y * scaleY - basePaddingY);
    const maxRight = BODY_VIEWBOX.x + BODY_VIEWBOX.width;
    const maxBottom = BODY_VIEWBOX.y + BODY_VIEWBOX.height;
    const width = Math.min(maxRight - x, hitbox.width * scaleX + basePaddingX * 2);
    const height = Math.min(maxBottom - y, hitbox.height * scaleY + basePaddingY * 2);

    return { x, y, width, height };
  }, [hoveredRegion]);

  const tooltipStyle = useMemo(() => {
    if (!tooltipPosition || typeof window === 'undefined') return undefined;

    const tooltipWidth = 280;
    const tooltipHeight = 188;
    const gap = 18;
    const edgePadding = 12;

    let left = tooltipPosition.x + gap;
    let top = tooltipPosition.y - 8;

    if (left + tooltipWidth > window.innerWidth - edgePadding) {
      left = tooltipPosition.x - tooltipWidth - gap;
    }

    if (left < edgePadding) {
      left = edgePadding;
    }

    if (top + tooltipHeight > window.innerHeight - edgePadding) {
      top = window.innerHeight - tooltipHeight - edgePadding;
    }

    if (top < edgePadding) {
      top = edgePadding;
    }

    return {
      position: 'fixed' as const,
      left,
      top,
      zIndex: 99999,
      pointerEvents: 'none' as const,
    };
  }, [tooltipPosition]);

  const handleRegionHover = (region: BodyRegionKey, event: React.MouseEvent<HTMLButtonElement>) => {
    setHoveredRegion(region);
    setTooltipPosition({ x: event.clientX, y: event.clientY });
  };

  return (
    <>
      <div
        className="relative h-[517px] w-[260px]"
        onMouseLeave={() => {
          setHoveredRegion(null);
          setTooltipPosition(null);
        }}
      >
        <svg
          className="pointer-events-none"
          width="260"
          height="517"
          viewBox={`${BODY_VIEWBOX.x} ${BODY_VIEWBOX.y} ${BODY_VIEWBOX.width} ${BODY_VIEWBOX.height}`}
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <g
            transform={`translate(${BODY_CENTER_X} ${BODY_CENTER_Y}) scale(${BODY_OVERALL_SCALE}) translate(${-BODY_CENTER_X} ${-BODY_CENTER_Y})`}
          >
            <g
              transform={`translate(${BODY_CENTER_X} ${BODY_CENTER_Y}) scale(${BODY_BACKGROUND_SCALE_X} ${BODY_BACKGROUND_SCALE_Y}) translate(${-BODY_CENTER_X} ${-BODY_CENTER_Y})`}
            >
              <g
                transform={`scale(${BODY_BG_SCALE_X} ${BODY_BG_SCALE_Y})`}
                style={{ color: 'var(--color-primary)', opacity: 0.12 }}
                aria-hidden="true"
                dangerouslySetInnerHTML={{ __html: bodyBackgroundMarkup }}
              />
            </g>
            <g
              transform={`translate(${BODY_CENTER_X} ${BODY_CENTER_Y}) scale(${BODY_FOREGROUND_SCALE}) translate(${-BODY_CENTER_X} ${-BODY_CENTER_Y})`}
              style={{ opacity: 0.38 }}
              dangerouslySetInnerHTML={{ __html: bodySvgMarkup }}
            />
          </g>
        </svg>

        {BODY_REGION_ORDER.map((region) => {
          const regionMeta = getBodyRegionMeta(region);
          const { hitbox } = regionMeta;

          return (
            <button
              key={region}
              type="button"
              tabIndex={-1}
              aria-label={regionMeta.label}
              className="absolute border-0 bg-transparent p-0 outline-none"
              style={{
                left: hitbox.x,
                top: hitbox.y,
                width: hitbox.width,
                height: hitbox.height,
                borderRadius: hitbox.radius,
                cursor: 'help',
              }}
              onMouseEnter={(event) => handleRegionHover(region, event)}
              onMouseMove={(event) => handleRegionHover(region, event)}
            />
          );
        })}
      </div>

      {hoveredRegion &&
        tooltipStyle &&
        createPortal(
          <div style={tooltipStyle}>
            <BodyRegionTooltip
              region={hoveredRegion}
              injured={injurySet.has(hoveredRegion)}
              bodyPreviewMarkup={bodyPreviewMarkup}
              previewViewBox={previewViewBox}
            />
          </div>,
          document.body
        )}
    </>
  );
};
