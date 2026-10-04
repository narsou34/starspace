import type { IconName } from '../components/Icons';
import type { BackdropId, Focus } from '../scenery/Backdrop';
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
  /** Ambiance de la page : thème de couleurs + illustration de fond. */
  theme: ThemeId;
  art: BackdropId;
  focus: Focus;
}

export const VIEWS: Record<ViewId, ViewDef> = {
  home: { id: 'home', label: 'Accueil', kanji: '本部', icon: 'home', theme: 'water', art: 'akaza', focus: 'right' },
  server: { id: 'server', label: 'Serveur', kanji: '里', icon: 'server', theme: 'wind', art: 'akaza', focus: 'right' },
  character: { id: 'character', label: 'Personnage', kanji: '剣士', icon: 'characters', theme: 'mist', art: 'kokushibo', focus: 'left' },
  whitelist: { id: 'whitelist', label: 'Whitelist', kanji: '審査', icon: 'whitelist', theme: 'thunder', art: 'gyomei', focus: 'right' },
  tickets: { id: 'tickets', label: 'Tickets', kanji: '相談', icon: 'tickets', theme: 'moon', art: 'akaza', focus: 'right' },
  news: { id: 'news', label: 'Actualités', kanji: '瓦版', icon: 'news', theme: 'flame', art: 'gyomei', focus: 'right' },
  shop: { id: 'shop', label: 'Boutique', kanji: '商店', icon: 'shop', theme: 'sun', art: 'gyomei', focus: 'right' },
  settings: { id: 'settings', label: 'Paramètres', kanji: '設定', icon: 'settings', theme: 'demon', art: 'kokushibo', focus: 'right' },
  profile: { id: 'profile', label: 'Profil', kanji: '隊士', icon: 'account', theme: 'sun', art: 'gyomei', focus: 'right' },
};

export const NAV_ORDER: ViewId[] = ['home', 'server', 'character', 'whitelist', 'tickets', 'news', 'shop', 'settings'];
