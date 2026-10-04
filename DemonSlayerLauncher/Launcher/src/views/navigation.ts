import type { IconName } from '../components/Icons';
import type { SceneId } from '../scenery/Landscape';
import type { ThemeId } from '../theme/themes';

export type ViewId =
  | 'home'
  | 'server'
  | 'character'
  | 'whitelist'
  | 'tickets'
  | 'news'
  | 'shop'
  | 'settings'
  | 'profile';

export interface ViewDef {
  id: ViewId;
  label: string;
  kanji: string;
  icon: IconName;
  /** Ambiance de la page (thème + décor). */
  theme: ThemeId;
  scene: SceneId;
}

export const VIEWS: Record<ViewId, ViewDef> = {
  home: { id: 'home', label: 'Accueil', kanji: '本部', icon: 'home', theme: 'water', scene: 'mountains' },
  server: { id: 'server', label: 'Serveur', kanji: '里', icon: 'server', theme: 'wind', scene: 'village' },
  character: { id: 'character', label: 'Personnage', kanji: '剣士', icon: 'characters', theme: 'water', scene: 'forest' },
  whitelist: { id: 'whitelist', label: 'Whitelist', kanji: '審査', icon: 'whitelist', theme: 'thunder', scene: 'shrine' },
  tickets: { id: 'tickets', label: 'Tickets', kanji: '相談', icon: 'tickets', theme: 'moon', scene: 'lake' },
  news: { id: 'news', label: 'Actualités', kanji: '瓦版', icon: 'news', theme: 'flame', scene: 'shrine' },
  shop: { id: 'shop', label: 'Boutique', kanji: '商店', icon: 'shop', theme: 'sun', scene: 'village' },
  settings: { id: 'settings', label: 'Paramètres', kanji: '設定', icon: 'settings', theme: 'demon', scene: 'lake' },
  profile: { id: 'profile', label: 'Profil', kanji: '隊士', icon: 'account', theme: 'mist', scene: 'lake' },
};

export const NAV_ORDER: ViewId[] = ['home', 'server', 'character', 'whitelist', 'tickets', 'news', 'shop', 'settings'];
