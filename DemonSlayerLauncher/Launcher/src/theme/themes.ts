import type { CSSProperties } from 'react';

/**
 * Système de thèmes « Respirations ».
 * Chaque thème définit une palette complète (accents, ciel, montagnes, brume,
 * particules). Les pages choisissent un thème ; le joueur peut en imposer un.
 */
export type ThemeId = 'water' | 'flame' | 'thunder' | 'mist' | 'wind' | 'moon' | 'sun' | 'demon';
export type ParticleKind = 'motes' | 'embers' | 'petals' | 'sparks' | 'leaves';

export interface Theme {
  id: ThemeId;
  name: string;
  breath: string;
  kanji: string;
  accent: string;
  accent2: string;
  /** Couleur claire pour textes accentués sur fond sombre */
  ink: string;
  sky: [string, string, string];
  mountains: [string, string, string];
  moon: string;
  mist: string;
  shade: string;
  lamp: string;
  particle: ParticleKind;
  particleColors: string[];
}

export const THEMES: Record<ThemeId, Theme> = {
  water: {
    id: 'water',
    name: 'Eau',
    breath: "Souffle de l'Eau",
    kanji: '水',
    accent: '#2f9bff',
    accent2: '#3ff0ff',
    ink: '#bfeeff',
    sky: ['#07112b', '#123a72', '#3a8fc4'],
    mountains: ['#1d4f86', '#123561', '#0a1d3c'],
    moon: '#e9f7ff',
    mist: 'rgba(160, 225, 255, 0.22)',
    shade: '#050c1f',
    lamp: '#ffd27a',
    particle: 'motes',
    particleColors: ['140,230,255', '90,180,255', '220,250,255'],
  },
  flame: {
    id: 'flame',
    name: 'Flamme',
    breath: 'Souffle de la Flamme',
    kanji: '炎',
    accent: '#ff4b2b',
    accent2: '#ffb33d',
    ink: '#ffd9b8',
    sky: ['#1a0610', '#5e1420', '#e0582c'],
    mountains: ['#7a2420', '#4a1218', '#22070d'],
    moon: '#ffdcae',
    mist: 'rgba(255, 150, 100, 0.2)',
    shade: '#14040a',
    lamp: '#ffcf6b',
    particle: 'embers',
    particleColors: ['255,120,60', '255,200,90', '255,70,50'],
  },
  thunder: {
    id: 'thunder',
    name: 'Tonnerre',
    breath: 'Souffle du Tonnerre',
    kanji: '雷',
    accent: '#ffcc1f',
    accent2: '#a46bff',
    ink: '#fff1b8',
    sky: ['#0f0a2a', '#33227a', '#8a62c9'],
    mountains: ['#4b3592', '#2c1f63', '#150f36'],
    moon: '#fff4c4',
    mist: 'rgba(200, 170, 255, 0.2)',
    shade: '#0a0720',
    lamp: '#ffe066',
    particle: 'sparks',
    particleColors: ['255,220,90', '200,160,255', '255,250,200'],
  },
  mist: {
    id: 'mist',
    name: 'Brume',
    breath: 'Souffle de la Brume',
    kanji: '霞',
    accent: '#8f7bff',
    accent2: '#7fd8ff',
    ink: '#e2dcff',
    sky: ['#0d0e2c', '#2f2f72', '#8a8fd6'],
    mountains: ['#4c4f9a', '#2f3170', '#17183d'],
    moon: '#f3f0ff',
    mist: 'rgba(210, 205, 255, 0.28)',
    shade: '#08091f',
    lamp: '#f6c8ff',
    particle: 'petals',
    particleColors: ['230,190,255', '255,200,235', '200,215,255'],
  },
  wind: {
    id: 'wind',
    name: 'Vent',
    breath: 'Souffle du Vent',
    kanji: '風',
    accent: '#19e3a6',
    accent2: '#38c8ff',
    ink: '#c8fff0',
    sky: ['#04161f', '#0c4352', '#2b9a9a'],
    mountains: ['#17606a', '#0d3d48', '#06202a'],
    moon: '#eafffa',
    mist: 'rgba(150, 255, 230, 0.18)',
    shade: '#03121a',
    lamp: '#ffd27a',
    particle: 'leaves',
    particleColors: ['120,240,190', '160,230,255', '220,255,200'],
  },
  moon: {
    id: 'moon',
    name: 'Lune',
    breath: 'Souffle de la Lune',
    kanji: '月',
    accent: '#7c8cff',
    accent2: '#e6c56b',
    ink: '#dfe3ff',
    sky: ['#070a1f', '#1b2457', '#4d5ca8'],
    mountains: ['#2f3a7c', '#1c2457', '#0c1130'],
    moon: '#fff8e1',
    mist: 'rgba(190, 200, 255, 0.2)',
    shade: '#060818',
    lamp: '#ffd98a',
    particle: 'motes',
    particleColors: ['220,225,255', '255,230,170', '170,180,255'],
  },
  sun: {
    id: 'sun',
    name: 'Soleil',
    breath: 'Danse du Dieu du Feu',
    kanji: '日',
    accent: '#f0b429',
    accent2: '#ff4f5e',
    ink: '#ffe7b0',
    sky: ['#1a0b12', '#6b2330', '#e8963c'],
    mountains: ['#8a3a2a', '#57201f', '#260c10'],
    moon: '#fff1c2',
    mist: 'rgba(255, 210, 140, 0.2)',
    shade: '#150709',
    lamp: '#ffe08a',
    particle: 'sparks',
    particleColors: ['255,210,110', '255,120,90', '255,240,190'],
  },
  demon: {
    id: 'demon',
    name: 'Démon',
    breath: 'Lune supérieure',
    kanji: '鬼',
    accent: '#e0264b',
    accent2: '#9b4dff',
    ink: '#ffc9d6',
    sky: ['#0b0612', '#2c0d2e', '#6e1a3f'],
    mountains: ['#4a1838', '#2b0d24', '#140611'],
    moon: '#ffd0d8',
    mist: 'rgba(220, 120, 200, 0.18)',
    shade: '#0a040c',
    lamp: '#ff7a8a',
    particle: 'petals',
    particleColors: ['255,90,130', '190,120,255', '255,180,200'],
  },
};

export const THEME_ORDER: ThemeId[] = ['water', 'flame', 'thunder', 'mist', 'wind', 'moon', 'sun', 'demon'];

/** Variables CSS d'un thème (appliquées sur un conteneur). */
export function themeVars(id: ThemeId): CSSProperties {
  const t = THEMES[id];
  return {
    '--accent': t.accent,
    '--accent-2': t.accent2,
    '--accent-ink': t.ink,
    '--sky-1': t.sky[0],
    '--sky-2': t.sky[1],
    '--sky-3': t.sky[2],
    '--mount-1': t.mountains[0],
    '--mount-2': t.mountains[1],
    '--mount-3': t.mountains[2],
    '--moon': t.moon,
    '--mist': t.mist,
    '--shade': t.shade,
    '--lamp': t.lamp,
  } as CSSProperties;
}
