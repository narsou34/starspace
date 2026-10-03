import type { IconName } from '../components/Icons';

export type ViewId = 'home' | 'account' | 'characters' | 'whitelist' | 'news' | 'changelog' | 'tickets' | 'settings';

export interface NavItem {
  id: ViewId;
  label: string;
  kanji: string;
  icon: IconName;
  /** Phase de développement où la section sera livrée (absente = disponible). */
  phase?: number;
  description?: string;
}

export const NAV_GROUPS: { title: string; items: NavItem[] }[] = [
  {
    title: 'Jeu',
    items: [{ id: 'home', label: 'Accueil', kanji: '本部', icon: 'home' }],
  },
  {
    title: 'Pourfendeur',
    items: [
      { id: 'account', label: 'Mon compte', kanji: '隊士', icon: 'account' },
      {
        id: 'characters',
        label: 'Personnages',
        kanji: '剣士',
        icon: 'characters',
        phase: 2,
        description: 'Vos personnages, leur faction, leur grade, leur respiration et leur progression.',
      },
      {
        id: 'whitelist',
        label: 'Whitelist',
        kanji: '審査',
        icon: 'whitelist',
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
        phase: 3,
        description: 'Annonces, événements, maintenances et nouveautés publiées par l’équipe.',
      },
      {
        id: 'changelog',
        label: 'Changelog',
        kanji: '記録',
        icon: 'changelog',
        phase: 3,
        description: 'Historique détaillé des versions du serveur : nouveautés, améliorations, corrections.',
      },
      {
        id: 'tickets',
        label: 'Support',
        kanji: '相談',
        icon: 'tickets',
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
  phase: 4,
  description: 'Chemin de nanos world, paramètres de lancement, animations, langue et notifications.',
};

export function findNav(id: ViewId): NavItem | undefined {
  return [...NAV_GROUPS.flatMap((g) => g.items), SETTINGS_ITEM].find((i) => i.id === id);
}
