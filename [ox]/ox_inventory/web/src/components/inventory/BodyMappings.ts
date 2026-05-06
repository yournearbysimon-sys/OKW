import { Locale } from '../../store/locale';

export const BODY_VIEWBOX = {
  x: 110,
  y: 0,
  width: 380,
  height: 1130,
} as const;

export const BODY_REGION_ORDER = ['HEAD', 'TORSO', 'RIGHT_ARM', 'LEFT_ARM', 'RIGHT_LEG', 'LEFT_LEG'] as const;

export type BodyRegionKey = (typeof BODY_REGION_ORDER)[number];

type BodyRegionHitbox = {
  x: number;
  y: number;
  width: number;
  height: number;
  radius: number;
};

export type BodyRegionMeta = {
  label: string;
  subtitle: string;
  description: string;
  coverage: string;
  focus: string;
  hitbox: BodyRegionHitbox;
};

type BodyRegionMetaDefinition = {
  labelKey: string;
  labelFallback: string;
  subtitleKey: string;
  subtitleFallback: string;
  descriptionKey: string;
  descriptionFallback: string;
  coverageKey: string;
  coverageFallback: string;
  focusKey: string;
  focusFallback: string;
  hitbox: BodyRegionHitbox;
};

const translate = (key: string, fallback: string) => Locale[key] || fallback;

// SVG path indexes are 1-based and follow the export order inside body-anterior.svg.
// Each injury group colors broader body regions instead of individual bones.
export const BODY_INJURY_PATHS: Record<BodyRegionKey, number[]> = {
  HEAD: [39, 40, 41, 42, 43, 44],
  TORSO: [13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 27, 36, 37, 38],
  RIGHT_ARM: [23, 24, 45, 46, 49, 50, 51, 52, 57, 58, 61, 62],
  LEFT_ARM: [25, 26, 47, 48, 53, 54, 55, 56, 59, 60, 63, 64],
  RIGHT_LEG: [1, 2, 5, 6, 9, 10],
  LEFT_LEG: [3, 4, 7, 8, 11, 12],
};

const BODY_REGION_META_DEFINITIONS: Record<BodyRegionKey, BodyRegionMetaDefinition> = {
  HEAD: {
    labelKey: 'body_head_label',
    labelFallback: 'Head',
    subtitleKey: 'body_head_subtitle',
    subtitleFallback: 'Cranial region',
    descriptionKey: 'body_head_description',
    descriptionFallback: 'Tracks skull, facial and upper-neck trauma.',
    coverageKey: 'body_head_coverage',
    coverageFallback: 'Skull, face, jaw, neck',
    focusKey: 'body_head_focus',
    focusFallback: 'Vision, balance and awareness',
    hitbox: { x: 94, y: 6, width: 72, height: 92, radius: 999 },
  },
  TORSO: {
    labelKey: 'body_torso_label',
    labelFallback: 'Torso',
    subtitleKey: 'body_torso_subtitle',
    subtitleFallback: 'Chest and abdomen',
    descriptionKey: 'body_torso_description',
    descriptionFallback: 'Tracks chest, spine and abdominal impact.',
    coverageKey: 'body_torso_coverage',
    coverageFallback: 'Chest, ribs, spine, abdomen',
    focusKey: 'body_torso_focus',
    focusFallback: 'Breathing and vital organs',
    hitbox: { x: 77, y: 92, width: 108, height: 176, radius: 44 },
  },
  RIGHT_ARM: {
    labelKey: 'body_right_arm_label',
    labelFallback: 'Right arm',
    subtitleKey: 'body_right_arm_subtitle',
    subtitleFallback: 'Shoulder to hand',
    descriptionKey: 'body_right_arm_description',
    descriptionFallback: 'Tracks the full right upper limb.',
    coverageKey: 'body_right_arm_coverage',
    coverageFallback: 'Shoulder, arm, forearm, hand',
    focusKey: 'body_right_arm_focus',
    focusFallback: 'Grip and arm movement',
    hitbox: { x: 20, y: 98, width: 64, height: 226, radius: 40 },
  },
  LEFT_ARM: {
    labelKey: 'body_left_arm_label',
    labelFallback: 'Left arm',
    subtitleKey: 'body_left_arm_subtitle',
    subtitleFallback: 'Shoulder to hand',
    descriptionKey: 'body_left_arm_description',
    descriptionFallback: 'Tracks the full left upper limb.',
    coverageKey: 'body_left_arm_coverage',
    coverageFallback: 'Shoulder, arm, forearm, hand',
    focusKey: 'body_left_arm_focus',
    focusFallback: 'Grip and arm movement',
    hitbox: { x: 176, y: 98, width: 64, height: 226, radius: 40 },
  },
  RIGHT_LEG: {
    labelKey: 'body_right_leg_label',
    labelFallback: 'Right leg',
    subtitleKey: 'body_right_leg_subtitle',
    subtitleFallback: 'Hip to foot',
    descriptionKey: 'body_right_leg_description',
    descriptionFallback: 'Tracks the full right lower limb.',
    coverageKey: 'body_right_leg_coverage',
    coverageFallback: 'Hip, thigh, knee, shin, foot',
    focusKey: 'body_right_leg_focus',
    focusFallback: 'Walking and sprint control',
    hitbox: { x: 88, y: 258, width: 46, height: 248, radius: 26 },
  },
  LEFT_LEG: {
    labelKey: 'body_left_leg_label',
    labelFallback: 'Left leg',
    subtitleKey: 'body_left_leg_subtitle',
    subtitleFallback: 'Hip to foot',
    descriptionKey: 'body_left_leg_description',
    descriptionFallback: 'Tracks the full left lower limb.',
    coverageKey: 'body_left_leg_coverage',
    coverageFallback: 'Hip, thigh, knee, shin, foot',
    focusKey: 'body_left_leg_focus',
    focusFallback: 'Walking and sprint control',
    hitbox: { x: 136, y: 258, width: 46, height: 248, radius: 26 },
  },
};

export const getBodyRegionMeta = (region: BodyRegionKey): BodyRegionMeta => {
  const meta = BODY_REGION_META_DEFINITIONS[region];

  return {
    label: translate(meta.labelKey, meta.labelFallback),
    subtitle: translate(meta.subtitleKey, meta.subtitleFallback),
    description: translate(meta.descriptionKey, meta.descriptionFallback),
    coverage: translate(meta.coverageKey, meta.coverageFallback),
    focus: translate(meta.focusKey, meta.focusFallback),
    hitbox: meta.hitbox,
  };
};
