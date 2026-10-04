import { useEffect, useMemo, useRef, useState, type CSSProperties, type ComponentType } from 'react';
import { bridge, isDemoMode } from '../api/bridge';
import { useAuth } from '../auth/AuthContext';
import { Avatar } from '../components/Avatar';
import { Emblem } from '../components/Emblem';
import { Icon } from '../components/Icons';
import { useApiPing } from '../components/ServerPing';
import { useToast } from '../components/Toasts';
import { PreviewTag } from '../components/ui';
import { PREVIEW_NOTIFICATIONS } from '../models/preview';
import { ROLE_LABELS, errorMessage, type AppInfo, type PublicConfig } from '../models/types';
import { THEMES, themeVars, type ThemeId } from '../theme/themes';
import { LauncherContext } from './LauncherContext';
import { NAV_ORDER, VIEWS, type ViewId } from './navigation';
import { CharacterView } from './pages/CharacterView';
import { HomeView } from './pages/HomeView';
import { NewsView } from './pages/NewsView';
import { ProfileView } from './pages/ProfileView';
import { ServerView } from './pages/ServerView';
import { SettingsView } from './pages/SettingsView';
import { ShopView } from './pages/ShopView';
import { TicketsView } from './pages/TicketsView';
import { WhitelistView } from './pages/WhitelistView';

const PAGES: Record<ViewId, ComponentType> = {
  home: HomeView,
  server: ServerView,
  character: CharacterView,
  whitelist: WhitelistView,
  tickets: TicketsView,
  news: NewsView,
  shop: ShopView,
  settings: SettingsView,
  profile: ProfileView,
};

export function Shell({
  info,
  config,
  theme,
  onViewChange,
}: {
  info: AppInfo | null;
  config: PublicConfig | null;
  theme: ThemeId;
  onViewChange: (view: ViewId) => void;
}) {
  const { user, logout } = useAuth();
  const toast = useToast();
  const ping = useApiPing(30_000);
  const [view, setView] = useState<ViewId>('home');
  const [bellOpen, setBellOpen] = useState(false);
  const bellRef = useRef<HTMLDivElement>(null);

  useEffect(() => onViewChange(view), [view, onViewChange]);

  useEffect(() => {
    if (!bellOpen) return;
    const close = (e: MouseEvent) => {
      if (!bellRef.current?.contains(e.target as Node)) setBellOpen(false);
    };
    window.addEventListener('mousedown', close);
    return () => window.removeEventListener('mousedown', close);
  }, [bellOpen]);

  const ctx = useMemo(() => ({ info, config, ping, navigate: setView }), [info, config, ping]);
  if (!user) return null;

  const onLogout = async () => {
    try {
      await logout();
      toast.show('info', 'Déconnecté', 'À bientôt sur NDR | Demon Slayer.');
    } catch (err) {
      toast.show('error', 'Déconnexion', errorMessage(err));
    }
  };

  const activeIndex = NAV_ORDER.indexOf(view);
  const Page = PAGES[view];
  const def = VIEWS[view];

  return (
    <LauncherContext.Provider value={ctx}>
      <div className="shell">
        <aside className="rail">
          <div className="rail__brand">
            <Emblem size={42} />
            <div>
              <strong>NDR</strong>
              <span>Demon Slayer</span>
            </div>
          </div>

          <nav className="rail__nav" style={{ '--active': Math.max(activeIndex, 0) } as CSSProperties}>
            <span className={`rail__indicator${activeIndex < 0 ? ' is-hidden' : ''}`} aria-hidden="true" />
            {NAV_ORDER.map((id) => {
              const v = VIEWS[id];
              return (
                <button
                  key={id}
                  type="button"
                  className={`rail__item${view === id ? ' is-active' : ''}`}
                  style={themeVars(v.theme)}
                  onClick={() => setView(id)}
                  aria-current={view === id ? 'page' : undefined}
                >
                  <span className="rail__icon">
                    <Icon name={v.icon} size={19} />
                  </span>
                  <span className="rail__label">{v.label}</span>
                  <span className="rail__kanji">{v.kanji}</span>
                </button>
              );
            })}
          </nav>

          <div className="rail__foot">
            {config?.links.discord && (
              <button type="button" className="rail__discord" onClick={() => void bridge.openExternal(config.links.discord!)}>
                <Icon name="discord" size={18} />
                <span>Discord</span>
              </button>
            )}
            <p className="rail__version">v{info?.version ?? '—'}</p>
          </div>
        </aside>

        <div className="stage">
          <header className="topbar">
            <div className="topbar__where">
              <span className="topbar__kanji">{def.kanji}</span>
              <div>
                <strong>{def.label}</strong>
                <small>{THEMES[theme].breath}</small>
              </div>
            </div>

            <div className="topbar__actions">
              {isDemoMode() && (
                <span className="demo-badge" title="Aucune connexion au serveur : données simulées">
                  <Icon name="eye" size={14} /> Mode aperçu
                </span>
              )}
              <div className="bell" ref={bellRef}>
                <button
                  type="button"
                  className="iconbtn"
                  aria-label="Notifications"
                  onClick={() => setBellOpen((o) => !o)}
                >
                  <Icon name="bell" />
                  <span className="iconbtn__dot" />
                </button>
                {bellOpen && (
                  <div className="bell__menu">
                    <header>
                      <strong>Notifications</strong>
                      <PreviewTag phase={3} />
                    </header>
                    {PREVIEW_NOTIFICATIONS.map((n, i) => (
                      <div key={i} className="bell__item" style={themeVars(n.theme)}>
                        <span className="bell__icon">
                          <Icon name={n.icon} size={16} />
                        </span>
                        <p>{n.text}</p>
                        <small>{n.time}</small>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              <button
                type="button"
                className={`profilechip${view === 'profile' ? ' is-active' : ''}`}
                onClick={() => setView('profile')}
              >
                <Avatar user={user} size={34} />
                <span>
                  <strong>{user.username}</strong>
                  <small>{ROLE_LABELS[user.role]}</small>
                </span>
              </button>
              <button type="button" className="iconbtn" aria-label="Se déconnecter" title="Se déconnecter" onClick={() => void onLogout()}>
                <Icon name="logout" />
              </button>
            </div>
          </header>

          <main className="page" key={view}>
            <Page />
          </main>
        </div>
      </div>
    </LauncherContext.Provider>
  );
}
