import type { CSSProperties } from 'react';
import type { IconName } from '../components/Icons';

/** Couleurs inspirées des Respirations : chaque fonctionnalité a la sienne. */
export const BREATHS = {
  flamme: { name: 'Flamme', title: "Respiration de la Flamme", accent: '#ff5a2e', accent2: '#ffb648' },
  eau: { name: 'Eau', title: "Respiration de l'Eau", accent: '#2f8bff', accent2: '#5fe0ff' },
  tonnerre: { name: 'Tonnerre', title: "Respiration du Tonnerre", accent: '#ffc21a', accent2: '#fff07a' },
  insecte: { name: 'Insecte', title: "Respiration de l'Insecte", accent: '#a15cff', accent2: '#e49bff' },
  amour: { name: 'Amour', title: "Respiration de l'Amour", accent: '#ff3f8e', accent2: '#ffa0c8' },
  brume: { name: 'Brume', title: "Respiration de la Brume", accent: '#4fd8c9', accent2: '#c2f6ff' },
  vent: { name: 'Vent', title: "Respiration du Vent", accent: '#2fd879', accent2: '#b5f76b' },
  lune: { name: 'Lune', title: "Respiration de la Lune", accent: '#7b6dff', accent2: '#c9b8ff' },
} as const;

export type Breath = keyof typeof BREATHS;

/** Variables CSS --accent / --accent-2 pour un élément. */
export function accentStyle(breath: Breath): CSSProperties {
  const b = BREATHS[breath];
  return { '--accent': b.accent, '--accent-2': b.accent2 } as CSSProperties;
}

export type ViewId = 'home' | 'account' | 'characters' | 'whitelist' | 'news' | 'changelog' | 'tickets' | 'settings';

export interface NavItem {
  id: ViewId;
  label: string;
  kanji: string;
  icon: IconName;
  breath: Breath;
  /** Phase de développement où la section sera livrée (absente = disponible). */
  phase?: number;
  description?: string;
}

export const NAV_GROUPS: { title: string; items: NavItem[] }[] = [
  {
    title: 'Jeu',
    items: [{ id: 'home', label: 'Accueil', kanji: '本部', icon: 'home', breath: 'flamme' }],
  },
  {
    title: 'Pourfendeur',
    items: [
      { id: 'account', label: 'Mon compte', kanji: '隊士', icon: 'account', breath: 'eau' },
      {
        id: 'characters',
        label: 'Personnages',
        kanji: '剣士',
        icon: 'characters',
        breath: 'tonnerre',
        phase: 2,
        description: 'Vos personnages, leur faction, leur grade, leur respiration et leur progression.',
      },
      {
        id: 'whitelist',
        label: 'Whitelist',
        kanji: '審査',
        icon: 'whitelist',
        breath: 'insecte',
        phase: 2,
        description: 'Suivez votre candidature ou postulez à la whitelist directement depuis le launcher.',
      },
    ],
  },
  {
    title: 'Communauté',
    items: [
      {
        id: 'news',
        label: 'Actualités',
        kanji: '瓦版',
        icon: 'news',
        breath: 'amour',
        phase: 3,
        description: 'Annonces, événements, maintenances et nouveautés publiées par l’équipe.',
      },
      {
        id: 'changelog',
        label: 'Changelog',
        kanji: '記録',
        icon: 'changelog',
        breath: 'brume',
        phase: 3,
        description: 'Historique détaillé des versions du serveur : nouveautés, améliorations, corrections.',
      },
      {
        id: 'tickets',
        label: 'Support',
        kanji: '相談',
        icon: 'tickets',
        breath: 'vent',
        phase: 3,
        description: 'Ouvrez un ticket, joignez des captures et suivez les réponses du staff.',
      },
    ],
  },
];

export const SETTINGS_ITEM: NavItem = {
  id: 'settings',
  label: 'Paramètres',
  kanji: '設定',
  icon: 'settings',
  breath: 'lune',
  phase: 4,
  description: 'Chemin de nanos world, paramètres de lancement, animations, langue et notifications.',
};

export function findNav(id: ViewId): NavItem | undefined {
  return [...NAV_GROUPS.flatMap((g) => g.items), SETTINGS_ITEM].find((i) => i.id === id);
}
