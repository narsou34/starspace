import { useState } from 'react';
import { useAuth } from '../auth/AuthContext';
import { Avatar } from '../components/Avatar';
import { Emblem } from '../components/Emblem';
import { Icon } from '../components/Icons';
import { IconTile } from '../components/IconTile';
import { useToast } from '../components/Toasts';
import { ROLE_LABELS, errorMessage, type AppInfo, type PublicConfig } from '../models/types';
import { AccountView } from './AccountView';
import { ComingSoonView } from './ComingSoonView';
import { HomeView } from './HomeView';
import { NAV_GROUPS, SETTINGS_ITEM, accentStyle, findNav, type NavItem, type ViewId } from './navigation';

function NavButton({ item, active, onSelect }: { item: NavItem; active: boolean; onSelect: (id: ViewId) => void }) {
  return (
    <button
      type="button"
      className={`nav__item${active ? ' is-active' : ''}`}
      onClick={() => onSelect(item.id)}
      aria-current={active ? 'page' : undefined}
      style={accentStyle(item.breath)}
    >
      <IconTile name={item.icon} size="sm" />
      <span className="nav__label">{item.label}</span>
      {item.phase ? <span className="nav__soon">bientôt</span> : <span className="nav__kanji">{item.kanji}</span>}
    </button>
  );
}

export function Shell({ info, config }: { info: AppInfo | null; config: PublicConfig | null }) {
  const { user, logout } = useAuth();
  const toast = useToast();
  const [view, setView] = useState<ViewId>('home');
  const [leaving, setLeaving] = useState(false);
  if (!user) return null;

  const onLogout = async () => {
    setLeaving(true);
    try {
      await logout();
      toast.show('info', 'Déconnecté', 'À bientôt sur NDR | Demon Slayer.');
    } catch (err) {
      toast.show('error', 'Déconnexion', errorMessage(err));
      setLeaving(false);
    }
  };

  const current = findNav(view);

  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="sidebar__brand">
          <Emblem size={44} />
          <div>
            <strong>
              <em>NDR</em> | DEMON SLAYER
            </strong>
            <span>Roleplay · nanos</span>
          </div>
        </div>

        <nav className="nav">
          {NAV_GROUPS.map((group) => (
            <div key={group.title} className="nav__group">
              <p className="nav__title">{group.title}</p>
              {group.items.map((item) => (
                <NavButton key={item.id} item={item} active={view === item.id} onSelect={setView} />
              ))}
            </div>
          ))}
        </nav>

        <div className="sidebar__bottom">
          <NavButton item={SETTINGS_ITEM} active={view === 'settings'} onSelect={setView} />
          <div className="usercard">
            <button type="button" className="usercard__main" onClick={() => setView('account')}>
              <Avatar user={user} size={38} />
              <span>
                <strong>{user.username}</strong>
                <small>{ROLE_LABELS[user.role]}</small>
              </span>
            </button>
            <button
              type="button"
              className="usercard__logout"
              onClick={() => void onLogout()}
              disabled={leaving}
              aria-label="Se déconnecter"
              title="Se déconnecter"
            >
              <Icon name="logout" />
            </button>
          </div>
          <p className="sidebar__version">Launcher v{info?.version ?? '—'}</p>
        </div>
      </aside>

      <main className="content" key={view}>
        {view === 'home' && <HomeView onNavigate={setView} config={config} />}
        {view === 'account' && <AccountView />}
        {current?.phase && <ComingSoonView item={current} />}
      </main>
    </div>
  );
}
